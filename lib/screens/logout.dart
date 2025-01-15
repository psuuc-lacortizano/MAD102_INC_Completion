import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login.dart';
import 'package:flutter_application_1/services/auth_services.dart';

class logout extends StatefulWidget {
  const logout({super.key});

  @override
  State<logout> createState() => _logoutState();
}

class _logoutState extends State<logout> {
  final auth = AuthServices();

  Future<void> signout() async {
    await auth.signout();
    Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => login(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Log out"),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 42, 152, 255),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Are you sure you want to Log out?",
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                  width: 500,
                  child: ElevatedButton(
                    onPressed: signout,
                    child: Text(
                      "Log out",
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 42, 152, 255)),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
