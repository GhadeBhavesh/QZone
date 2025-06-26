import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final TextEditingController _roomIdController = TextEditingController();
  String? _generatedRoomId;

  void _createRoom() {
    final roomId = const Uuid().v4().substring(0, 6).toUpperCase();
    setState(() {
      _generatedRoomId = roomId;
    });
  }

  void _joinRoom() {
    if (_roomIdController.text.isNotEmpty) {
      // TODO: Implement room joining logic
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Joining room...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                if (_generatedRoomId == null) ...[
                  _buildJoinRoomSection(),
                  const SizedBox(height: 40),
                  _buildCreateRoomButton(),
                ] else
                  _buildRoomCreatedSection(),
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

  Widget _buildRoomCreatedSection() {
    return Column(
      children: [
        const Text(
          'Room Created!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _generatedRoomId!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedRoomId!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room ID copied to clipboard'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _generatedRoomId = null;
            });
          },
          child: const Text('Create Another Room'),
        ),
      ],
    );
  }
}
