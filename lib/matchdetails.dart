import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDetailsPage extends StatefulWidget {
  final String matchId;
  const MatchDetailsPage({Key? key, required this.matchId}) : super(key: key);

  @override
  _MatchDetailsPageState createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  final TextEditingController team1ScoreController = TextEditingController();
  final TextEditingController team2ScoreController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  String? selectedStatus;
  List<Map<String, dynamic>> team1Members = [];
  List<Map<String, dynamic>> team2Members = [];
  Map<String, TextEditingController> performanceControllers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      DocumentSnapshot matchSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();
      Map<String, dynamic>? matchData = matchSnapshot.data() as Map<String, dynamic>?;

      if (matchData != null) {
        print("Match data loaded: $matchData");
        setState(() {
          venueController.text = matchData['venue'] ?? '';
          team1ScoreController.text = matchData['team1Score']?.toString() ?? '';
          team2ScoreController.text = matchData['team2Score']?.toString() ?? '';
          selectedStatus = matchData['status'];
        });

        await _loadTeamMembers(matchData['team1Id'], matchData['team2Id']);
      } else {
        print("No match data found for match ID: ${widget.matchId}");
      }
    } catch (e) {
      print("Error fetching match data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadTeamMembers(String? team1Id, String? team2Id) async {
    try {
      if (team1Id != null) {
        QuerySnapshot team1Snapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(team1Id)
            .collection('members')
            .get();
        
        team1Members = team1Snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          performanceControllers[doc.id] = TextEditingController();
          return {'id': doc.id, ...data};
        }).toList();
        print("Loaded Team 1 Members: ${team1Members}");
      } else {
        print("team1Id is null");
      }

      if (team2Id != null) {
        QuerySnapshot team2Snapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(team2Id)
            .collection('members')
            .get();

        team2Members = team2Snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          performanceControllers[doc.id] = TextEditingController();
          return {'id': doc.id, ...data};
        }).toList();
        print("Loaded Team 2 Members: ${team2Members}");
      } else {
        print("team2Id is null");
      }

      setState(() {});
    } catch (e) {
      print("Error fetching team members: $e");
    }
  }

  void _saveMatchDetails() {
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'venue': venueController.text,
      'team1Score': int.tryParse(team1ScoreController.text),
      'team2Score': int.tryParse(team2ScoreController.text),
      'status': selectedStatus,
    }).then((_) {
      _saveMemberPerformance(team1Members);
      _saveMemberPerformance(team2Members);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match details updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update match: $error')),
      );
    });
  }

  void _saveMemberPerformance(List<Map<String, dynamic>> teamMembers) {
    for (var member in teamMembers) {
      String memberId = member['id'];
      String performance = performanceControllers[memberId]?.text ?? '';

      FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('memberPerformance')
          .doc(memberId)
          .set({
        'name': member['name'] ?? 'Unknown',
        'role': member['role'] ?? 'Unknown',
        'performance': performance,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: venueController,
                    decoration: const InputDecoration(
                      labelText: 'Venue',
                      filled: true,
                      fillColor: Color(0xFFF1F8E9),
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Match Status',
                      filled: true,
                      fillColor: Color(0xFFF1F8E9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    items: ['Scheduled', 'In Progress', 'Completed']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: team1ScoreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Team 1 Score',
                            filled: true,
                            fillColor: Color(0xFFF1F8E9),
                            prefixIcon: Icon(Icons.sports),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          controller: team2ScoreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Team 2 Score',
                            filled: true,
                            fillColor: Color(0xFFF1F8E9),
                            prefixIcon: Icon(Icons.sports),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Team 1 Members Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  for (var member in team1Members) ...[
                    ListTile(
                      title: Text('${member['name'] ?? 'Unknown'} (${member['role'] ?? 'Unknown'})'),
                      subtitle: TextField(
                        controller: performanceControllers[member['id']],
                        decoration: const InputDecoration(
                          labelText: 'Performance',
                          filled: true,
                          fillColor: Color(0xFFF1F8E9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Divider(),
                  const Text(
                    'Team 2 Members Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  for (var member in team2Members) ...[
                    ListTile(
                      title: Text('${member['name'] ?? 'Unknown'} (${member['role'] ?? 'Unknown'})'),
                      subtitle: TextField(
                        controller: performanceControllers[member['id']],
                        decoration: const InputDecoration(
                          labelText: 'Performance',
                          filled: true,
                          fillColor: Color(0xFFF1F8E9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveMatchDetails,
                    child: const Text('Save Match Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
