import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/screens/offer_selection_details.dart';
import 'package:project/screens/payment_details.dart';
import 'package:project/screens/request_Details.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Admin Panel",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
          elevation: 6,
          shadowColor: Colors.black38,
          centerTitle: true,
          toolbarHeight: 70,
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending requests."));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final vehicleId = req['vehicleId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .get(),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) return const SizedBox();
                final vehicleData =
                    vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                if (vehicleData == null) return const SizedBox();

                final model = vehicleData['model'] ?? 'Unknown Model';
                final registrationNumber =
                    vehicleData['registrationNumber'] ?? 'Unknown';
                final chassisNumber = vehicleData['chassisNumber'] ?? 'Unknown';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No offer selection requests."));
        }

        final offerRequests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: offerRequests.length,
          itemBuilder: (context, index) {
            final req = offerRequests[index];
            final vehicleId = req['vehicleId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .get(),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) return const SizedBox();
                final vehicleData =
                    vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                if (vehicleData == null) return const SizedBox();

                final model = vehicleData['model'] ?? 'Unknown Model';
                final registrationNumber =
                    vehicleData['registrationNumber'] ?? 'Unknown';
                final chassisNumber = vehicleData['chassisNumber'] ?? 'Unknown';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
          .where('status', isEqualTo: 'payment_done')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No payments pending approval."));
        }

        final payments = snapshot.data!.docs;
      
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final req = payments[index];
            final vehicleId = req['vehicleId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .get(),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) return const SizedBox();
                final vehicleData =
                    vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                if (vehicleData == null) return const SizedBox();

                final model = vehicleData['model'] ?? 'Unknown Model';
                final registrationNumber =
                    vehicleData['registrationNumber'] ?? 'Unknown';
                final chassisNumber = vehicleData['chassisNumber'] ?? 'Unknown';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                          builder: (_) => PaymentDetailsPage(
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
