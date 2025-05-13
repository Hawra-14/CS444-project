import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectedOfferPage extends StatelessWidget {
  final String requestId;
  final String vehicleId;
  final Map<String, dynamic> requestData;

  const SelectedOfferPage({
    super.key,
    required this.requestId,
    required this.vehicleId,
    required this.requestData,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOffer = requestData['selectedOffer'] ?? {};
    final double selectedPrice = (selectedOffer['price'] ?? 0).toDouble();
    final String validity = selectedOffer['validity'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Completed Request')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final vehicleData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final model = vehicleData['model'] ?? 'Unknown';
          final priceRaw = vehicleData['priceWhenNew'];
          final priceWhenNew = priceRaw is num ? priceRaw.toDouble() : 0.0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vehicle: $model", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text("Original Price: ${priceWhenNew.toStringAsFixed(2)} BH"),
                const SizedBox(height: 20),
                Text("Selected Offer", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text("Price: ${selectedPrice.toStringAsFixed(2)} BH"),
                Text("Validity: $validity"),
              ],
            ),
          );
        },
      ),
    );
  }
}
