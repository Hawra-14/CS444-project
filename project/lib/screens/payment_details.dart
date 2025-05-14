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

  void _showStyledSnackbar(BuildContext context, String message,
      {bool isError = true}) {
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
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
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
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
        toolbarHeight: 70,
        title: Text(
          "Payment Details",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _sectionCard(
                        "Vehicle Information",
                        [
                          _infoRow("Model", vehicle['model']),
                          _infoRow("Registration Number",
                              vehicle['registrationNumber']),
                          _infoRow("Chassis Number", vehicle['chassisNumber']),
                          _infoRow("Manufacturing Year",
                              vehicle['manufacturingYear']?.toString()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionCard(
                        "Payment Information",
                        [
                          _infoRow(
                            "Paid Amount",
                            requestData['selectedOffer']?['price'] != null
                                ? "${requestData['selectedOffer']['price']} BHD"
                                : "N/A",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text(
                      "Approve & Mark as Insured",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

                        // Get validity period from the request
                        final int validityMonths =
                            (requestData['selectedOffer']?['validity'] ?? 12)
                                .toInt();
                        final now = DateTime.now();
                        final expiryDate = DateTime(
                            now.year, now.month + validityMonths, now.day);

                        await vehicleRef.update({'isInsured': true});

                        // Invalidate old active policies
                        final currentPolicies = await policiesRef
                            .where('vehicleId', isEqualTo: vehicleId)
                            .where('isCurrent', isEqualTo: true)
                            .get();

                        for (var doc in currentPolicies.docs) {
                          await doc.reference.update({'isCurrent': false});
                        }

                        // Create new policy
                        await policiesRef.add({
                          'vehicleId': vehicleId,
                          'registrationNumber':
                              vehicleData['registrationNumber'],
                          'model': vehicleData['model'],
                          'policyValue': requestData['selectedOffer']['price'],
                          'year': now.year,
                          'isCurrent': true,
                          'createdAt': Timestamp.fromDate(now),
                          'expiryDate': Timestamp.fromDate(
                              expiryDate),
                        });
                        await requestRef.delete();
                        deleteNotification(vehicleId);
                        _showStyledSnackbar(
                          context,
                          'Request approved and policy created.',
                          isError: false,
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        _showStyledSnackbar(context, 'Error: $e',
                            isError: true);
                      }
                    }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
              ),
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

Future<void> deleteNotification(String vehicleId) async {
  try {
    // Fetch the notification related to the vehicleId and user
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    for (var doc in querySnapshot.docs) {
      // Delete notification
      await doc.reference.delete();
    }
  } catch (e) {
    print("Error deleting notification: $e");
  }
}

String containsVehicleId(String vehicleId) {
  return "$vehicleId";
}