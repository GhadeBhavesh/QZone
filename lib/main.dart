import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'quiz_page.dart';
import 'room_page.dart';
import 'widgets/auth_wrapper.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/scores_page.dart';
import 'pages/leaderboard_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QZone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MyHomePage(title: 'Game'),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final _authService = AuthService();
  late AnimationController _titleAnimationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late List<Animation<double>> _buttonAnimations;
  late Animation<double> _backgroundRotation;

  @override
  void initState() {
    super.initState();

    // Title animation controller
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Button animation controller
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Title animations
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _titleScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.bounceOut),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Button animations
    _buttonAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _buttonAnimationController,
          curve: Interval(
            0.1 + (index * 0.15),
            0.4 + (index * 0.15),
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    // Background rotation
    _backgroundRotation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(_backgroundAnimationController);

    // Start animations
    _titleAnimationController.forward();
    _buttonAnimationController.forward();
    _backgroundAnimationController.repeat();
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _buttonAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.purple.shade900,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.blue,
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
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
                ...List.generate(15, (index) {
                  return Positioned(
                    left: (index * 30.0) % MediaQuery.of(context).size.width,
                    top: (index * 50.0) % MediaQuery.of(context).size.height,
                    child: Transform.rotate(
                      angle: _backgroundRotation.value + (index * 0.5),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
                // Main content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated title
                          SlideTransition(
                            position: _titleSlideAnimation,
                            child: ScaleTransition(
                              scale: _titleScaleAnimation,
                              child: FadeTransition(
                                opacity: _titleFadeAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'QZone',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 15.0,
                                          color: Colors.cyan,
                                          offset: Offset(2.0, 2.0),
                                        ),
                                        Shadow(
                                          blurRadius: 15.0,
                                          color: Colors.purple,
                                          offset: Offset(-2.0, -2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Animated buttons
                          ..._buildAnimatedButtons(),
                        ],
                      ),
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

  List<Widget> _buildAnimatedButtons() {
    final buttonData = [
      {
        'text': 'Start Game',
        'icon': Icons.play_arrow,
        'gradient': [Colors.green.shade400, Colors.teal.shade600],
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuizPage()),
          );
        },
      },
      {
        'text': 'Create Room',
        'icon': Icons.group_add,
        'gradient': [Colors.orange.shade400, Colors.deepOrange.shade600],
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoomPage()),
          );
        },
      },
      {
        'text': 'My Scores',
        'icon': Icons.score,
        'gradient': [Colors.blue.shade400, Colors.indigo.shade600],
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScoresPage()),
          );
        },
      },
      {
        'text': 'Leaderboard',
        'icon': Icons.leaderboard,
        'gradient': [Colors.purple.shade400, Colors.deepPurple.shade600],
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaderboardPage()),
          );
        },
      },
      {
        'text': 'Exit',
        'icon': Icons.exit_to_app,
        'gradient': [Colors.red.shade400, Colors.pink.shade600],
        'onPressed': () => Navigator.of(context).pop(),
      },
    ];

    return buttonData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: ScaleTransition(
          scale: _buttonAnimations[index],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(index.isEven ? -1.5 : 1.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _buttonAnimationController,
                curve: Interval(
                  0.1 + (index * 0.15),
                  0.4 + (index * 0.15),
                  curve: Curves.elasticOut,
                ),
              ),
            ),
            child: _buildAnimatedButton(
              data['text'] as String,
              data['onPressed'] as VoidCallback,
              data['icon'] as IconData,
              data['gradient'] as List<Color>,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAnimatedButton(
    String text,
    VoidCallback onPressed,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      width: 280,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.4),
            offset: const Offset(0, 8),
            blurRadius: 20.0,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
