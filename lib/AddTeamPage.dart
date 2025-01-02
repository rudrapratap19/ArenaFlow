import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TeamMembersPage.dart';
import 'match_making.dart';

class AddTeamPage extends StatefulWidget {
  final String sport;
  const AddTeamPage({super.key, required this.sport});

  @override
  _AddTeamPageState createState() => _AddTeamPageState();
}

class _AddTeamPageState extends State<AddTeamPage> {
  final List<TextEditingController> _teamControllers = [];
  final List<String?> _teamIds = [];

  @override
  void initState() {
    super.initState();
    _loadExistingTeams();
  }

  Future<void> _loadExistingTeams() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .where('sport', isEqualTo: widget.sport) // Only load teams for this sport
        .get();

    setState(() {
      _teamControllers.clear();
      _teamIds.clear();

      for (var doc in querySnapshot.docs) {
        _teamControllers.add(TextEditingController(text: doc['teamName'] ?? ''));
        _teamIds.add(doc.id);
      }
    });
  }

  void _addNewTeamField() {
    setState(() {
      _teamControllers.add(TextEditingController());
      _teamIds.add(null);
    });
  }

  void _deleteTeamField(int index) {
    setState(() {
      _teamControllers[index].dispose();
      _teamControllers.removeAt(index);
      _teamIds.removeAt(index);
    });
  }

  Future<void> _saveTeams() async {
    for (int i = 0; i < _teamControllers.length; i++) {
      final teamName = _teamControllers[i].text.trim();
      if (teamName.isNotEmpty) {
        if (_teamIds[i] == null) {
          DocumentReference teamRef = await FirebaseFirestore.instance.collection('teams').add({
            'teamName': teamName,
            'sport': widget.sport, // Save sport in team data
          });
          setState(() {
            _teamIds[i] = teamRef.id;
          });
        } else {
          await FirebaseFirestore.instance.collection('teams').doc(_teamIds[i]).update({
            'teamName': teamName,
          });
        }
      }
    }
  }

  void _navigateToTeamMembersPage(int index) {
    if (_teamIds[index] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamMembersPage(
            teamName: _teamControllers[index].text,
            teamId: _teamIds[index]!,
          ),
        ),
      );
    }
  }

  void _navigateToMatchMakingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchMakingPage(
          teams: _teamControllers.map((controller) => controller.text).toList(),
          sport: widget.sport, // Pass the sport to match-making page
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _teamControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Teams - ${widget.sport}'),
        centerTitle: true,
        backgroundColor: Colors.green.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent.shade100, Colors.green.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Enter Team Names',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _teamControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _teamControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Team Name ${index + 1}',
                                labelStyle: const TextStyle(color: Colors.black54),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.group, color: Colors.black54),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _teamControllers.length > 1
                                ? () => _deleteTeamField(index)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _navigateToTeamMembersPage(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(126, 46, 125, 50),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            child: const Icon(Icons.person, color: Colors.white),
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
                  onPressed: _addNewTeamField,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Add New Team', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _saveTeams,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Save Teams', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToMatchMakingPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Schedule Matches', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
