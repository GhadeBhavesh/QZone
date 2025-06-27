import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'services/socket_service.dart';
import 'pages/room_waiting_page.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final TextEditingController _roomIdController = TextEditingController();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.connect();
  }

  void _createRoom() {
    final roomId = const Uuid().v4().substring(0, 6).toUpperCase();

    // Navigate to waiting room as creator
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomWaitingPage(roomId: roomId, isCreator: true),
      ),
    );
  }

  void _joinRoom() {
    if (_roomIdController.text.isNotEmpty) {
      final roomId = _roomIdController.text.trim().toUpperCase();

      // Navigate to waiting room as participant
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => RoomWaitingPage(roomId: roomId, isCreator: false),
        ),
      ).then((_) {
        // Clear input when coming back
        _roomIdController.clear();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a room ID')));
    }
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Multiplayer Room',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Join or Create a Room',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildJoinRoomSection(),
                const SizedBox(height: 40),
                _buildCreateRoomButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinRoomSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _roomIdController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter Room ID',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _joinRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Join Room', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildCreateRoomButton() {
    return ElevatedButton(
      onPressed: _createRoom,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: const Text('Create Room', style: TextStyle(fontSize: 18)),
    );
  }
}
