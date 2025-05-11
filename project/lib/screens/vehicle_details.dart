import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsPage extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailsPage({super.key, required this.vehicleId});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  late Map<String, dynamic> vehicleData;

  final Map<String, TextEditingController> _controllers = {
    'model': TextEditingController(),
    'registrationNumber': TextEditingController(),
    'chassisNumber': TextEditingController(),
    'manufacturingYear': TextEditingController(),
    'numPassengers': TextEditingController(),
    'driverAge': TextEditingController(),
    'priceWhenNew': TextEditingController(),
    'image': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _fetchVehicleDetails();
  }

  Future<void> _fetchVehicleDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.vehicleId)
        .get();

    if (doc.exists) {
      vehicleData = doc.data()!;
      _controllers.forEach((key, controller) {
        controller.text = vehicleData[key]?.toString() ?? '';
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        for (var key in _controllers.keys) key: _controllers[key]!.text,
      };

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vehicle details updated successfully")),
      );
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE0E7FF),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('model', 'Model'),
              _buildTextField('registrationNumber', 'Registration Number'),
              _buildTextField('chassisNumber', 'Chassis Number'),
              _buildTextField('manufacturingYear', 'Manufacturing Year'),
              _buildTextField('numPassengers', 'Number of Passengers'),
              _buildTextField('driverAge', 'Driver Age'),
              _buildTextField('priceWhenNew', 'Car Price When New (BD)'),
              _buildTextField('image', 'Image URL'),
              const SizedBox(height: 12),
              Image.network(
                _controllers['image']!.text,
                height: 160,
                errorBuilder: (_, __, ___) => const Text('Invalid image URL'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white),),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Vehicle'),
                        content: const Text('Are you sure you want to delete this vehicle?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes, Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 231, 87, 76),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(widget.vehicleId)
                          .delete();
                
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vehicle deleted.')),
                      );
                
                      Navigator.pop(context); // Go back to the previous screen
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 231, 87, 76),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Delete Vehicle', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        )
      ),
    );
  }
}
