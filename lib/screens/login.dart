import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/mainscreen.dart';
import 'package:flutter_application_1/screens/signup.dart';
import 'package:flutter_application_1/services/auth_services.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final auth = AuthServices();

  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  login() async {
    final email = emailcontroller.text.trim();
    final password = passwordcontroller.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both email and password.'),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final user = await auth.login(email, password);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User Login Successfully! Welcome, ${user.email}'),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 70,
                  color: const Color.fromARGB(255, 42, 152, 255),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome to Loca",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Link",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 42, 152, 255)),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
                TextField(
                  controller: emailcontroller,
                  decoration: InputDecoration(
                      labelText: "Enter your email",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 238, 237, 250)),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: passwordcontroller,
                  decoration: InputDecoration(
                      labelText: "Enter your password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 238, 237, 250)),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  width: 500,
                  child: ElevatedButton(
                    onPressed: login,
                    child: Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 42, 152, 255)),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => signin(),
                              ));
                        },
                        child: Text(
                          "Sign up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
