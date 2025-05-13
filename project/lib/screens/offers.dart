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
  double? adjustedPrice;

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
      requestDocId = doc.id;

      final List<dynamic>? options =
          doc.data()['adminResponse']?['offerOptions'];
      if (options != null) {
        offers = options.whereType<Map<String, dynamic>>().toList();
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _submitSelectedOffer() async {
    if (selectedIndex == null ||
        requestDocId == null ||
        adjustedPrice == null) {
      _showStyledSnackbar(context, 'Please select and adjust an offer', isError: true);
      return;
    }

    final selectedOffer = {
      ...offers[selectedIndex!],
      'price': adjustedPrice!.round(),
    };

    await FirebaseFirestore.instance
        .collection('insurance_requests')
        .doc(requestDocId)
        .update({
      'selectedOffer': selectedOffer,
      'status': 'offer_selected',
    });

    _showStyledSnackbar(context, 'Offer submitted successfully', isError: false);
    Navigator.pop(context);
  }

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
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: isSelected
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                title: Text(
                                  '${offer['price']} BD',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Validity: ${offer['validity']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                    adjustedPrice =
                                        (offer['price'] as num).toDouble();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (selectedIndex != null)
                        Builder(builder: (context) {
                          final original =
                              offers[selectedIndex!]['price'] as num;
                          final double min = (original * 0.95).floorToDouble();
                          final double max = (original * 1.05).ceilToDouble();
                          adjustedPrice ??= original.toDouble();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adjust Price (±5%)',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Min: ${min.toStringAsFixed(0)} BD',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[700])),
                                  Text('Max: ${max.toStringAsFixed(0)} BD',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[700])),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  activeTrackColor: Colors.indigo,
                                  inactiveTrackColor: Colors.indigo.shade100,
                                  thumbColor: Colors.indigo,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 10),
                                  overlayColor: Colors.indigo.withOpacity(0.2),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 20),
                                  valueIndicatorColor: Colors.indigo,
                                ),
                                child: Slider(
                                  value: adjustedPrice!.clamp(min, max),
                                  min: min,
                                  max: max,
                                  divisions: (max - min).toInt(),
                                  label:
                                      '${adjustedPrice!.toStringAsFixed(0)} BD',
                                  onChanged: (value) {
                                    setState(() => adjustedPrice = value);
                                  },
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Selected: ${adjustedPrice!.toStringAsFixed(0)} BD',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      const SizedBox(height: 24),
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
