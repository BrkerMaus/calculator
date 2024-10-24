import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'message_page.dart';

class MessageMenu extends StatefulWidget {
  final String username;
  final double avatarSize;
  final double textSize;

  const MessageMenu({
    super.key,
    required this.username,
    this.avatarSize = 50.0,
    this.textSize = 20.0,
  });

  @override
  _MessageMenuState createState() => _MessageMenuState();
}

class _MessageMenuState extends State<MessageMenu> {
  final DatabaseReference _groupsRef = FirebaseDatabase.instance.ref('groups');
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    _groupsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> groupsList = [];

        data.forEach((key, value) {
          final groupDetails = value['groupdetail'] ?? {};
          groupsList.add({
            'groupId': key,
            'groupName': groupDetails['groupName'] ?? 'Unnamed Group',
            'groupImage': groupDetails['groupImage'] ?? '',
          });
        });

        setState(() {
          _groups = groupsList;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${widget.username}'),
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];

          ImageProvider groupImage = group['groupImage'] != ''
              ? _isBase64(group['groupImage'])
              ? MemoryImage(base64Decode(group['groupImage']))
              : NetworkImage(group['groupImage'])
              : AssetImage('assets/default_group.png') as ImageProvider;

          return ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            leading: Container(
              width: widget.avatarSize,
              height: widget.avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: widget.avatarSize,
                  height: widget.avatarSize,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image(
                      image: groupImage,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/default_group.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              group['groupName'],
              style: TextStyle(fontSize: 16.0),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagePage(
                    groupId: group['groupId'],
                    groupName: group['groupName'],
                    groupImage: group['groupImage'],
                    username: widget.username,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}
