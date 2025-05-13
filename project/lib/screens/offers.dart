import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OfferSelectionPage extends StatefulWidget {
  final String vehicleId;

  const OfferSelectionPage({super.key, required this.vehicleId});

  @override
  State<OfferSelectionPage> createState() => _OfferSelectionPageState();
}

class _OfferSelectionPageState extends State<OfferSelectionPage> {
  List<Map<String, dynamic>> offers = [];
  int? selectedIndex;
  bool isLoading = true;
  String? requestDocId;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInsuranceRequest();
  }

  Future<void> _fetchInsuranceRequest() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('insurance_requests')
        .where('vehicleId', isEqualTo: widget.vehicleId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();

      requestDocId = doc.id;

      final List<dynamic>? options = data['adminResponse']?['offerOptions'];
      if (options != null) {
        offers = options.whereType<Map<String, dynamic>>().toList();
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _submitSelectedOffer() async {
    if (selectedIndex == null || requestDocId == null) {
      _showSnackbar('Please select an offer');
      return;
    }

    final originalOffer = offers[selectedIndex!];
    final originalPrice = originalOffer['price'] as num;
    final adjustedPrice = num.tryParse(_priceController.text);

    if (adjustedPrice == null) {
      _showSnackbar('Invalid price entered');
      return;
    }

    final minAllowed = originalPrice * 0.95;
    final maxAllowed = originalPrice * 1.05;

    if (adjustedPrice < minAllowed || adjustedPrice > maxAllowed) {
      _showSnackbar('Price must be within ±5% of $originalPrice BD');
      return;
    }

    final selectedOffer = {
      ...originalOffer,
      'price': adjustedPrice.round(),
    };

    await FirebaseFirestore.instance
        .collection('insurance_requests')
        .doc(requestDocId)
        .update({
      'selectedOffer': selectedOffer,
      'status': 'offerSelected',
    });

    _showSnackbar('Offer submitted successfully', isError: false);
    Navigator.pop(context);
  }

  void _showSnackbar(String message, {bool isError = true}) {
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
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
        elevation: 6,
        shadowColor: Colors.black38,
        centerTitle: true,
        toolbarHeight: 70,
        title: Text(
          "Insurance Offers",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : offers.isEmpty
              ? Center(
                  child: Text(
                    'No offers available.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Offers:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            final isSelected = index == selectedIndex;

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: isSelected
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                title: Text(
                                  '${offer['price']} BD',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  'Validity: ${offer['validity']}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade700),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                    _priceController.text =
                                        offer['price'].toString();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      if (selectedIndex != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Adjust Price (±5%)',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter new price',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitSelectedOffer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Submit Offer",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
