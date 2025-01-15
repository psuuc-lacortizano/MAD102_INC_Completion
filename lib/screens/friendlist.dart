import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendList extends StatefulWidget {
  const FriendList({super.key});

  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> friendList = [];
  List<String> receivedRequests = [];
  String? _currentUserId;
  String? _currentUserEmail;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _fetchFriendList();
    _fetchReceivedRequests();
  }

  Future<void> _getCurrentUserId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser.uid;
      });
      _getCurrentUserEmail();
    }
  }

  Future<void> _getCurrentUserEmail() async {
    if (_currentUserId != null) {
      final currentUserDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      setState(() {
        _currentUserEmail = currentUserDoc['email'];
      });
    }
  }

  Future<void> _fetchFriendList() async {
    try {
      if (_currentUserId != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_currentUserId).get();
        List<dynamic> friendIds = userDoc['friends'] ?? [];

        List<String> fetchedEmails = [];
        for (var friendId in friendIds) {
          DocumentSnapshot friendDoc =
              await _firestore.collection('users').doc(friendId).get();
          fetchedEmails.add(friendDoc['email']);
        }

        setState(() {
          friendList = fetchedEmails;
        });
      }
    } catch (e) {
      print("Error fetching friend list: $e");
    }
  }

  Future<void> _fetchReceivedRequests() async {
    try {
      if (_currentUserId != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_currentUserId).get();
        List<dynamic> receivedIds = userDoc['friendRequests.received'] ?? [];

        List<String> fetchedEmails = [];
        for (var friendId in receivedIds) {
          DocumentSnapshot friendDoc =
              await _firestore.collection('users').doc(friendId).get();
          fetchedEmails.add(friendDoc['email']);
        }

        setState(() {
          receivedRequests = fetchedEmails;
        });
      }
    } catch (e) {
      print("Error fetching received friend requests: $e");
    }
  }

  Future<void> _acceptFriendRequest(String friendEmail) async {
    try {
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isNotEmpty) {
        final friendId = friendQuery.docs.first.id;

        await _firestore.collection('users').doc(_currentUserId).update({
          'friends': FieldValue.arrayUnion([friendId]),
        });

        await _firestore.collection('users').doc(friendId).update({
          'friends': FieldValue.arrayUnion([_currentUserId]),
        });

        await _firestore.collection('users').doc(_currentUserId).update({
          'friendRequests.received': FieldValue.arrayRemove([friendId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request accepted!')),
        );

        setState(() {
          friendList.add(friendEmail);
          receivedRequests.remove(friendEmail);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _declineFriendRequest(String friendEmail) async {
    try {
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isNotEmpty) {
        final friendId = friendQuery.docs.first.id;

        await _firestore.collection('users').doc(_currentUserId).update({
          'friendRequests.received': FieldValue.arrayRemove([friendId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request declined!')),
        );

        setState(() {
          receivedRequests.remove(friendEmail);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<bool> _checkIfEmailExists(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

  Future<void> _sendFriendRequest(String friendEmail) async {
    if (friendEmail == _currentUserEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You cannot send a friend request to yourself!')),
      );
      return;
    }

    try {
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isNotEmpty) {
        final friendDoc = friendQuery.docs.first;
        final friendId = friendDoc.id;

        final currentUserDoc =
            await _firestore.collection('users').doc(_currentUserId).get();
        final friends = List<String>.from(currentUserDoc['friends'] ?? []);
        if (friends.contains(friendId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You are already friends with this user!')),
          );
          return;
        }

        await _firestore.collection('users').doc(_currentUserId).update({
          'friendRequests.sent': FieldValue.arrayUnion([friendId]),
        });

        await _firestore.collection('users').doc(friendId).update({
          'friendRequests.received': FieldValue.arrayUnion([_currentUserId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkAndSendFriendRequest() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    bool emailExists = await _checkIfEmailExists(email);

    if (emailExists) {
      _sendFriendRequest(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user found with this email')),
      );
    }
  }

  Future<void> _unfriend(String friendEmail) async {
    try {
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isNotEmpty) {
        final friendId = friendQuery.docs.first.id;

        await _firestore.collection('users').doc(_currentUserId).update({
          'friends': FieldValue.arrayRemove([friendId]),
        });

        await _firestore.collection('users').doc(friendId).update({
          'friends': FieldValue.arrayRemove([_currentUserId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('You are no longer friends with $friendEmail')),
        );

        setState(() {
          friendList.remove(friendEmail);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Lists"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 42, 152, 255),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: "Enter email to add friend",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 238, 237, 250)),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _checkAndSendFriendRequest,
                  child: Text("Add", style: TextStyle(color: Colors.white)),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromARGB(255, 42, 152, 255)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Friend List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friendList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(friendList[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _unfriend(friendList[index]),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Friend Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: receivedRequests.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(receivedRequests[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () =>
                              _acceptFriendRequest(receivedRequests[index]),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () =>
                              _declineFriendRequest(receivedRequests[index]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
