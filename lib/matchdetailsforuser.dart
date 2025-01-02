import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMatchDetailsPage extends StatefulWidget {
  final String matchId;

  const UserMatchDetailsPage({Key? key, required this.matchId}) : super(key: key);

  @override
  _UserMatchDetailsPageState createState() => _UserMatchDetailsPageState();
}

class _UserMatchDetailsPageState extends State<UserMatchDetailsPage> {
  Map<String, dynamic>? matchData;
  Map<String, dynamic>? team1Data;
  Map<String, dynamic>? team2Data;
  List<Map<String, dynamic>> team1Members = [];
  List<Map<String, dynamic>> team2Members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToMatchData();
  }

  void _listenToMatchData() {
    FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .snapshots()
        .listen((matchSnapshot) async {
      if (matchSnapshot.exists) {
        matchData = matchSnapshot.data() as Map<String, dynamic>?;

        if (matchData != null) {
          await _loadTeamData(matchData!['team1Id'], matchData!['team2Id']);
        }
      }
      setState(() => isLoading = false);
    });
  }

  Future<void> _loadTeamData(String? team1Id, String? team2Id) async {
    try {
      if (team1Id != null) {
        DocumentSnapshot team1Snapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(team1Id)
            .get();
        team1Data = team1Snapshot.data() as Map<String, dynamic>?;

        QuerySnapshot team1MembersSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(team1Id)
            .collection('members')
            .get();

        team1Members = team1MembersSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, ...data};
        }).toList();
      }

      if (team2Id != null) {
        DocumentSnapshot team2Snapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(team2Id)
            .get();
        team2Data = team2Snapshot.data() as Map<String, dynamic>?;

        QuerySnapshot team2MembersSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(team2Id)
            .collection('members')
            .get();

        team2Members = team2MembersSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, ...data};
        }).toList();
      }
      setState(() {});
    } catch (e) {
      print("Error fetching team details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        backgroundColor: Colors.green.shade800,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matchData == null
              ? const Center(
                  child: Text(
                    "No details available for this match.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${team1Data?['name'] ?? 'Team 1'} vs ${team2Data?['name'] ?? 'Team 2'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Venue: ${matchData!['venue'] ?? 'TBD'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Match Time: ${matchData!['matchTime'] ?? 'TBD'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${matchData!['status'] ?? 'Scheduled'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Score: ${matchData!['team1Score'] ?? 0} - ${matchData!['team2Score'] ?? 0}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Divider(height: 30),
                      Text(
                        '${team1Data?['name'] ?? 'Team 1'} Members',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      for (var member in team1Members)
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(member['name'] ?? 'Unknown'),
                          subtitle: Text(member['role'] ?? 'Unknown Role'),
                        ),
                      const Divider(height: 30),
                      Text(
                        '${team2Data?['name'] ?? 'Team 2'} Members',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      for (var member in team2Members)
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(member['name'] ?? 'Unknown'),
                          subtitle: Text(member['role'] ?? 'Unknown Role'),
                        ),
                    ],
                  ),
                ),
    );
  }
}
