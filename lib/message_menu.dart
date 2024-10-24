import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'message_page.dart';
import 'dart:io'; // Import for File
import 'dart:math';
import 'package:image_picker/image_picker.dart';

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
    _groupsRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> groupsList = [];

        data.forEach((key, value) {
          final groupDetails = value['groupdetail'] ?? {};
          final groupUsers = value['groupuser'] ?? {};

          // Check if the current user's username is in the groupuser
          if (groupUsers[widget.username] != null) {
            groupsList.add({
              'groupId': key,
              'groupName': groupDetails['groupName'] ?? 'Unnamed Group',
              'groupImage': groupDetails['groupImage'] ?? '',
            });
          }
        });

        setState(() {
          _groups = groupsList;
        });
      }
    });
  }


  Future<void> _showGroupOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.0),
          height: 200,
          child: Column(
            children: [
              ListTile(
                title: Text('Create Group'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateGroupDialog();
                },
              ),
              ListTile(
                title: Text('Join Group'),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinGroupDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateGroupDialog() async {
    String groupName = '';
    String groupPassword = '';
    String groupImage = ''; // This will hold the base64 string of the selected image
    bool isImageAdded = false; // Track if an image has been added
    String buttonMessage = 'Pick Group Image'; // Message for the button

    final ImagePicker _picker = ImagePicker(); // Create an ImagePicker instance

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Group Name'),
                  onChanged: (value) {
                    groupName = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Group Password'),
                  onChanged: (value) {
                    groupPassword = value;
                  },
                ),
                // Add a button to pick an image
                ElevatedButton(
                  onPressed: () async {
                    // Pick an image from the gallery
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      // Read the image file as bytes
                      final bytes = await File(image.path).readAsBytes();
                      setState(() {
                        groupImage = base64Encode(bytes); // Convert bytes to base64 string
                        isImageAdded = true; // Update image state to true
                        buttonMessage = 'Picture was updated'; // Update message
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Picture was added')),
                      );
                    }
                  },
                  child: Text(buttonMessage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isImageAdded ? Colors.green : null, // Change button color
                  ),
                ),
                // Show the selected image (optional)
                if (groupImage.isNotEmpty)
                  Image.memory(
                    base64Decode(groupImage),
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (groupName.isNotEmpty && groupPassword.isNotEmpty) {
                  // Generate a unique groupId
                  String groupId = _generateGroupId();
                  // Store group details in Firebase
                  await _groupsRef.child(groupId).set({
                    'groupdetail': {
                      'groupName': groupName,
                      'groupPassword': groupPassword,
                      'groupImage': groupImage, // Save the base64 string of the image
                    },
                    'groupuser': {
                      widget.username: true, // Store the current user's username
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _showJoinGroupDialog() async {
    final idController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Join Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: InputDecoration(labelText: 'Group ID'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Group Password'),
                obscureText: true, // To hide password input
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String groupId = idController.text;
                String groupPassword = passwordController.text;

                print("Join button clicked"); // Debug log

                if (groupId.isNotEmpty && groupPassword.isNotEmpty) {
                  print("Group ID: $groupId, Group Password: $groupPassword"); // Debug log

                  // Fetch the group data for the given groupId
                  DatabaseReference groupRef = FirebaseDatabase.instance.ref('groups/$groupId');
                  print('Fetching group data from Firebase for groupId: $groupId'); // Debug log

                  try {
                    final snapshot = await groupRef.get();

                    if (snapshot.exists) {
                      // Group exists, retrieve data
                      Map<dynamic, dynamic>? groupData = snapshot.value as Map<dynamic, dynamic>?;
                      print('Group Data: $groupData'); // Debug log the entire group data

                      if (groupData != null) {
                        final groupDetail = groupData['groupdetail'];

                        if (groupDetail != null && groupDetail['groupPassword'] == groupPassword) {
                          // Password matches, add user to the group
                          print("Password matches, adding user to the group"); // Debug log
                          await groupRef.child('groupuser/${widget.username}').set(true);

                          // Close the dialog
                          Navigator.pop(context);

                          // Refresh the group list after successfully joining
                          _fetchGroups();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Successfully joined the group!')),
                          );
                        } else {
                          // Incorrect password
                          print("Incorrect password"); // Debug log
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Incorrect group password')),
                          );
                        }
                      } else {
                        print("No group detail found"); // Debug log
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Group detail not found')),
                        );
                      }
                    } else {
                      // Group doesn't exist
                      print("Group not found"); // Debug log
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Group not found')),
                      );
                    }
                  } catch (error) {
                    print("Error fetching group data: $error"); // Log the error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error fetching group data: $error')),
                    );
                  }
                } else {
                  print("Group ID or Password is empty"); // Debug log
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter both Group ID and Password')),
                  );
                }
              },
              child: Text('Join'),
            ),
          ],
        );
      },
    );
  }





  String _generateGroupId() {
    // Generates a unique group ID (You can change this to your own logic)
    return 'group_${Random().nextInt(10000)}';
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showGroupOptions,
        child: Icon(Icons.add),
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
