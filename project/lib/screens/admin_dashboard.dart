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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
          elevation: 6,
          shadowColor: Colors.black38,
          centerTitle: true,
          toolbarHeight: 70,
          title: Text(
            "Admin Panel",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF4F46E5),
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
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

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .snapshots(),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) return const SizedBox();
                final vehicleData =
                    vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                if (vehicleData == null) return const SizedBox();

                final model = vehicleData['model'] ?? 'Unknown Model';
                final regNumber = vehicleData['registrationNumber'] ?? 'Unknown';
                final chassis = vehicleData['chassisNumber'] ?? 'Unknown';

                return VehicleRequestCard(
                  title: model,
                  regNumber: regNumber,
                  chassisNumber: chassis,
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

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final vehicleId = req['vehicleId'];

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .snapshots(),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) return const SizedBox();
                final vehicleData =
                    vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                if (vehicleData == null) return const SizedBox();

                final model = vehicleData['model'] ?? 'Unknown Model';
                final regNumber = vehicleData['registrationNumber'] ?? 'Unknown';
                final chassis = vehicleData['chassisNumber'] ?? 'Unknown';

                return VehicleRequestCard(
                  title: model,
                  regNumber: regNumber,
                  chassisNumber: chassis,
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

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final vehicleId = req['vehicleId'];

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .snapshots(),
              builder: (context, vehicleSnapshot) {
                if (!vehicleSnapshot.hasData) return const SizedBox();
                final vehicleData =
                    vehicleSnapshot.data?.data() as Map<String, dynamic>?;

                if (vehicleData == null) return const SizedBox();

                final model = vehicleData['model'] ?? 'Unknown Model';
                final regNumber = vehicleData['registrationNumber'] ?? 'Unknown';
                final chassis = vehicleData['chassisNumber'] ?? 'Unknown';

                return VehicleRequestCard(
                  title: model,
                  regNumber: regNumber,
                  chassisNumber: chassis,
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
                );
              },
            );
          },
        );
      },
    );
  }
}
class VehicleRequestCard extends StatelessWidget {
  final String title;
  final String regNumber;
  final String chassisNumber;
  final VoidCallback onTap;

  const VehicleRequestCard({
    super.key,
    required this.title,
    required this.regNumber,
    required this.chassisNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        tileColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Reg#: $regNumber",
                  style: GoogleFonts.poppins(fontSize: 14)),
              Text("Chassis#: $chassisNumber",
                  style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
