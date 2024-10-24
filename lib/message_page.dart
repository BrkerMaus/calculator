import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessagePage extends StatefulWidget {
  final String username;
  final String groupId;
  String groupName;
  String groupImage;


  MessagePage({super.key,
    required this.username,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
  });

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<dynamic, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late final DatabaseReference _messagesRef;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _messagesRef =
        FirebaseDatabase.instance.ref('groups/${widget.groupId}/messages');
    _fetchMessages();
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
          _messages = messagesList;
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final messageData = {
        'username': widget.username,
        'message': _messageController.text,
        'timestamp': DateTime
            .now()
            .millisecondsSinceEpoch,
      };

      _messagesRef.push().set(messageData).then((_) {
        _messageController.clear();
        _scrollToBottom();
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      await _messagesRef.push().set({
        'username': widget.username,
        'image': base64Image,
        'timestamp': DateTime
            .now()
            .millisecondsSinceEpoch,
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery
                          .of(context)
                          .size
                          .width * 0.9,
                      maxHeight: MediaQuery
                          .of(context)
                          .size
                          .height * 0.7,
                    ),
                    child: Image.memory(
                      base64Decode(base64Image),
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
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

  void _changeGroupName() {
    String newGroupName = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Group Name'),
          content: TextField(
            onChanged: (value) {
              newGroupName = value;
            },
            decoration: InputDecoration(hintText: "Enter new group name"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                if (newGroupName.isNotEmpty) {
                  FirebaseDatabase.instance.ref(
                      'groups/${widget.groupId}/groupdetail')
                      .update({'groupName': newGroupName});

                  setState(() {
                    widget.groupName = newGroupName;
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeGroupImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      await FirebaseDatabase.instance.ref(
          'groups/${widget.groupId}/groupdetail')
          .update({'groupImage': base64Image});

      setState(() {
        widget.groupImage = base64Image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.groupImage.isNotEmpty
                  ? MemoryImage(base64Decode(widget.groupImage))
                  : AssetImage('assets/default.png') as ImageProvider,
            ),
            SizedBox(width: 10),
            Text(widget.groupName),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'changeName') {
                _changeGroupName();
              } else if (value == 'changeImage') {
                _changeGroupImage();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'changeName',
                  child: Text('Change Group Name'),
                ),
                PopupMenuItem(
                  value: 'changeImage',
                  child: Text('Change Group Image'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUserMessage = message['username'] == widget.username;

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: isUserMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['username'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUserMessage ? Colors.blue : Colors.black,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery
                              .of(context)
                              .size
                              .width * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: isUserMessage ? Colors.blue[100] : Colors
                              .grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: message['message'] != null
                            ? Text(message['message'] ?? '')
                            : message['image'] != null
                            ? GestureDetector(
                          onTap: () => _viewImage(message['image']),
                          child: SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.3,
                            child: Image.memory(
                              base64Decode(message['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : SizedBox.shrink(),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onSubmitted: (value) {
                        _sendMessage();
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
                IconButton(
                  icon: Icon(Icons.photo, color: Colors.green),
                  onPressed: _pickImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
