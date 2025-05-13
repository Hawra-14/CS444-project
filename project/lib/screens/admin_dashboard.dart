import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:project/screens/offer_selection_details.dart';
import 'package:project/screens/request_Details.dart';
=======
// import 'package:google_fonts/google_fonts.dart';
import 'request_details_page.dart';
import 'selected_offer.dart';
>>>>>>> 5a4ef1a1ac8766dd7e5ca3426cd8e603f9ceb061

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // void _showSnack(BuildContext context, String msg, bool error) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
  //       backgroundColor: error ? Colors.red : Colors.green,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: const Text('Admin Panel')),
          backgroundColor: Color(0xFFE0E7FF),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Insurance Requests'),
              Tab(text: 'Offer Requests'),
              Tab(text: 'Payment Approvals'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            InsuranceRequestsTab(),
            OfferSelectionRequestsTab(),
            PaymentApprovalTab(),
          ],
        ),
      ),
    );
  }
}

class InsuranceRequestsTab extends StatelessWidget {
  const InsuranceRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
    );
  }
}

class OfferSelectionRequestsTab extends StatelessWidget {
  const OfferSelectionRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('insurance_requests')
          .where('status', isEqualTo: 'offerSelected')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final offerRequests = snapshot.data!.docs;
        if (offerRequests.isEmpty) {
          return const Center(child: Text("No offer selection requests."));
        }

        return ListView.builder(
          itemCount: offerRequests.length,
          itemBuilder: (context, index) {
            final req = offerRequests[index];
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
                          builder: (_) => OfferSelectionDetailsPage(
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
    );
  }
}

class PaymentApprovalTab extends StatelessWidget {
  const PaymentApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('insurance_requests')
          .where('adminApproved', isEqualTo: true)
          .where('paymentConfirmed', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final payments = snapshot.data!.docs;
        if (payments.isEmpty) return const Center(child: Text("No payments pending approval."));

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final req = payments[index];
            final requestData = req.data() as Map<String, dynamic>;
            final vehicleId = requestData['vehicleId'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Colors.orange[50],
              child: ListTile(
                title: Text("Payment pending for: ${requestData['userId'] ?? 'Unknown'}"),
                subtitle: const Text("Tap to view and approve payment"),
                trailing: const Icon(Icons.payment),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailsPage(
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
    );
=======
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
                  return const Center(child: Text("No requests yet."));
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
                              builder: (_) => SelectedOfferPage(
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
>>>>>>> 5a4ef1a1ac8766dd7e5ca3426cd8e603f9ceb061
  }
}
