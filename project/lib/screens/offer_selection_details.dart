import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class OfferSelectionDetailsPage extends StatefulWidget {
  final String requestId;
  final String vehicleId;
  final Map<String, dynamic> requestData;

  const OfferSelectionDetailsPage({
    super.key,
    required this.requestId,
    required this.vehicleId,
    required this.requestData,
  });

  @override
  State<OfferSelectionDetailsPage> createState() =>
      _OfferSelectionDetailsPageState();
}

class _OfferSelectionDetailsPageState extends State<OfferSelectionDetailsPage> {
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

  Future<void> _handleApproval(bool approve) async {
    setState(() => _isProcessing = true);
    final requestRef = FirebaseFirestore.instance
        .collection('insurance_requests')
        .doc(widget.requestId);

    try {
      if (approve) {
        await requestRef.update({'status': 'awaiting_payment'});
        _showStyledSnackbar(context, 'Offer approved and payment requested.');
      } else {
        await requestRef.update({'status': 'rejected'});
        _showStyledSnackbar(context, 'Offer rejected.');
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
    final offer = widget.requestData['selectedOffer'] ?? {};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
        elevation: 6,
        shadowColor: Colors.black38,
        centerTitle: true,
        toolbarHeight: 70,
        title: Text(
          "selected Offer Details",
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _sectionCard('Vehicle Information', [
                        _infoRow('Model', vehicle['model']),
                        _infoRow('Registration Number',
                            vehicle['registrationNumber']),
                        _infoRow('Chassis Number', vehicle['chassisNumber']),
                        _infoRow('Manufacturing Year',
                            vehicle['manufacturingYear']?.toString()),
                        _infoRow('Price When New',
                            '${vehicle['priceWhenNew'] ?? 'N/A'} BHD'),
                        _infoRow('Estimated Price',
                            '${vehicle['currentEstimatedPrice'] ?? 'N/A'} BHD'),
                      ]),
                      const SizedBox(height: 16),
                      _buildAvailableOffersSection(),
                      const SizedBox(height: 16),
                      _sectionCard('Customer Selection', [
                        _infoRow(
                            'Selected Price', '${offer['price'] ?? 'N/A'} BHD'),
                        _infoRow('Validity', offer['validity']),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isProcessing ? null : () => _handleApproval(true),
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
                                    fontWeight: FontWeight.w600),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isProcessing ? null : () => _handleApproval(false),
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
                                    fontWeight: FontWeight.w600),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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

  Widget _buildAvailableOffersSection() {
    final offers =
        (widget.requestData['adminResponse']?['offerOptions'] as List?) ?? [];

    if (offers.isEmpty) {
      return _sectionCard('Offers Sent to the Customer', [
        Text(
          'No offers submitted yet.',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      ]);
    }

    return _sectionCard('Offers Sent to the Customer', [
      ...offers.map((offer) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Price', '${offer['price']} BHD'),
              _infoRow('Validity', offer['validity']),
            ],
          ),
        );
      }).toList(),
    ]);
  }
}
