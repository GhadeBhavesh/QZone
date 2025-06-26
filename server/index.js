const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection using Supabase
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
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
  try {
    console.log('Starting server...');
    console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'Set' : 'Not set');
    console.log('NODE_ENV:', process.env.NODE_ENV);
    
    // Start server first
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });

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
    
    // Still start the server even if DB fails initially
    if (!app.listening) {
      app.listen(PORT, () => {
        console.log(`Server running on port ${PORT} (without database)`);
      });
    }
  }
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
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    res.json({ 
      status: 'Database connected', 
      timestamp: result.rows[0].now 
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'Database connection failed', 
      error: error.message 
    });
  }
});

// Routes
app.post('/api/signup', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Check if user already exists
    const existingUser = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Insert new user
    const result = await pool.query(
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
    res.status(500).json({ error: 'Internal server error' });
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
