import 'package:flutter/material.dart';
import 'dart:async';
import 'services/auth_service.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  int score = 0;
  int timeLeft = 30;
  int currentQuestionIndex = 0;
  int totalQuestionsAttempted = 0;
  late Timer timer;
  final _authService = AuthService();

  // Animation controllers
  late AnimationController _questionAnimationController;
  late AnimationController _optionAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;

  // Animations
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late List<Animation<double>> _optionAnimations;
  late Animation<double> _backgroundRotation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _timerColorAnimation;

  final List<QuizQuestion> questions = [
    QuizQuestion(
      question: "What is the capital of France?",
      options: ["London", "Berlin", "Paris", "Madrid"],
      correctAnswer: 2,
    ),
    QuizQuestion(
      question: "Which planet is known as the Red Planet?",
      options: ["Venus", "Mars", "Jupiter", "Saturn"],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: "What is 2 + 2 × 4?",
      options: ["16", "10", "8", "12"],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: "Who painted the Mona Lisa?",
      options: ["Van Gogh", "Da Vinci", "Picasso", "Michelangelo"],
      correctAnswer: 1,
    ),
    QuizQuestion(
      question: "What is the largest mammal?",
      options: ["African Elephant", "Blue Whale", "Giraffe", "Hippopotamus"],
      correctAnswer: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _optionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _questionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _questionAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _questionAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _optionAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _optionAnimationController,
          curve: Interval(
            index * 0.15,
            0.3 + (index * 0.15),
            curve: Curves.bounceOut,
          ),
        ),
      );
    });

    _backgroundRotation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(_backgroundAnimationController);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _timerColorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(_pulseAnimationController);

    // Start animations
    _animateQuestion();
    _backgroundAnimationController.repeat();
    _pulseAnimationController.repeat(reverse: true);

    startTimer();
  }

  void _animateQuestion() {
    _questionAnimationController.reset();
    _optionAnimationController.reset();
    _questionAnimationController.forward();
    _optionAnimationController.forward();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          showScore();
        }
      });
    });
  }

  void checkAnswer(int selectedAnswer) {
    setState(() {
      totalQuestionsAttempted++;
    });

    if (selectedAnswer == questions[currentQuestionIndex].correctAnswer) {
      setState(() {
        score += 10;
      });
    } else {
      setState(() {
        score -= 5;
      });
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      setState(() {
        currentQuestionIndex = 0; // Reset to first question
      });
    }

    // Animate to next question
    _animateQuestion();
  }

  void showScore() async {
    timer.cancel();

    // Save score to database
    try {
      final result = await _authService.saveScore(
        score,
        totalQuestionsAttempted,
      );
      if (!result['success']) {
        print('Failed to save score: ${result['error']}');
      }
    } catch (e) {
      print('Error saving score: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.indigo.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Time\'s Up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                  const SizedBox(height: 15),
                  Text(
                    'Final Score: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Questions Attempted: $totalQuestionsAttempted',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.pink.shade600],
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade600],
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      score = 0;
                      currentQuestionIndex = 0;
                      totalQuestionsAttempted = 0;
                      timeLeft = 30;
                      _animateQuestion();
                      startTimer();
                    });
                  },
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    _questionAnimationController.dispose();
    _optionAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
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
                  Colors.indigo.shade900,
                  Colors.purple.shade800,
                  Colors.blue.shade900,
                  Colors.teal.shade800,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(20, (index) {
                  return Positioned(
                    left: (index * 25.0) % MediaQuery.of(context).size.width,
                    top: (index * 40.0) % MediaQuery.of(context).size.height,
                    child: Transform.rotate(
                      angle: _backgroundRotation.value + (index * 0.3),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Score and Timer Header
                        _buildHeader(),
                        const SizedBox(height: 40),
                        // Question Section
                        Expanded(flex: 2, child: _buildQuestionSection()),
                        const SizedBox(height: 30),
                        // Options Section
                        Expanded(flex: 3, child: _buildOptionsSection()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score with animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade600],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Timer with color animation
          AnimatedBuilder(
            animation: _timerColorAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      timeLeft <= 10
                          ? _timerColorAnimation.value
                          : Colors.blue.shade600,
                ),
                child: Row(
                  children: [
                    Icon(
                      timeLeft <= 10 ? Icons.timer : Icons.access_time,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Time: $timeLeft',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    return SlideTransition(
      position: _questionSlideAnimation,
      child: FadeTransition(
        opacity: _questionFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.white.withOpacity(0.8),
                size: 40,
              ),
              const SizedBox(height: 20),
              Text(
                questions[currentQuestionIndex].question,
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    final colors = [
      [Colors.red.shade400, Colors.pink.shade600],
      [Colors.blue.shade400, Colors.indigo.shade600],
      [Colors.green.shade400, Colors.teal.shade600],
      [Colors.orange.shade400, Colors.deepOrange.shade600],
    ];

    return Column(
      children: List.generate(4, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ScaleTransition(
              scale: _optionAnimations[index],
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: colors[index],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[index][1].withOpacity(0.4),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => checkAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              questions[currentQuestionIndex].options[index],
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
