// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _modelController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _yearController = TextEditingController();
  final _passengerCountController = TextEditingController();
  final _driverAgeController = TextEditingController();
  final _priceController = TextEditingController();

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _customerName = data['name'] ?? '';
          _customerNameController.text = _customerName;
          _loadingUser = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*'..multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      List<String> selectedImages = [];

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoadEnd.first;
        selectedImages.add(reader.result.toString());
      }

      setState(() => _images = selectedImages);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final List<String> imageUrls = [];

      for (var base64Image in _images) {
        final mimeTypeMatch = RegExp(r'data:(.*?);base64,').firstMatch(base64Image);
        final mimeType = mimeTypeMatch?.group(1) ?? 'application/octet-stream';

        if (!mimeType.startsWith('image/')) continue;

        final imageData = base64Decode(base64Image.split(',').last);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('vehicle_photos/$fileName');

        final metadata = SettableMetadata(contentType: mimeType);
        final uploadTask = ref.putData(Uint8List.fromList(imageData), metadata);

        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        imageUrls.add(url);
      }

      final manufacturingYear = int.tryParse(_yearController.text) ?? 0;
      final priceWhenNew = double.tryParse(_priceController.text) ?? 0.0;
      final age = DateTime.now().year - manufacturingYear;

      double estimatedPrice = priceWhenNew;
      for (int i = 0; i < age; i++) {
        estimatedPrice -= estimatedPrice * 0.1;
      }
      estimatedPrice = estimatedPrice < 0 ? 0 : estimatedPrice;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vehicleDoc = FirebaseFirestore.instance.collection('vehicles').doc();
        await vehicleDoc.set({
          'userId': user.uid,
          'customerName': _customerName,
          'model': _modelController.text,
          'chassisNumber': _chassisNumberController.text,
          'registrationNumber': _registrationNumberController.text,
          'manufacturingYear': manufacturingYear,
          'numPassengers': int.tryParse(_passengerCountController.text) ?? 0,
          'driverAge': int.tryParse(_driverAgeController.text) ?? 0,
          'priceWhenNew': priceWhenNew,
          'currentEstimatedPrice': estimatedPrice,
          'hasAccidentBefore': false,
          'photos': imageUrls,
          'isInsured': false,
        });
        Navigator.pop(context);
        _showStyledSnackbar(context, 'Vehicle information submitted successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      _showStyledSnackbar(context, 'Failed to add vehicle: $e', isError: true);
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
              if (_loadingUser) const CircularProgressIndicator(),
              if (!_loadingUser)
                _buildTextField(
                  controller: _customerNameController,
                  icon: Icons.person,
                  label: "Customer Name",
                  hint: "Auto-filled",
                  readOnly: true,
                  validator: (_) => null,
                  suffixIcon: const Icon(Icons.lock_outline),
                ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _modelController,
                icon: Icons.directions_car,
                label: "Car Model",
                hint: "e.g. Toyota Camry",
                validator: _requiredField,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _chassisNumberController,
                icon: Icons.confirmation_number,
                label: "Chassis Number",
                hint: "Enter chassis number",
                validator: _requiredField,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _registrationNumberController,
                icon: Icons.numbers,
                label: "Registration Number",
                hint: "Enter registration number",
                validator: _requiredField,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _yearController,
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
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passengerCountController,
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
              const SizedBox(height: 16),
              _buildTextField(
                controller: _driverAgeController,
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
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                icon: Icons.attach_money,
                label: "Car Price (when new)",
                hint: "e.g. 30000",
                validator: (value) {
                  if (double.tryParse(value ?? '') == null) {
                    return '*Enter valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: Text("Upload Vehicle Photos", style: GoogleFonts.poppins()),
              ),
              const SizedBox(height: 16),
              if (_images.isNotEmpty)
                Wrap(
                  spacing: 10,
                  children: _images.map((img) {
                    final bytes = base64Decode(img.split(',').last);
                    return Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover);
                  }).toList(),
                )
              else
                Text("No images selected", style: GoogleFonts.poppins()),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Add Vehicle", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
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
    required String? Function(String?) validator,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
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

  String? _requiredField(String? value) =>
      (value == null || value.isEmpty) ? '*Required' : null;
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

