import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
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
          'status': 'approved',
          'adminResponse': {
            'offerOptions': offerOptions,
            'validityPeriod': 'User must select one option',
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
      appBar: AppBar(title: const Text('Request Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .get(),
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
                      Text('Vehicle Information',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text('Model: $model'),
                      Text('Registration Number: $registration'),
                      Text('Chassis Number: $chassis'),
                      Text('Manufacturing Year: $manufacturingYear'),
                      Text('Number of Passengers: $numPassengers'),
                      Text('Driver Age: $driverAge'),
                      Text('Has Accident Before: $hasAccidentBefore'),
                      Text('Price When New: ${price.toStringAsFixed(2)} BH'),
                      const Divider(height: 30),
                      Text('Request Information',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text('Request ID: ${widget.requestId}'),
                      Text('User ID: $userId'),
                      Text('Status: $status'),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: _isProcessing
                          ? null
                          : () => _handleDecision(true, price, manufacturingYear),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      onPressed: _isProcessing
                          ? null
                          : () => _handleDecision(false, price, manufacturingYear),
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
}