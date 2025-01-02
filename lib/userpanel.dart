import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tournament_management_app/matchdetails.dart';
import 'package:tournament_management_app/matchdetailsforuser.dart';

class UserPanelPage extends StatefulWidget {
  const UserPanelPage({Key? key}) : super(key: key);

  @override
  _UserMatchesPageState createState() => _UserMatchesPageState();
}

class _UserMatchesPageState extends State<UserPanelPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> matches = [];

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      // Fetch all matches without filtering by sport
      final querySnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        matches = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching matches: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Matches'),
        backgroundColor: Colors.green.shade800,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matches.isEmpty
              ? const Center(
                  child: Text(
                    "No matches scheduled.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      elevation: 5,
                      child: ListTile(
                        title: Text(
                          '${match['team1']} vs ${match['team2']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sport: ${match['sport'] ?? 'Unknown'}'),
                            Text('Status: ${match['matchStatus'] ?? 'Scheduled'}'),
                            Text('Venue: ${match['venue'] ?? 'TBD'}'),
                            Text('Time: ${match['matchTime'] ?? 'TBD'}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to MatchDetailsPage with the match ID
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserMatchDetailsPage(
                                matchId: match['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}