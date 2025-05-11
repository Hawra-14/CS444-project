import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'request_details_page.dart';
import 'completed_request_details_page.dart'; // <- You’ll create this

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _showSnack(BuildContext context, String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: error ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Requests'),
        backgroundColor: Colors.indigo.shade200,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('insurance_requests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final requests = snapshot.data!.docs;
                if (requests.isEmpty) return const Center(child: Text("No pending requests."));

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final vehicleId = req['vehicleId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get(),
                      builder: (context, vehicleSnapshot) {
                        if (!vehicleSnapshot.hasData) return const SizedBox();
                        final vehicleData = vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                        if (vehicleData == null) return const SizedBox();

                        final model = vehicleData['model'] ?? 'Unknown Model';
                        final registrationNumber = vehicleData['registrationNumber'] ?? 'Unknown';
                        final chassisNumber = vehicleData['chassisNumber'] ?? 'Unknown';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(model),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Reg#: $registrationNumber"),
                                Text("Chassis#: $chassisNumber"),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RequestDetailsPage(
                                    requestId: req.id,
                                    vehicleId: vehicleId,
                                    requestData: req.data() as Map<String, dynamic>,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.black54),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Offers Selection Requests", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('insurance_requests')
                  .where('status', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final completedRequests = snapshot.data!.docs;

                if (completedRequests.isEmpty) {
                  return const Center(child: Text("No offers selection requests yet."));
                }

                return ListView.builder(
                  itemCount: completedRequests.length,
                  itemBuilder: (context, index) {
                    final req = completedRequests[index];
                    final requestData = req.data() as Map<String, dynamic>;
                    final vehicleId = requestData['vehicleId'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      color: Colors.green[50],
                      child: ListTile(
                        title: Text("User: ${requestData['userId'] ?? 'Unknown'}"),
                        subtitle: Text("Click to view selected offer"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompletedRequestDetailsPage(
                                requestId: req.id,
                                vehicleId: vehicleId,
                                requestData: requestData,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
