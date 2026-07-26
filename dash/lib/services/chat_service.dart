import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send Message
  Future<void> sendMessage(String currentUserId, String receiverId, String text) async {
    final message = MessageModel(
      senderId: currentUserId,
      receiverId: receiverId,
      text: text,
      timestamp: Timestamp.now(),
    );

    List<String> ids = [currentUserId, receiverId]..sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());
  }

  // Stream Messages Real-time
  Stream<QuerySnapshot> getMessages(String currentUserId, String receiverId) {
    List<String> ids = [currentUserId, receiverId]..sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}