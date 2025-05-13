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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E7FF),
        title: Text(
          'Payment Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 4,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final vehicle = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(title: "Vehicle Information", children: [
                  _infoRow("Model", vehicle['model']),
                  _infoRow(
                      "Registration Number", vehicle['registrationNumber']),
                  _infoRow("Chassis Number", vehicle['chassisNumber']),
                  _infoRow("Manufacturing Year",
                      vehicle['manufacturingYear'].toString()),
                ]),
                const SizedBox(height: 20),
                _infoCard(title: "Payment Information", children: [
                  if (requestData['selectedOffer'] != null &&
                      requestData['selectedOffer']['price'] != null)
                    _infoRow(
                      "Payed Amount",
                      "${requestData['selectedOffer']['price']} BD",
                    ),
                ]),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  label: Text(
                    "Approve & Mark as Insured",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () async {
                    try {
                      final vehicleRef = FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(vehicleId);
                      final requestRef = FirebaseFirestore.instance
                          .collection('insurance_requests')
                          .doc(requestId);

                      await vehicleRef.update({'isInsured': true});
                      await requestRef.update({
                        'status': 'approved',
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Request approved and marked as insured.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: Colors.grey[700]))),
          Expanded(
              flex: 4,
              child: Text(value,
                  style: GoogleFonts.poppins(color: Colors.black87))),
        ],
      ),
    );
  }
}
