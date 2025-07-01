const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const { createServer } = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Store active rooms
const rooms = new Map();

// Quiz questions
const quizQuestions = [
  {
    question: "What is the capital of France?",
    options: ["London", "Berlin", "Paris", "Madrid"],
    correctAnswer: 2,
  },
  {
    question: "Which planet is known as the Red Planet?",
    options: ["Venus", "Mars", "Jupiter", "Saturn"],
    correctAnswer: 1,
  },
  {
    question: "What is 2 + 2 × 4?",
    options: ["16", "10", "8", "12"],
    correctAnswer: 1,
  },
  {
    question: "Who painted the Mona Lisa?",
    options: ["Van Gogh", "Da Vinci", "Picasso", "Michelangelo"],
    correctAnswer: 1,
  },
  {
    question: "What is the largest mammal?",
    options: ["African Elephant", "Blue Whale", "Giraffe", "Hippopotamus"],
    correctAnswer: 1,
  },
  {
    question: "What is the smallest country in the world?",
    options: ["Monaco", "Vatican City", "San Marino", "Liechtenstein"],
    correctAnswer: 1,
  },
  {
    question: "Which programming language is known for its use in web development?",
    options: ["Python", "JavaScript", "C++", "Assembly"],
    correctAnswer: 1,
  },
  {
    question: "What is the chemical symbol for gold?",
    options: ["Go", "Gd", "Au", "Ag"],
    correctAnswer: 2,
  },
  {
    question: "Which year did World War II end?",
    options: ["1944", "1945", "1946", "1947"],
    correctAnswer: 1,
  },
  {
    question: "What is the fastest land animal?",
    options: ["Lion", "Cheetah", "Gazelle", "Horse"],
    correctAnswer: 1,
  },
];

// Store active games
const activeGames = new Map();

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection using Supabase
// Using environment variable with fallback
const connectionString = process.env.DATABASE_URL || '';

const pool = new Pool({
  connectionString: connectionString,
  ssl: {
    rejectUnauthorized: false
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});


// Create users table if it doesn't exist
async function createUsersTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Users table created or already exists');
  } catch (error) {
    console.error('Error creating users table:', error);
  }
}

// Create scores table if it doesn't exist
async function createScoresTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS scores (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        score INTEGER NOT NULL,
        questions_attempted INTEGER NOT NULL,
        game_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Scores table created or already exists');
  } catch (error) {
    console.error('Error creating scores table:', error);
  }
}

const PORT = process.env.PORT || 3000;

// Test database connection and start server
async function startServer() {
  // Start server first
  const httpServer = server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });

  // Then try to connect to database
  setTimeout(async () => {
    try {
      console.log('Starting server...');
      console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'Set' : 'Not set');
      console.log('NODE_ENV:', process.env.NODE_ENV);
      
      // Test database connection and initialize tables
      console.log('Testing database connection...');
      const client = await pool.connect();
      console.log('Connected to Supabase database successfully');
      client.release();
      
      // Initialize database tables
      await createUsersTable();
      await createScoresTable();
      console.log('Database initialization complete');
      
    } catch (error) {
      console.error('Database connection failed:', error);
      console.error('Error details:', {
        message: error.message,
        code: error.code,
        errno: error.errno,
        syscall: error.syscall,
        address: error.address,
        port: error.port
      });
      
      console.log('Server will continue running without database connection');
      console.log('Database operations will fail until connection is restored');
    }
  }, 2000); // Wait 2 seconds before trying database connection
}

// Initialize database
startServer();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'Server is running', timestamp: new Date().toISOString() });
});

// Test database connection endpoint
app.get('/api/test-db', async (req, res) => {
  try {
    console.log('Testing database connection with individual parameters...');
    console.log('Host: db.wiblsiguzfdbayuydudr.supabase.co');
    console.log('Port: 5432');
    console.log('Database: postgres');
    console.log('User: postgres');
    
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    res.json({ 
      status: 'Database connected', 
      timestamp: result.rows[0].now 
    });
  } catch (error) {
    console.error('Database test error:', error);
    res.status(500).json({ 
      status: 'Database connection failed', 
      error: error.message,
      code: error.code,
      address: error.address
    });
  }
});

// Database connection helper with retry logic
async function getDbConnection() {
  try {
    const client = await pool.connect();
    return client;
  } catch (error) {
    console.error('Database connection failed:', error.message);
    throw new Error('Database temporarily unavailable');
  }
}

// Routes
app.post('/api/signup', async (req, res) => {
  let client;
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Get database connection
    client = await getDbConnection();

    // Check if user already exists
    const existingUser = await client.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Insert new user
    const result = await client.query(
      'INSERT INTO users (email, password) VALUES ($1, $2) RETURNING id, email, created_at',
      [email, hashedPassword]
    );

    const user = result.rows[0];
    
    // Generate JWT token
    const token = jwt.sign({ userId: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: '24h',
    });

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user.id,
        email: user.email,
        createdAt: user.created_at,
      },
      token,
    });
  } catch (error) {
    console.error('Signup error:', error);
    if (error.message === 'Database temporarily unavailable') {
      res.status(503).json({ error: 'Service temporarily unavailable. Please try again later.' });
    } else {
      res.status(500).json({ error: 'Internal server error' });
    }
  } finally {
    if (client) client.release();
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign({ userId: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: '24h',
    });

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        createdAt: user.created_at,
      },
      token,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(400).json({ error: 'Invalid token' });
  }
};

// Protected route example
app.get('/api/profile', verifyToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT id, email, created_at FROM users WHERE id = $1', [req.user.userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Save quiz score
app.post('/api/save-score', verifyToken, async (req, res) => {
  try {
    const { score, questionsAttempted } = req.body;

    // Validate input
    if (score === undefined || questionsAttempted === undefined) {
      return res.status(400).json({ error: 'Score and questions attempted are required' });
    }

    // Save score to database
    const result = await pool.query(
      'INSERT INTO scores (user_id, score, questions_attempted) VALUES ($1, $2, $3) RETURNING *',
      [req.user.userId, score, questionsAttempted]
    );

    res.status(201).json({
      message: 'Score saved successfully',
      score: result.rows[0]
    });
  } catch (error) {
    console.error('Save score error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get user's scores
app.get('/api/scores', verifyToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM scores WHERE user_id = $1 ORDER BY game_date DESC',
      [req.user.userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get scores error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get user's best score
app.get('/api/best-score', verifyToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT MAX(score) as best_score FROM scores WHERE user_id = $1',
      [req.user.userId]
    );

    res.json({ bestScore: result.rows[0].best_score || 0 });
  } catch (error) {
    console.error('Get best score error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get leaderboard - top scores from all users
app.get('/api/leaderboard', verifyToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        u.email,
        MAX(s.score) as best_score,
        MAX(s.game_date) as last_played
      FROM users u
      JOIN scores s ON u.id = s.user_id
      GROUP BY u.id, u.email
      ORDER BY best_score DESC
      LIMIT 10
    `);

    res.json(result.rows);
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Create room
  socket.on('create-room', (data) => {
    const { roomId, userName } = data;
    
    // Create room if it doesn't exist
    if (!rooms.has(roomId)) {
      rooms.set(roomId, {
        id: roomId,
        creator: userName,
        participants: [],
        createdAt: Date.now()
      });
    }

    // Join the socket room
    socket.join(roomId);
    
    // Add user to room participants
    const room = rooms.get(roomId);
    room.participants.push({
      id: socket.id,
      name: userName,
      isCreator: true
    });

    socket.emit('room-created', {
      roomId,
      room: room
    });

    console.log(`Room ${roomId} created by ${userName}`);
  });

  // Join room
  socket.on('join-room', (data) => {
    const { roomId, userName } = data;
    
    if (!rooms.has(roomId)) {
      socket.emit('room-error', { message: 'Room not found' });
      return;
    }

    const room = rooms.get(roomId);
    
    // Check if room is full (limit to 10 players)
    if (room.participants.length >= 10) {
      socket.emit('room-error', { message: 'Room is full' });
      return;
    }

    // Join the socket room
    socket.join(roomId);
    
    // Add user to room participants
    room.participants.push({
      id: socket.id,
      name: userName,
      isCreator: false
    });

    // Notify all users in the room
    io.to(roomId).emit('user-joined', {
      userName,
      room: room
    });

    socket.emit('room-joined', {
      roomId,
      room: room
    });

    console.log(`${userName} joined room ${roomId}`);
  });

  // Leave room
  socket.on('leave-room', (roomId) => {
    if (rooms.has(roomId)) {
      const room = rooms.get(roomId);
      room.participants = room.participants.filter(p => p.id !== socket.id);
      
      socket.leave(roomId);
      
      // Notify other users
      socket.to(roomId).emit('user-left', {
        socketId: socket.id,
        room: room
      });

      // Delete room if empty
      if (room.participants.length === 0) {
        rooms.delete(roomId);
        console.log(`Room ${roomId} deleted (empty)`);
      }
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    
    // Remove user from all rooms
    rooms.forEach((room, roomId) => {
      const participantIndex = room.participants.findIndex(p => p.id === socket.id);
      if (participantIndex !== -1) {
        room.participants.splice(participantIndex, 1);
        
        // Notify other users
        socket.to(roomId).emit('user-left', {
          socketId: socket.id,
          room: room
        });

        // Delete room if empty
        if (room.participants.length === 0) {
          rooms.delete(roomId);
          console.log(`Room ${roomId} deleted (empty)`);
        }
      }
    });
  });

  // Start game in room
  socket.on('start-game', (roomId) => {
    if (rooms.has(roomId)) {
      const room = rooms.get(roomId);
      if (room.participants.length >= 2 && room.participants.length <= 10) {
        // Initialize game state
        const gameState = {
          roomId: roomId,
          currentQuestionIndex: 0,
          totalQuestions: quizQuestions.length,
          players: room.participants.map(p => ({
            id: p.id,
            name: p.name,
            score: 0,
            hasAnswered: false,
            answer: null,
            answerTime: null
          })),
          questionStartTime: null,
          timer: null,
          isGameActive: true
        };
        
        activeGames.set(roomId, gameState);
        
        io.to(roomId).emit('game-started', { 
          roomId,
          totalQuestions: gameState.totalQuestions 
        });
        
        console.log(`Game started in room ${roomId}`);
        
        // Start first question after a short delay
        setTimeout(() => {
          startNextQuestion(roomId);
        }, 3000);
      } else {
        socket.emit('room-error', { message: 'Need at least 2 players and maximum 10 players to start' });
      }
    }
  });

  // Handle quiz answer
  socket.on('submit-answer', (data) => {
    const { roomId, answer } = data;
    const game = activeGames.get(roomId);
    
    if (!game || !game.isGameActive) return;
    
    const player = game.players.find(p => p.id === socket.id);
    if (!player || player.hasAnswered) return;
    
    // Record answer and time
    player.hasAnswered = true;
    player.answer = answer;
    player.answerTime = Date.now();
    
    console.log(`Player ${player.name} answered ${answer} in room ${roomId}`);
    
    // Check if all players have answered
    const allAnswered = game.players.every(p => p.hasAnswered);
    if (allAnswered) {
      clearTimeout(game.timer);
      processQuestionResults(roomId);
    }
  });

  // Function to start next question
  function startNextQuestion(roomId) {
    const game = activeGames.get(roomId);
    if (!game || !game.isGameActive) return;
    
    if (game.currentQuestionIndex >= game.totalQuestions) {
      endGame(roomId);
      return;
    }
    
    const question = quizQuestions[game.currentQuestionIndex];
    
    // Reset player states for new question
    game.players.forEach(p => {
      p.hasAnswered = false;
      p.answer = null;
      p.answerTime = null;
    });
    
    game.questionStartTime = Date.now();
    
    // Send question to all players
    io.to(roomId).emit('new-question', {
      questionIndex: game.currentQuestionIndex,
      question: question.question,
      options: question.options,
      timeLimit: 10000 // 10 seconds
    });
    
    console.log(`Question ${game.currentQuestionIndex + 1} started in room ${roomId}`);
    
    // Set timer for question timeout
    game.timer = setTimeout(() => {
      processQuestionResults(roomId);
    }, 10000);
  }
  
  // Function to process question results
  function processQuestionResults(roomId) {
    const game = activeGames.get(roomId);
    if (!game) return;
    
    const question = quizQuestions[game.currentQuestionIndex];
    const correctAnswer = question.correctAnswer;
    
    // Sort players by answer time (faster first)
    const answeredPlayers = game.players
      .filter(p => p.hasAnswered && p.answer !== null)
      .sort((a, b) => a.answerTime - b.answerTime);
    
    // Calculate scores
    const results = game.players.map(player => {
      let pointsEarned = 0;
      let status = 'no-answer';
      
      if (player.hasAnswered && player.answer === correctAnswer) {
        // Correct answer
        const answerIndex = answeredPlayers.findIndex(p => p.id === player.id);
        if (answerIndex === 0) {
          pointsEarned = 10; // First correct answer
          status = 'first-correct';
        } else {
          pointsEarned = 5; // Subsequent correct answers
          status = 'correct';
        }
      } else if (player.hasAnswered) {
        pointsEarned = -5; // Wrong answer
        status = 'wrong';
      } else {
        pointsEarned = 0; // No answer
        status = 'no-answer';
      }
      
      player.score += pointsEarned;
      
      return {
        playerId: player.id,
        playerName: player.name,
        answer: player.answer,
        pointsEarned,
        totalScore: player.score,
        status
      };
    });
    
    // Send results to all players
    io.to(roomId).emit('question-results', {
      questionIndex: game.currentQuestionIndex,
      correctAnswer,
      results,
      leaderboard: game.players
        .map(p => ({ name: p.name, score: p.score }))
        .sort((a, b) => b.score - a.score)
    });
    
    console.log(`Question ${game.currentQuestionIndex + 1} results processed in room ${roomId}`);
    
    game.currentQuestionIndex++;
    
    // Start next question after showing results
    setTimeout(() => {
      startNextQuestion(roomId);
    }, 5000);
  }
  
  // Function to end game
  function endGame(roomId) {
    const game = activeGames.get(roomId);
    if (!game) return;
    
    game.isGameActive = false;
    
    const finalResults = game.players
      .map(p => ({ name: p.name, score: p.score }))
      .sort((a, b) => b.score - a.score);
    
    io.to(roomId).emit('game-ended', {
      finalResults,
      winner: finalResults[0]
    });
    
    console.log(`Game ended in room ${roomId}`);
    
    // Clean up
    activeGames.delete(roomId);
  }
});
