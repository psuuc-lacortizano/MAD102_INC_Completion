import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login.dart';
import 'package:flutter_application_1/services/auth_services.dart';

class signin extends StatefulWidget {
  const signin({super.key});

  @override
  State<signin> createState() => _signinState();
}

class _signinState extends State<signin> {
  final auth = AuthServices();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController usernamecontroller = TextEditingController();

  signup() async {
    final email = emailcontroller.text.trim();
    final password = passwordcontroller.text.trim();
    final username = usernamecontroller.text.trim();
    // Validate that the email, password, and username are not empty

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter all the fields (email, password, username).'),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    try {
      final user = await auth.signUp(emailcontroller.text,
          passwordcontroller.text, usernamecontroller.text);

      if (user != null) {
        print("User Created Successfully!");
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => login(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.black87,
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
                      "Make an account for Loca",
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
                  controller: usernamecontroller,
                  decoration: InputDecoration(
                      labelText: "Enter username",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 238, 237, 250)),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: emailcontroller,
                  decoration: InputDecoration(
                      labelText: "Enter valid email",
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
                      labelText: "Enter password",
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
                    onPressed: signup,
                    child: Text(
                      "Sign In",
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
                    Text("Already have an account?"),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => login(),
                              ));
                        },
                        child: Text("Log in",
                            style: TextStyle(fontWeight: FontWeight.bold)))
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
