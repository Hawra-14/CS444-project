import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ... [Keep all imports]

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
    'currentEstimatedPrice': TextEditingController(),
  };

  late double originalCurrentEstimatedPrice;

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

      originalCurrentEstimatedPrice =
          double.tryParse(vehicleData['currentEstimatedPrice'].toString()) ??
              0.0;
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

      _showStyledSnackbar(context, 'Vehicle details updated successfully!',
          isError: false);
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Widget _verticalSpace([double height = 16]) => SizedBox(height: height);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
        elevation: 6,
        shadowColor: Colors.black38,
        centerTitle: true,
        toolbarHeight: 70,
        title: Text(
          "Vehicle Details",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _controllers['model']!,
                icon: Icons.directions_car,
                label: "Car Model",
                hint: "e.g. Toyota Camry",
                validator: _requiredValidator("Car model"),
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['chassisNumber']!,
                icon: Icons.confirmation_number,
                label: "Chassis Number",
                hint: "Enter chassis number",
                validator: _requiredValidator("Chassis number"),
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['registrationNumber']!,
                icon: Icons.numbers,
                label: "Registration Number",
                hint: "Enter registration number",
                validator: _requiredValidator("Registration number"),
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['manufacturingYear']!,
                icon: Icons.calendar_today,
                label: "Manufacturing Year",
                hint: "e.g. 2022",
                validator: (value) {
                  if (value == null || value.isEmpty) return '*Required';
                  final year = int.tryParse(value);
                  if (year == null || year > DateTime.now().year) {
                    return '*Invalid year';
                  }
                  return null;
                },
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['numPassengers']!,
                icon: Icons.event_seat,
                label: "Number of Passengers",
                hint: "e.g. 5",
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  if (count == null || count < 1 || count > 100) {
                    return '*Enter valid number (1–100)';
                  }
                  return null;
                },
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['driverAge']!,
                icon: Icons.person_outline,
                label: "Driver Age",
                hint: "e.g. 35",
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 18 || age > 100) {
                    return '*Enter valid age (18–100)';
                  }
                  return null;
                },
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['priceWhenNew']!,
                icon: Icons.attach_money,
                label: "Car Price (When New)",
                hint: "e.g. 30000",
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return '*Car price is required';
                  if (double.tryParse(value) == null) return '*Invalid price';
                  return null;
                },
              ),
              _verticalSpace(),
              _buildTextField(
                controller: _controllers['currentEstimatedPrice']!,
                icon: Icons.attach_money,
                label: "Current Estimated Price",
                hint: "e.g. 25000",
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return '*Estimated price is required';
                  final newPrice = double.tryParse(value);
                  if (newPrice == null) return '*Invalid price';
                  final lowerLimit = originalCurrentEstimatedPrice * 0.9;
                  final upperLimit = originalCurrentEstimatedPrice * 1.1;
                  if (newPrice < lowerLimit || newPrice > upperLimit) {
                    return '*Price must be within ±10% of \$${originalCurrentEstimatedPrice.toStringAsFixed(2)}';
                  }
                  return null;
                },
              ),
              _verticalSpace(24),
              _buildButton(
                label: "Save Changes",
                color: const Color(0xFF6366F1),
                onPressed: _saveChanges,
              ),
              _verticalSpace(10),
              _buildButton(
                label: "Delete Vehicle",
                color: const Color.fromARGB(255, 231, 87, 76),
                onPressed: _confirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[800]),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildButton(
      {required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  String? Function(String?) _requiredValidator(String fieldName) {
    return (value) =>
        value == null || value.isEmpty ? '*$fieldName is required' : null;
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

  Future<void> _confirmDelete() async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 231, 87, 76),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final vehicleRef = FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId);
        batch.delete(vehicleRef);

        Future<void> deleteRelated(String collection) async {
          final snapshot = await FirebaseFirestore.instance
              .collection(collection)
              .where('vehicleId', isEqualTo: widget.vehicleId)
              .get();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
        }

        await Future.wait([
          deleteRelated('insurance_policies'),
          deleteRelated('accidents'),
          deleteRelated('insurance_requests'),
        ]);

        await batch.commit();

        _showStyledSnackbar(
            context, 'Vehicle and related records deleted successfully!',
            isError: false);
        Navigator.pop(context);
      } catch (e) {
        _showStyledSnackbar(context, 'Error deleting vehicle: $e', isError: true);
      }
    }
  }
}
