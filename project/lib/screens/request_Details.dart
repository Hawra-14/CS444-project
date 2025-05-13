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
    final Color backgroundColor = isError ? Colors.red[400]! : Colors.green[600]!;
    final Icon icon = Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Colors.white,
      size: 24,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        content: Row(
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
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleDecision(bool approve, double priceWhenNew, int manufacturingYear) async {
    setState(() => _isProcessing = true);

    final requestRef = FirebaseFirestore.instance
        .collection('insurance_requests')
        .doc(widget.requestId);
    final currentYear = DateTime.now().year;

    double renewalBasePrice = priceWhenNew;
    for (int i = 0; i < currentYear - manufacturingYear; i++) {
      renewalBasePrice *= 0.9;
    }

    try {
      if (approve) {
        List<Map<String, dynamic>> offerOptions = [
          {'price': (renewalBasePrice * 0.6).round(), 'validity': '6 months'},
          {'price': (renewalBasePrice).round(), 'validity': '12 months'},
          {'price': (renewalBasePrice * 1.4).round(), 'validity': '18 months'},
        ];

        await requestRef.update({
          'status': 'offers_sent',
          'adminResponse': {
            'offerOptions': offerOptions,
          },
        });

        _showStyledSnackbar(context, 'Request approved and offers sent.', isError: false);
      } else {
        await requestRef.update({
          'status': 'rejected',
          'adminResponse': {
            'offerOptions': [],
            'validityPeriod': null,
          },
        });
        _showStyledSnackbar(context, 'Request rejected.', isError: false);
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
      appBar: AppBar(
        title: Text(
          'Request Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
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

          final vehicleData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final model = vehicleData['model'] ?? 'Unknown';
          final registration = vehicleData['registrationNumber'] ?? 'Unknown';
          final chassis = vehicleData['chassisNumber'] ?? 'Unknown';
          final priceRaw = vehicleData['priceWhenNew'];
          final price = priceRaw is num
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw?.toString() ?? '') ?? 0.0;
          final manufacturingYear = int.tryParse(
                  vehicleData['manufacturingYear']?.toString() ?? '') ??
              0;
          final numPassengers = vehicleData['numPassengers']?.toString() ?? 'N/A';
          final driverAge = vehicleData['driverAge']?.toString() ?? 'N/A';
          final hasAccidentBefore =
              vehicleData['hasAccidentBefore'] == true ? 'Yes' : 'No';

          final userId = widget.requestData['userId'] ?? 'N/A';
          final status = widget.requestData['status'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
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
                              'Vehicle Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Model', model),
                            _buildInfoRow('Registration Number', registration),
                            _buildInfoRow('Chassis Number', chassis),
                            _buildInfoRow('Manufacturing Year', manufacturingYear.toString()),
                            _buildInfoRow('Number of Passengers', numPassengers),
                            _buildInfoRow('Driver Age', driverAge),
                            _buildInfoRow('Has Accident Before', hasAccidentBefore),
                            _buildInfoRow('Price When New', '${price.toStringAsFixed(2)} BHD'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                              'Request Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Request ID', widget.requestId),
                            _buildInfoRow('User ID', userId),
                            _buildInfoRow('Status', 
                              status, 
                              textColor: _getStatusColor(status),
                              isBold: true
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Approve',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _handleDecision(true, price, manufacturingYear),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Reject',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _handleDecision(false, price, manufacturingYear),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? textColor, bool isBold = false}) {
    
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
      case 'rejected':
        return Colors.red;
      case 'offer_selected':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }
}