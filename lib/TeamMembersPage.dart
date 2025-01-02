import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMembersPage extends StatefulWidget {
  final String teamName;
  final String teamId;
  const TeamMembersPage({super.key, required this.teamName, required this.teamId});

  @override
  _TeamMembersPageState createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  final List<TextEditingController> _memberControllers = [];
  final List<String?> _memberIds = []; // Store Firestore document IDs

  @override
  void initState() {
    super.initState();
    _loadExistingMembers(); // Load previously saved members
  }

  // Load existing members from Firestore
  Future<void> _loadExistingMembers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('members')
        .get();

    for (var doc in snapshot.docs) {
      final controller = TextEditingController(text: doc['memberName']);
      _memberControllers.add(controller);
      _memberIds.add(doc.id);
    }

    // If there are no existing members, add an empty field
    if (_memberControllers.isEmpty) {
      _addNewMemberField();
    }

    setState(() {}); // Refresh the UI
  }

  // Add a new member field
  void _addNewMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
      _memberIds.add(null); // For new members without an existing Firestore ID
    });
  }

  // Delete a member field
  void _deleteMemberField(int index) {
    setState(() {
      _memberControllers[index].dispose();
      _memberControllers.removeAt(index);
      _memberIds.removeAt(index);
    });
  }

  // Save or update members in Firestore
  Future<void> _saveMembers() async {
    for (int i = 0; i < _memberControllers.length; i++) {
      final memberName = _memberControllers[i].text;
      if (memberName.isNotEmpty) {
        if (_memberIds[i] == null) {
          // Add new member to Firestore
          DocumentReference memberRef = await FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('members')
              .add({'memberName': memberName});
          _memberIds[i] = memberRef.id;
        } else {
          // Update existing member name
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('members')
              .doc(_memberIds[i])
              .update({'memberName': memberName});
        }
      }
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (var controller in _memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Members - ${widget.teamName}'),
        backgroundColor: Colors.green.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Enter Member Names',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _memberControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _memberControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Member Name ${index + 1}',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person, color: Colors.black54),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (index == _memberControllers.length - 1)
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green.shade800),
                            onPressed: _addNewMemberField,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _memberControllers.length > 1 ? () => _deleteMemberField(index) : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveMembers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text('Save Members', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
