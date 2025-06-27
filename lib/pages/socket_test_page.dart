import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class SocketTestPage extends StatefulWidget {
  const SocketTestPage({super.key});

  @override
  State<SocketTestPage> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage> {
  final SocketService _socketService = SocketService();
  final List<String> _logs = [];
  final String _testRoomId = 'test123';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _socketService.onRoomCreated((data) {
      _addLog('Room created: $data');
    });

    _socketService.onGameStarted((data) {
      _addLog('Game started: $data');
    });

    _socketService.onNewQuestion((data) {
      _addLog('New question: $data');
    });

    _socketService.onQuestionResults((data) {
      _addLog('Question results: $data');
    });

    _socketService.onGameEnded((data) {
      _addLog('Game ended: $data');
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal()}: $message');
    });
    print(message);
  }

  void _createRoom() {
    _addLog('Creating room: $_testRoomId');
    _socketService.createRoom(_testRoomId, 'TestUser1');
  }

  void _startGame() {
    _addLog('Starting game in room: $_testRoomId');
    _socketService.startGame(_testRoomId);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createRoom,
                    child: const Text('Create Room'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start Game'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearLogs,
                    child: const Text('Clear Logs'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
