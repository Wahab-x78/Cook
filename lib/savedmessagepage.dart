import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class SavedMessagesPage extends StatelessWidget {
  final List<ChatMessage> savedMessages;

  const SavedMessagesPage({super.key, required this.savedMessages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Messages'),
      ),
      body: ListView.builder(
        itemCount: savedMessages.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(savedMessages[index].text),
              subtitle: Text(savedMessages[index].createdAt.toString()),
            ),
          );
        },
      ),
    );
  }
}
