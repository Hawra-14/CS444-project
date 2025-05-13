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

class _OfferSelectionDetailsPageState
    extends State<OfferSelectionDetailsPage> {
  bool _isProcessing = false;

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
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
        await requestRef.update({
          'status': 'awaiting_payment',
        });
        _showSnackbar('Offer approved and payment requested.');
      } else {
        await requestRef.update({
          'status': 'rejected',
        });
        _showSnackbar('Offer rejected.');
      }

      Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.requestData['selectedOffer'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Selected Offer Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE0E7FF),
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _sectionCard('Vehicle Info', [
                        _infoRow('Model', vehicle['model']),
                        _infoRow('Registration #', vehicle['registrationNumber']),
                        _infoRow('Chassis #', vehicle['chassisNumber']),
                        _infoRow('Manufacturing Year',
                            vehicle['manufacturingYear']?.toString()),
                        _infoRow('Price When New',
                            '${vehicle['priceWhenNew'] ?? 'N/A'} BHD'),
                        _infoRow('current Estimated Price',
                            '${vehicle['currentEstimatedPrice'] ?? 'N/A'} BHD'),    
                      ]),
                      _buildAvailableOffersSection(),
                      const SizedBox(height: 12),
                      _sectionCard('Customer Selection', [
                        _infoRow('Selected Price', '${offer['price'] ?? 'N/A'} BHD'),
                        _infoRow('Validity', offer['validity']),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleApproval(true),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleApproval(false),
                              icon: const Icon(Icons.close, color: Colors.white),
                              label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold ),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
  Widget _buildAvailableOffersSection() {
  final offers = (widget.requestData['adminResponse']?['offerOptions'] as List?) ?? [];

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
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Price', '${offer['price']} BHD'),
              _infoRow('Validity', offer['validity'] ?? 'N/A'),
            ],
          ),
        ),
      );
    }).toList(),
  ]);
}

}
