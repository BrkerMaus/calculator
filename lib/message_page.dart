import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class MessagePage extends StatefulWidget {
  final String username;

  MessagePage({required this.username});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('messages');
  final TextEditingController _messageController = TextEditingController();
  List<Map<dynamic, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController(); // Scroll controller

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _checkAndDeleteOldImages(); // Check for old images on startup
  }

  Future<void> _fetchMessages() async {
    _messagesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<dynamic, dynamic>> messagesList = [];

        data.forEach((key, value) {
          messagesList.add(value);
        });

        setState(() {
          _messages = messagesList; // Update messages list
        });

        // Scroll to the bottom for the latest topic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messages.isNotEmpty) {
            _scrollToLatestTopic();
          }
        });
      }
    });
  }

  void _scrollToLatestTopic() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), // Duration for smooth scrolling
        curve: Curves.easeInOut, // Animation curve for smoothness
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Convert image to base64 string
      final bytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      // Save the base64 image to Firebase Realtime Database
      await _messagesRef.push().set({
        'username': widget.username,
        'image': base64Image, // Store as base64 string
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Scroll to the latest topic after an image is sent
      _scrollToLatestTopic();
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final messageData = {
        'username': widget.username,
        'message': _messageController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _messagesRef.push().set(messageData).then((_) {
        _messageController.clear(); // Clear the input after sending

        // Scroll to the latest topic when a new message is sent
        _scrollToLatestTopic();
      });
    }
  }

  void _checkAndDeleteOldImages() {
    _messagesRef.once().then((snapshot) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          final timestamp = value['timestamp'] as int;
          final DateTime messageDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final DateTime threeDaysAgo = DateTime.now().subtract(Duration(days: 3));

          if (messageDate.isBefore(threeDaysAgo)) {
            // If the message is older than 3 days, delete it
            _messagesRef.child(key).remove();
          }
        });
      }
    });
  }

  // Function to view the image in full screen
  void _viewImage(String base64Image) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Use MediaQuery to set maximum dimensions for the image
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
                      maxHeight: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
                    ),
                    child: Image.memory(
                      base64Decode(base64Image),
                      fit: BoxFit.contain, // Use contain to maintain aspect ratio
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User: ${widget.username}'),
        centerTitle: true,
        backgroundColor: Color(0xFFCC1E4A),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign the scroll controller
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(
                    message['username'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.containsKey('message')) Text(message['message']),
                      if (message.containsKey('image'))
                        GestureDetector(
                          onTap: () => _viewImage(message['image']),
                          child: Image.memory(
                            base64Decode(message['image']),
                            width: 300,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _sendMessage(); // Send the message when Enter is pressed
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Color(0xFFCC1E4A),
                ),
                IconButton(
                  icon: Icon(Icons.add_a_photo),
                  onPressed: _pickImage,
                  color: Color(0xFFCC1E4A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
