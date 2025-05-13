import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentDetailsPage extends StatelessWidget {
  final String requestId;
  final String vehicleId;
  final Map<String, dynamic> requestData;

  const PaymentDetailsPage({
    super.key,
    required this.requestId,
    required this.vehicleId,
    required this.requestData,
  });

  void _showStyledSnackbar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    final Color backgroundColor =
        isError ? Colors.red[400]! : Colors.green[600]!;
    final Icon icon = Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Colors.white,
      size: 24,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        showCloseIcon: true,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E7FF),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Payment Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _infoCard(title: "Vehicle Information", children: [
                        _infoRow("Model", vehicle['model']),
                        _infoRow("Registration Number",
                            vehicle['registrationNumber']),
                        _infoRow("Chassis Number", vehicle['chassisNumber']),
                        _infoRow("Manufacturing Year",
                            vehicle['manufacturingYear'].toString()),
                      ]),
                      const SizedBox(height: 20),
                      _infoCard(title: "Payment Information", children: [
                        if (requestData['selectedOffer'] != null &&
                            requestData['selectedOffer']['price'] != null)
                          _infoRow(
                            "Paid Amount",
                            "${requestData['selectedOffer']['price']} BHD",
                          )
                        else
                          _infoRow("Paid Amount", "N/A"),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    "Approve & Mark as Insured",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final vehicleRef = FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(vehicleId);
                      final requestRef = FirebaseFirestore.instance
                          .collection('insurance_requests')
                          .doc(requestId);
                      final policiesRef = FirebaseFirestore.instance
                          .collection('insurance_policies');

                      final vehicleSnapshot = await vehicleRef.get();
                      final vehicleData =
                          vehicleSnapshot.data() as Map<String, dynamic>;
                      final now = DateTime.now();

                      await vehicleRef.update({'isInsured': true});
                      await requestRef.update({
                        'status': 'approved',
                        'paymentConfirmed': true,
                      });

                      final currentPolicies = await policiesRef
                          .where('vehicleId', isEqualTo: vehicleId)
                          .where('isCurrent', isEqualTo: true)
                          .get();

                      for (var doc in currentPolicies.docs) {
                        if (doc.exists && doc.id != requestRef.id) {
                          await doc.reference.update({'isCurrent': false});
                        }
                      }

                      await policiesRef.add({
                        'vehicleId': vehicleId,
                        'registrationNumber': vehicleData['registrationNumber'],
                        'model': vehicleData['model'],
                        'policyValue': requestData['selectedOffer']['price'],
                        'year': now.year,
                        'isCurrent': true,
                        'createdAt': Timestamp.now(),
                      });

                      _showStyledSnackbar(
                          context, 'Request approved and policy created.');
                      Navigator.of(context).pop();
                    } catch (e) {
                      _showStyledSnackbar(context, 'Error: $e', isError: true);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}
