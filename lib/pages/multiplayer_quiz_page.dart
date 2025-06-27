import 'package:flutter/material.dart';
import 'dart:async';
import '../services/socket_service.dart';
import '../services/auth_service.dart';

class MultiplayerQuizPage extends StatefulWidget {
  final String roomId;

  const MultiplayerQuizPage({super.key, required this.roomId});

  @override
  State<MultiplayerQuizPage> createState() => _MultiplayerQuizPageState();
}

class _MultiplayerQuizPageState extends State<MultiplayerQuizPage> {
  final SocketService _socketService = SocketService();
  final AuthService _authService = AuthService();

  // Game state
  String? _currentQuestion;
  List<String> _options = [];
  int _questionIndex = 0;
  int _totalQuestions = 10;
  int _timeLeft = 10;
  Timer? _timer;
  bool _hasAnswered = false;
  int? _selectedAnswer;
  bool _showingResults = false;

  // Player scores
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _questionResults = [];

  // Game status
  bool _gameEnded = false;
  String? _winner;
  String? _userName;

  @override
  void initState() {
    super.initState();
    print('MultiplayerQuizPage initState called');
    _initializeUser();
    _setupSocketListeners();
  }

  Future<void> _initializeUser() async {
    final email = await _authService.getUserEmail();
    setState(() {
      _userName = email?.split('@').first ?? 'Unknown';
    });
  }

  void _setupSocketListeners() {
    print('Setting up socket listeners in MultiplayerQuizPage');
    _socketService.onNewQuestion((data) {
      print('New question received: $data');
      _handleNewQuestion(data);
    });

    _socketService.onQuestionResults((data) {
      print('Question results: $data');
      _handleQuestionResults(data);
    });

    _socketService.onGameEnded((data) {
      print('Game ended: $data');
      _handleGameEnded(data);
    });
  }

  void _handleNewQuestion(Map<String, dynamic> data) {
    print('Handling new question: $data');
    setState(() {
      _currentQuestion = data['question'];
      _options = List<String>.from(data['options']);
      _questionIndex = data['questionIndex'];
      _timeLeft = 10;
      _hasAnswered = false;
      _selectedAnswer = null;
      _showingResults = false;
    });
    print('Question set: $_currentQuestion');
    print('Options set: $_options');

    _startTimer();
  }

  void _handleQuestionResults(Map<String, dynamic> data) {
    setState(() {
      _showingResults = true;
      _questionResults = List<Map<String, dynamic>>.from(data['results']);
      _leaderboard = List<Map<String, dynamic>>.from(data['leaderboard']);
    });

    _timer?.cancel();
  }

  void _handleGameEnded(Map<String, dynamic> data) {
    setState(() {
      _gameEnded = true;
      _leaderboard = List<Map<String, dynamic>>.from(data['finalResults']);
      _winner = data['winner']['name'];
    });

    _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          if (!_hasAnswered) {
            _submitAnswer(null); // No answer submitted
          }
        }
      });
    });
  }

  void _submitAnswer(int? answer) {
    if (_hasAnswered) return;

    setState(() {
      _hasAnswered = true;
      _selectedAnswer = answer;
    });

    if (answer != null) {
      _socketService.submitAnswer(widget.roomId, answer);
    }

    _timer?.cancel();
  }

  Color _getOptionColor(int index) {
    if (!_hasAnswered && !_showingResults) {
      return Colors.white.withOpacity(0.2);
    }

    if (_showingResults) {
      // Show correct answer in green
      final correctAnswer =
          _questionResults.isNotEmpty
              ? _questionResults.first['correctAnswer'] ?? -1
              : -1;

      if (index == correctAnswer) {
        return Colors.green.withOpacity(0.7);
      }

      // Show user's wrong answer in red
      if (index == _selectedAnswer && index != correctAnswer) {
        return Colors.red.withOpacity(0.7);
      }
    }

    if (_selectedAnswer == index) {
      return Colors.blue.withOpacity(0.7);
    }

    return Colors.white.withOpacity(0.2);
  }

  Widget _buildGameContent() {
    if (_gameEnded) {
      return _buildGameEndedScreen();
    }

    if (_showingResults) {
      return _buildResultsScreen();
    }

    if (_currentQuestion == null) {
      return _buildWaitingScreen();
    }

    return _buildQuestionScreen();
  }

  Widget _buildWaitingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Starting game...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen() {
    return Column(
      children: [
        // Timer and progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_questionIndex + 1}/$_totalQuestions',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _timeLeft <= 3 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Time: $_timeLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Progress bar
        LinearProgressIndicator(
          value: (_questionIndex + 1) / _totalQuestions,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),

        const SizedBox(height: 40),

        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            _currentQuestion!,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 30),

        // Options
        Expanded(
          child: ListView.builder(
            itemCount: _options.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: _getOptionColor(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _hasAnswered ? null : () => _submitAnswer(index),
                  child: Text(
                    _options[index],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_hasAnswered && !_showingResults)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Waiting for other players...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    return Column(
      children: [
        const Text(
          'Question Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        // Player results
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: _questionResults.length,
            itemBuilder: (context, index) {
              final result = _questionResults[index];
              final isCurrentUser = result['playerName'] == _userName;

              Color statusColor;
              String statusText;
              switch (result['status']) {
                case 'first-correct':
                  statusColor = Colors.amber;
                  statusText = 'First Correct! (+${result['pointsEarned']})';
                  break;
                case 'correct':
                  statusColor = Colors.green;
                  statusText = 'Correct! (+${result['pointsEarned']})';
                  break;
                case 'wrong':
                  statusColor = Colors.red;
                  statusText = 'Wrong (${result['pointsEarned']})';
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = 'No Answer (${result['pointsEarned']})';
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isCurrentUser
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      isCurrentUser
                          ? Border.all(color: Colors.amber, width: 2)
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result['playerName'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Total: ${result['totalScore']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Current leaderboard
        const Text(
          'Current Standings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final player = _leaderboard[index];
              final isCurrentUser = player['name'] == _userName;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      index == 0
                          ? Colors.amber
                          : index == 1
                          ? Colors.grey[400]
                          : Colors.orange[700],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  player['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  '${player['score']} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tileColor: isCurrentUser ? Colors.amber.withOpacity(0.3) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameEndedScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, size: 80, color: Colors.amber),

        const SizedBox(height: 20),

        const Text(
          'Game Finished!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Winner: $_winner',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          'Final Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final player = _leaderboard[index];
              final isCurrentUser = player['name'] == _userName;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isCurrentUser
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      isCurrentUser
                          ? Border.all(color: Colors.amber, width: 2)
                          : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          index == 0
                              ? Colors.amber
                              : index == 1
                              ? Colors.grey[400]
                              : Colors.orange[700],
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        player['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),

                    Text(
                      '${player['score']} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: const Text(
            'Back to Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketService.removeAllListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _gameEnded
              ? null
              : AppBar(
                title: const Text(
                  'Multiplayer Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.purple.shade900,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                automaticallyImplyLeading: false,
              ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade900, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildGameContent(),
          ),
        ),
      ),
    );
  }
}
