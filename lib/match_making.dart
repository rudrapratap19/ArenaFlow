import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class MatchMakingPage extends StatefulWidget {
  final List<String> teams;
  final String sport;

  const MatchMakingPage({super.key, required this.teams, required this.sport});

  @override
  _MatchMakingPageState createState() => _MatchMakingPageState();
}

class _MatchMakingPageState extends State<MatchMakingPage> {
  final List<TextEditingController> _venueControllers = [];
  final List<TextEditingController> _timeControllers = [];
  final Map<int, String> matchIds = {}; // Store document IDs for each match

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers for venue and time based on the number of matches
    int matchCount = (widget.teams.length / 2).ceil();
    for (int i = 0; i < matchCount; i++) {
      _venueControllers.add(TextEditingController());
      _timeControllers.add(TextEditingController());
    }
  }

  Future<void> _clearPreviousMatches() async {
    final matchCollection = FirebaseFirestore.instance.collection('matches');
    final snapshot = await matchCollection
        .where('sport', isEqualTo: widget.sport) // Clear only matches for this sport
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _saveMatchesToFirebase(List<List<String>> pairs) async {
    final matchCollection = FirebaseFirestore.instance.collection('matches');
    for (var i = 0; i < pairs.length; i++) {
      var pair = pairs[i];
      DocumentReference matchDocRef = await matchCollection.add({
        'team1': pair[0],
        'team2': pair[1],
        'sport': widget.sport, // Save the sport in each match document
        'matchStatus': 'Scheduled',
        'venue': _venueControllers[i].text.isEmpty ? 'TBD' : _venueControllers[i].text,
        'matchTime': _timeControllers[i].text.isEmpty ? 'TBD' : _timeControllers[i].text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      matchIds[i] = matchDocRef.id; // Store the document ID for each match
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teams.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Match Making"),
          backgroundColor: Colors.green.shade800,
        ),
        body: const Center(
          child: Text(
            "No teams available for matchmaking.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    // Shuffle teams and pair them
    List<String> shuffledTeams = List.from(widget.teams)..shuffle(Random());
    List<List<String>> pairs = [];
    for (int i = 0; i < shuffledTeams.length - 1; i += 2) {
      pairs.add([shuffledTeams[i], shuffledTeams[i + 1]]);
    }
    if (shuffledTeams.length % 2 != 0) {
      pairs.add([shuffledTeams.last, "Bye"]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Match Making - ${widget.sport}"),
        backgroundColor: Colors.green.shade800,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: pairs.length,
        itemBuilder: (context, index) {
          var pair = pairs[index];
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${pair[0]} vs ${pair[1]}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _venueControllers[index],
                    decoration: InputDecoration(
                      labelText: "Venue",
                      labelStyle: TextStyle(color: Colors.green.shade800),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.location_on, color: Colors.green.shade800),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _timeControllers[index],
                    decoration: InputDecoration(
                      labelText: "Match Time",
                      labelStyle: TextStyle(color: Colors.green.shade800),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.access_time, color: Colors.green.shade800),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _clearPreviousMatches();
          await _saveMatchesToFirebase(pairs);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Matches have been scheduled!")),
          );
        },
        backgroundColor: Colors.green.shade800,
        child: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _venueControllers) {
      controller.dispose();
    }
    for (var controller in _timeControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
