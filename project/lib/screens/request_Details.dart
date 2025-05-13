import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestDetailsPage extends StatefulWidget {
  final String requestId;
  final String vehicleId;
  final Map<String, dynamic> requestData;

  const RequestDetailsPage({
    super.key,
    required this.requestId,
    required this.vehicleId,
    required this.requestData,
  });

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  bool _isProcessing = false;

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

  Future<void> _handleDecision(
      bool approve, double priceWhenNew, int year) async {
    setState(() => _isProcessing = true);
    final ref = FirebaseFirestore.instance
        .collection('insurance_requests')
        .doc(widget.requestId);
    final int diff = DateTime.now().year - year;
    double renewalBase = priceWhenNew;

    for (int i = 0; i < diff; i++) {
      renewalBase *= 0.9;
    }

    try {
      if (approve) {
        List<Map<String, dynamic>> offers = [
          {'price': (renewalBase * 0.6).round(), 'validity': '6 months'},
          {'price': renewalBase.round(), 'validity': '12 months'},
          {'price': (renewalBase * 1.4).round(), 'validity': '18 months'},
        ];
        await ref.update({
          'status': 'offers_sent',
          'adminResponse': {'offerOptions': offers}
        });
        _showStyledSnackbar(context, 'Request approved and offers sent.',
            isError: false);
      }
      Navigator.pop(context);
    } catch (e) {
      _showStyledSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
        elevation: 6,
        shadowColor: Colors.black38,
        centerTitle: true,
        toolbarHeight: 70,
        title: Text(
          'Request Details',
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
            .doc(widget.vehicleId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Vehicle data not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final model = data['model'] ?? 'N/A';
          final reg = data['registrationNumber'] ?? 'N/A';
          final chassis = data['chassisNumber'] ?? 'N/A';
          final price = (data['priceWhenNew'] is num)
              ? (data['priceWhenNew'] as num).toDouble()
              : double.tryParse(data['priceWhenNew'].toString()) ?? 0.0;
          final year =
              int.tryParse(data['manufacturingYear']?.toString() ?? '') ?? 0;
          final passengers = data['numPassengers']?.toString() ?? 'N/A';
          final driverAge = data['driverAge']?.toString() ?? 'N/A';
          final hadAccident = data['hasAccidentBefore'] == true ? 'Yes' : 'No';

          final status = widget.requestData['status'] ?? 'N/A';
          final userId = widget.requestData['userId'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _buildCard('Vehicle Information', [
                        _buildInfoRow('Model', model),
                        _buildInfoRow('Registration Number', reg),
                        _buildInfoRow('Chassis Number', chassis),
                        _buildInfoRow('Manufacturing Year', year.toString()),
                        _buildInfoRow('Number of Passengers', passengers),
                        _buildInfoRow('Driver Age', driverAge),
                        _buildInfoRow('Has Accident Before', hadAccident),
                        _buildInfoRow('Price When New',
                            '${price.toStringAsFixed(2)} BHD'),
                      ]),
                      const SizedBox(height: 16),
                      _buildCard('Request Information', [
                        _buildInfoRow('Request ID', widget.requestId),
                        _buildInfoRow('User ID', userId),
                        _buildInfoRow('Status', status,
                            textColor: _getStatusColor(status), isBold: true),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text("Approve",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                        onPressed: _isProcessing
                            ? null
                            : () => _handleDecision(true, price, year),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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
              value,
              style: GoogleFonts.poppins(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'offer_selected':
        return Colors.blue;
      default:
        return Colors.black87;
    }
  }
}
