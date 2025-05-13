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
    'currentEstimatedPrice': TextEditingController(),
    'image': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _fetchVehicleDetails();
  }

  late double originalCurrentEstimatedPrice;

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

      // Save the original currentEstimatedPrice as double
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

      _showStyledSnackbar(context, 'Vehicle details updated successfully!', isError: false);
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
              _buildTextField(
                controller: _controllers['model']!,
                icon: Icons.directions_car,
                label: "Car Model",
                hint: "e.g. Toyota Camry",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Car model is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _controllers['chassisNumber']!,
                icon: Icons.confirmation_number,
                label: "Chassis Number",
                hint: "Enter chassis number",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Chassis number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _controllers['registrationNumber']!,
                icon: Icons.numbers,
                label: "Registration Number",
                hint: "Enter registration number",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Registration number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _controllers['manufacturingYear']!,
                icon: Icons.calendar_today,
                label: "Manufacturing Year",
                hint: "e.g. 2022",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Manufacturing year is required';
                  } else if (int.tryParse(value) == null) {
                    return '*Invalid manufacturing year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _controllers['numPassengers']!,
                icon: Icons.event_seat,
                label: "Number of Passengers",
                hint: "e.g. 5",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Number of Passengers is required';
                  } else if (int.tryParse(value) == null) {
                    return '*Invalid number of Passengers';
                  } else if (int.tryParse(value) != null) {
                    if (int.tryParse(value)! > 100) {
                      return '*Number of passengers should not be more than 10';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _controllers['driverAge']!,
                icon: Icons.person_outline,
                label: "Driver Age",
                hint: "e.g. 35",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Driver age is required';
                  } else if (int.tryParse(value) == null) {
                    return '*Invalid driver age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _controllers['priceWhenNew']!,
                icon: Icons.attach_money,
                label: "Car Price (when new)",
                hint: "e.g. 30000",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '*Car Price is required';
                  } else if (double.tryParse(value) == null) {
                    return '*Invalid car price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _controllers['currentEstimatedPrice']!,
                  icon: Icons.attach_money,
                  label: "Current Estimated Price",
                  hint: "e.g. 30000",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '*Current Estimated Price is required';
                    }

                    final newPrice = double.tryParse(value);
                    if (newPrice == null) {
                      return '*Invalid car price';
                    }

                    final lowerLimit = originalCurrentEstimatedPrice * 0.9;
                    final upperLimit = originalCurrentEstimatedPrice * 1.1;

                    if (newPrice < lowerLimit || newPrice > upperLimit) {
                      return '*New price must be within ±10% of the original estimated price (\$${originalCurrentEstimatedPrice.toStringAsFixed(2)})';
                    }

                    return null;
                  }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
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
                        content: const Text(
                            'Are you sure you want to delete this vehicle?'),
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

                      _showStyledSnackbar(context, 'Vehicle deleted successfully!', isError: false);
      
                      Navigator.pop(context); // Go back to the previous screen
                    }

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 231, 87, 76),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Delete Vehicle',
                      style: TextStyle(color: Colors.white)),
                ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    bool readOnly = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        suffixIcon: suffixIcon,
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

}
