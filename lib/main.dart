import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import '../message_page.dart';


FirebaseDatabase database = FirebaseDatabase.instance;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      String enteredUsername = _userController.text;
      String enteredPassword = _passwordController.text;

      // Reference to the Firebase Realtime Database
      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$enteredUsername');

      try {
        // Fetch the data for the entered username
        DataSnapshot snapshot = await userRef.get();

        if (snapshot.exists) {
          Map userData = snapshot.value as Map;

          String storedUsername = userData['username'];
          String storedPassword = userData['password'].toString(); // Convert to String

          // Compare entered credentials with the stored ones
          if (enteredUsername == storedUsername && enteredPassword == storedPassword) {
            // Successful login
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ));

            // Navigate to the UserHomePage, passing the username
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MessagePage(username: storedUsername)),
            );
          } else {
            // Incorrect password
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Invalid username or password'),
              backgroundColor: Colors.red,
            ));
          }
        } else {
          // User doesn't exist
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('User not found'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        // Handle errors
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred during login'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(
          'Calculator',
          style: TextStyle(color: Color(0xFFCC1E4A)), // Change font color to white or any color you prefer
        )),
        toolbarHeight: kToolbarHeight,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 400, // Set the desired width
            child: Card(
              color: Color(0xFF121F45),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  color: Color(0xFF121F45), // Set the inner padding color
                  padding: EdgeInsets.all(16.0), // Inner padding
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _userController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: Color(0xFFFFC906)), // Set label color
                            floatingLabelStyle: TextStyle(color: Color(0xFFFFC906)), // Label color when focused
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Circular border
                              borderSide: BorderSide(color: Color(0xFFFFC906)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Circular border
                              borderSide: BorderSide(color: Color(0xFFFFC906)), // Set the enabled border color
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Circular border when focused
                              borderSide: BorderSide(color: Color(0xFFFFC906)), // Set the focused border color
                            ),
                          ),
                          style: TextStyle(color: Color(0xFFFFC906)), // Set the font color
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Color(0xFFFFC906)), // Set label color
                            floatingLabelStyle: TextStyle(color: Color(0xFFFFC906)), // Label color when focused
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Circular border
                              borderSide: BorderSide(color: Color(0xFFFFC906)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Circular border
                              borderSide: BorderSide(color: Color(0xFFFFC906)), // Set the enabled border color
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Circular border when focused
                              borderSide: BorderSide(color: Color(0xFFFFC906)), // Set the focused border color
                            ),
                          ),
                          style: TextStyle(color: Color(0xFFFFC906)), // Set the font color
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _login,
                          child: Text(
                            'Login',
                            style: TextStyle(color: Colors.white), // Change font color to white or any color you prefer
                          ),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Color(0xFFCC1E4A)), // Set the button color
                            minimumSize: MaterialStateProperty.all(Size(double.infinity, 40)), // Minimum size
                            elevation: MaterialStateProperty.all(5), // Add shadow effect
                            shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.5)), // Shadow color and opacity
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Rounded corners
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
