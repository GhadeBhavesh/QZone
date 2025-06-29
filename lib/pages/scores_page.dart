import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';

class ScoresPage extends StatefulWidget {
  const ScoresPage({super.key});

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> with TickerProviderStateMixin {
  final _authService = AuthService();
  List<dynamic> _scores = [];
  int _bestScore = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _bestScoreAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _backgroundAnimationController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _bestScoreScaleAnimation;
  late Animation<double> _bestScorePulseAnimation;
  late List<Animation<double>> _listItemAnimations;
  late Animation<double> _backgroundRotation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bestScoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Initialize animations
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.bounceOut,
      ),
    );

    _bestScoreScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bestScoreAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _bestScorePulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _bestScoreAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _backgroundRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundAnimationController);

    // Start animations
    _headerAnimationController.forward();
    _backgroundAnimationController.repeat();

    _loadScores();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _bestScoreAnimationController.dispose();
    _listAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    print('Loading scores...');
    try {
      // Load user scores
      final scoresResult = await _authService.getUserScores();
      print('Scores result: $scoresResult');
      if (scoresResult['success']) {
        setState(() {
          _scores = scoresResult['scores'];
          _errorMessage = null;
        });
        print('Loaded ${_scores.length} scores');

        // Initialize list item animations
        _listItemAnimations = List.generate(_scores.length, (index) {
          return Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _listAnimationController,
              curve: Interval(
                index * 0.1,
                (index * 0.1) + 0.5,
                curve: Curves.elasticOut,
              ),
            ),
          );
        });

        _listAnimationController.forward();
      } else {
        print('Failed to load scores: ${scoresResult['error']}');
        setState(() {
          _errorMessage = 'Failed to load scores: ${scoresResult['error']}';
        });
      }

      // Load best score
      final bestScoreResult = await _authService.getBestScore();
      print('Best score result: $bestScoreResult');
      if (bestScoreResult['success']) {
        setState(() {
          _bestScore = bestScoreResult['bestScore'];
        });
        print('Best score: $_bestScore');
        _bestScoreAnimationController.forward();
        _bestScoreAnimationController.repeat(reverse: true);
      } else {
        print('Failed to load best score: ${bestScoreResult['error']}');
        if (_errorMessage == null) {
          setState(() {
            _errorMessage =
                'Failed to load best score: ${bestScoreResult['error']}';
          });
        }
      }
    } catch (e) {
      print('Error loading scores: $e');
      setState(() {
        _errorMessage = 'Error loading scores: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadScores();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, color: Colors.white70, size: 64),
            SizedBox(height: 16),
            Text(
              'No games played yet!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a quiz to see your scores here.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scores.length,
      itemBuilder: (context, index) {
        final score = _scores[index];
        return ScaleTransition(
          scale: _listItemAnimations[index],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(index.isEven ? -1 : 1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _listAnimationController,
                curve: Interval(
                  index * 0.1,
                  (index * 0.1) + 0.5,
                  curve: Curves.elasticOut,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Animated Score Circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors:
                              score['score'] >= 50
                                  ? [
                                    Colors.green.shade400,
                                    Colors.teal.shade600,
                                  ]
                                  : score['score'] >= 0
                                  ? [
                                    Colors.orange.shade400,
                                    Colors.deepOrange.shade600,
                                  ]
                                  : [Colors.red.shade400, Colors.pink.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (score['score'] >= 50
                                    ? Colors.green
                                    : score['score'] >= 0
                                    ? Colors.orange
                                    : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${score['score']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'pts',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.quiz,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Questions: ${score['questions_attempted']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.white.withOpacity(0.6),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(score['game_date']),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Performance indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (score['score'] >= 50
                                ? Colors.green
                                : score['score'] >= 0
                                ? Colors.orange
                                : Colors.red)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        score['score'] >= 50
                            ? 'Great!'
                            : score['score'] >= 0
                            ? 'Good'
                            : 'Try Again',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              score['score'] >= 50
                                  ? Colors.green.shade300
                                  : score['score'] >= 0
                                  ? Colors.orange.shade300
                                  : Colors.red.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.indigo.shade800,
                  Colors.blue.shade900,
                  Colors.cyan.shade800,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(12, (index) {
                  return Positioned(
                    left: (index * 40.0) % MediaQuery.of(context).size.width,
                    top: (index * 60.0) % MediaQuery.of(context).size.height,
                    child: Transform.rotate(
                      angle: _backgroundRotation.value + (index * 0.8),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Animated Header
                      SlideTransition(
                        position: _headerSlideAnimation,
                        child: FadeTransition(
                          opacity: _headerFadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Text(
                                      '📊 My Scores',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Colors.cyan,
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Animated Best Score Card
                      ScaleTransition(
                        scale: _bestScoreScaleAnimation,
                        child: AnimatedBuilder(
                          animation: _bestScorePulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _bestScorePulseAnimation.value,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade400,
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 8),
                                      blurRadius: 15,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Best Score',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$_bestScore',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Colors.orange,
                                            offset: Offset(2.0, 2.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Scores List
                      Expanded(
                        child:
                            _isLoading
                                ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Loading your scores...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : _errorMessage != null
                                ? _buildErrorWidget()
                                : _scores.isEmpty
                                ? _buildEmptyWidget()
                                : _buildScoresList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
