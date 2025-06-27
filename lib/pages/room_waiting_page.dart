import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import 'multiplayer_quiz_page.dart';

class RoomWaitingPage extends StatefulWidget {
  final String roomId;
  final bool isCreator;

  const RoomWaitingPage({
    super.key,
    required this.roomId,
    required this.isCreator,
  });

  @override
  State<RoomWaitingPage> createState() => _RoomWaitingPageState();
}

class _RoomWaitingPageState extends State<RoomWaitingPage> {
  final SocketService _socketService = SocketService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _participants = [];
  String? _userName;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
    _setupSocketListeners();
  }

  Future<void> _initializeRoom() async {
    final email = await _authService.getUserEmail();
    setState(() {
      _userName = email?.split('@').first ?? 'Unknown';
    });

    if (widget.isCreator) {
      _socketService.createRoom(widget.roomId, _userName!);
    } else {
      _socketService.joinRoom(widget.roomId, _userName!);
    }
  }

  void _setupSocketListeners() {
    _socketService.onRoomCreated((data) {
      print('Room created: $data');
      _updateParticipants(data['room']['participants']);
    });

    _socketService.onRoomJoined((data) {
      print('Room joined: $data');
      _updateParticipants(data['room']['participants']);
    });

    _socketService.onUserJoined((data) {
      print('User joined: $data');
      _updateParticipants(data['room']['participants']);
      _showSnackBar('${data['userName']} joined the room');
    });

    _socketService.onUserLeft((data) {
      print('User left: $data');
      _updateParticipants(data['room']['participants']);
      _showSnackBar('A user left the room');
    });

    _socketService.onRoomError((data) {
      print('Room error: $data');
      _showSnackBar(data['message'], isError: true);
      if (data['message'] == 'Room not found') {
        Navigator.of(context).pop();
      }
    });

    _socketService.onGameStarted((data) {
      print('Game started: $data');
      setState(() {
        _gameStarted = true;
      });
      _showSnackBar('Game started!');

      // Navigate to multiplayer quiz page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerQuizPage(roomId: widget.roomId),
        ),
      );
    });
  }

  void _updateParticipants(List<dynamic> participants) {
    setState(() {
      _participants = participants.cast<Map<String, dynamic>>();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startGame() {
    if (_participants.length >= 2) {
      _socketService.startGame(widget.roomId);
    } else {
      _showSnackBar('Need at least 2 players to start', isError: true);
    }
  }

  void _leaveRoom() {
    _socketService.leaveRoom(widget.roomId);
    Navigator.of(context).pop();
  }

  void _copyRoomId() {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    _showSnackBar('Room ID copied to clipboard');
  }

  @override
  void dispose() {
    // Don't remove listeners when navigating to quiz page
    // _socketService.removeAllListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Room',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveRoom,
        ),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Room ID Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Room ID',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.roomId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _copyRoomId,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        _gameStarted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _gameStarted ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    _gameStarted
                        ? '🎮 Game Started!'
                        : '⏳ Waiting for players...',
                    style: TextStyle(
                      color: _gameStarted ? Colors.green : Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 30),

                // Participants List
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Players (${_participants.length}/2)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child:
                              _participants.isEmpty
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _participants.length,
                                    itemBuilder: (context, index) {
                                      final participant = _participants[index];
                                      final isCurrentUser =
                                          participant['name'] == _userName;
                                      final isCreator =
                                          participant['isCreator'] ?? false;

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              isCurrentUser
                                                  ? Colors.amber.withOpacity(
                                                    0.3,
                                                  )
                                                  : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border:
                                              isCurrentUser
                                                  ? Border.all(
                                                    color: Colors.amber,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  isCreator
                                                      ? Colors.purple.shade600
                                                      : Colors.blue.shade600,
                                              child: Text(
                                                participant['name'][0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    participant['name'],
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          isCurrentUser
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                  ),
                                                  Text(
                                                    isCreator
                                                        ? 'Room Creator'
                                                        : 'Player',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isCurrentUser)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'YOU',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                if (widget.isCreator && !_gameStarted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _participants.length >= 2 ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Start Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (!widget.isCreator)
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Waiting for the room creator to start the game...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
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
