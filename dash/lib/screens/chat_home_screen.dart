import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'direct_chat_screen.dart';

class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),

      // ------------------ Active Chats List ------------------
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active chats yet. Tap + to start!"));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final List participants = chatData['participants'] ?? [];

              final otherUserId = participants.firstWhere(
                (id) => id != currentUser?.uid,
                orElse: () => '',
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();

                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final otherUserName = userData?['name'] ?? 'User';
                  final otherUserPhoto = userData?['photoUrl'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUserPhoto != null ? NetworkImage(otherUserPhoto) : null,
                      child: otherUserPhoto == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      chatData['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectChatScreen(
                            receiverId: otherUserId,
                            receiverName: otherUserName,
                            receiverPhotoUrl: otherUserPhoto,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),

      // ➕ මෙන්න මෙතැනට FLOATING ACTION BUTTON එක එකතු කරන්න:
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.message),
        onPressed: () {
          // Button එක එබුවාම Bottom Sheet එක open වෙනවා
          _showAllRegisteredUsers(context);
        },
      ),
    );
  }

  // ------------------ 2️⃣ FUNCTIONS (Class එක ඇතුළේ පහළින් දාන්න) ------------------

  // A. Registered ඉන්න ඔක්කොම Users ලාව List එකක පෙන්නන Function එක:
  void _showAllRegisteredUsers(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16151D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "New Chat",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blueAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddUserByEmailDialog(context); // Email search එකට යාම
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No registered users found.", style: TextStyle(color: Colors.white38)),
                      );
                    }

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != currentUser?.uid)
                        .toList();

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData = users[index].data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userData['photoUrl'] != null
                                ? NetworkImage(userData['photoUrl'])
                                : null,
                            child: userData['photoUrl'] == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            userData['name'] ?? 'User',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            userData['email'] ?? '',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DirectChatScreen(
                                  receiverId: userData['uid'],
                                  receiverName: userData['name'] ?? 'User',
                                  receiverPhotoUrl: userData['photoUrl'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // B. Email එකෙන් Search කරලා Chat පටන් ගන්න Dialog එක:
  void _showAddUserByEmailDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16151D),
          title: const Text("Search User by Email", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter user's registered email...",
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .get();

                if (query.docs.isNotEmpty) {
                  final userData = query.docs.first.data();

                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectChatScreen(
                          receiverId: userData['uid'],
                          receiverName: userData['name'] ?? 'User',
                          receiverPhotoUrl: userData['photoUrl'],
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No user registered with this email!")),
                    );
                  }
                }
              },
              child: const Text("Start Chat"),
            ),
          ],
        );
      },
    );
  }
}