import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Use your server URL
  static const String serverUrl = 'https://qzone.onrender.com';
  // For production: 'https://qzone.onrender.com'

  IO.Socket get socket {
    if (_socket == null) {
      connect();
    }
    return _socket!;
  }

  void connect() {
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to server');
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from server');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void createRoom(String roomId, String userName) {
    socket.emit('create-room', {'roomId': roomId, 'userName': userName});
  }

  void joinRoom(String roomId, String userName) {
    socket.emit('join-room', {'roomId': roomId, 'userName': userName});
  }

  void leaveRoom(String roomId) {
    socket.emit('leave-room', roomId);
  }

  void startGame(String roomId) {
    socket.emit('start-game', roomId);
  }

  // Event listeners
  void onRoomCreated(Function(dynamic) callback) {
    socket.on('room-created', callback);
  }

  void onRoomJoined(Function(dynamic) callback) {
    socket.on('room-joined', callback);
  }

  void onUserJoined(Function(dynamic) callback) {
    socket.on('user-joined', callback);
  }

  void onUserLeft(Function(dynamic) callback) {
    socket.on('user-left', callback);
  }

  void onRoomError(Function(dynamic) callback) {
    socket.on('room-error', callback);
  }

  void onGameStarted(Function(dynamic) callback) {
    socket.on('game-started', callback);
  }

  // Remove listeners
  void removeAllListeners() {
    socket.off('room-created');
    socket.off('room-joined');
    socket.off('user-joined');
    socket.off('user-left');
    socket.off('room-error');
    socket.off('game-started');
  }
}
