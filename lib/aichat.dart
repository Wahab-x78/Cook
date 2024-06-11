import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'savedmessagepage.dart';
import 'package:image_picker/image_picker.dart';

class AIchat extends StatefulWidget {
  final List<ChatMessage> savedMessages;
  final Function(ChatMessage) onSaveMessage;

  const AIchat({super.key, required this.savedMessages, required this.onSaveMessage});

  @override
  State<AIchat> createState() => _MyAIchatState();
}

class _MyAIchatState extends State<AIchat> {
  Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: '0', firstName: 'User');
  ChatUser cheif = ChatUser(id: '1', firstName: 'Cheif', profileImage: 'assets/cook.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('What you want to cook?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedMessagesPage(savedMessages: widget.savedMessages)),
              );
            },
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: () {
            mediaMessage();
          },
          icon: const Icon(Icons.image),
        ),
      ]),
      messageOptions: MessageOptions(
        onLongPressMessage: (ChatMessage message) {
          if (message.user.id == cheif.id) {
            _showSaveMessageDialog(message);
          }
        },
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      gemini.streamGenerateContent(
        question,
        images: images,
      ).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == cheif) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
          ChatMessage message = ChatMessage(user: cheif, createdAt: DateTime.now(), text: response);
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void mediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: 'What is the recipe for this?',
        medias: [
          ChatMedia(
            url: file.path,
            fileName: '',
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
    }
  }

  void _showSaveMessageDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Save Message"),
          content: const Text("Do you want to save this message?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                widget.onSaveMessage(message);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
