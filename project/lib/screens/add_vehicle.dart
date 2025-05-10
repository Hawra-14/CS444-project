// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _chassisNumberController =
      TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _passengerCountController =
      TextEditingController();
  final TextEditingController _driverAgeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<String> _images = [];
  bool _loadingUser = true;
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
  }

  Future<void> _loadCustomerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _customerName = '${data['name']}';
          _customerNameController.text = _customerName;
          _loadingUser = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      List<String> pickedImagesBase64 = [];

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoadEnd.first;
        pickedImagesBase64.add(reader.result.toString());
      }

      setState(() {
        _images = pickedImagesBase64;
      });
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        // 1. Upload photos to Firebase Storage and get the URLs
        List<String> imageUrls = [];
        for (var base64Image in _images) {
          // Extract MIME type from base64 prefix
          final mimeTypeMatch =
              RegExp(r'data:(.*?);base64,').firstMatch(base64Image);
          final mimeType = mimeTypeMatch != null
              ? mimeTypeMatch.group(1)
              : 'application/octet-stream';
          if (!mimeType!.startsWith('image/')) {
            // Skip or show error
            continue;
          }
          // Extract actual base64 content
          final imageData = base64Decode(base64Image.split(',').last);
          final fileName = DateTime.now().millisecondsSinceEpoch.toString();

          final storageRef =
              FirebaseStorage.instance.ref().child('vehicle_photos/$fileName');

          // Add MIME type to metadata
          final metadata = SettableMetadata(contentType: mimeType);

          final uploadTask =
              storageRef.putData(Uint8List.fromList(imageData), metadata);
          final taskSnapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await taskSnapshot.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        }
        // 2. Calculate the current estimated price
        final manufacturingYear = int.tryParse(_yearController.text) ?? 0;
        final priceWhenNew = double.tryParse(_priceController.text) ?? 0.0;

        int vehicleAge = DateTime.now().year - manufacturingYear;
        double depreciationFactor = 0.1;

        double currentEstimatedPrice = priceWhenNew;
        for (int i = 0; i < vehicleAge; i++) {
          currentEstimatedPrice -= currentEstimatedPrice * depreciationFactor;
        }
        if (currentEstimatedPrice < 0) {
          currentEstimatedPrice = 0;
        }
        // 3. Save vehicle information to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final vehicleRef =
              FirebaseFirestore.instance.collection('vehicles').doc();
          await vehicleRef.set({
            'userId': user.uid,
            'customerName': _customerNameController.text,
            'model': _modelController.text,
            'chassisNumber': _chassisNumberController.text,
            'registrationNumber': _registrationNumberController.text,
            'manufacturingYear': int.tryParse(_yearController.text) ?? 0,
            'numPassengers': int.tryParse(_passengerCountController.text) ?? 0,
            'driverAge': int.tryParse(_driverAgeController.text) ?? 0,
            'priceWhenNew': double.tryParse(_priceController.text) ?? 0.0,
            'hasAccidentBefore': false,
            'photos': imageUrls,
            'isInsured': false,
          });
          Navigator.pop(context);
          _showStyledSnackbar(
              context, 'Vehicle information submitted successfully!',
              isError: false);
          Navigator.pop(context);
        }
      } catch (e) {
        Navigator.pop(context);
        _showStyledSnackbar(context, 'Failed to add vehicle: $e',
            isError: true);
      }
    }
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
          "Add Vehicle",
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
              _loadingUser
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTextField(
                      controller: _customerNameController,
                      icon: Icons.person,
                      label: "Customer Name",
                      hint: "Auto-filled",
                      validator: (_) => null,
                      readOnly: true,
                      suffixIcon: const Icon(Icons.lock_outline),
                    ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _modelController,
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
                controller: _chassisNumberController,
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
                controller: _registrationNumberController,
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
                controller: _yearController,
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
                controller: _passengerCountController,
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
                controller: _driverAgeController,
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
                controller: _priceController,
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
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label:
                    Text("Upload Vehicle Photos", style: GoogleFonts.poppins()),
              ),
              const SizedBox(height: 16),
              _images.isNotEmpty
                  ? Wrap(
                      spacing: 10,
                      children: _images.map((base64Data) {
                        return kIsWeb
                            ? Image.memory(
                                Uint8List.fromList(
                                    base64Decode(base64Data.split(',').last)),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container();
                      }).toList(),
                    )
                  : const Text("No images selected"),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Add Vehicle",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
