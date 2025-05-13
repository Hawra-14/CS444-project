import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date formatting

class AccidentReportScreen extends StatefulWidget {
  const AccidentReportScreen({super.key});

  @override
  _AccidentReportScreenState createState() => _AccidentReportScreenState();
}

class _AccidentReportScreenState extends State<AccidentReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _accidentDateController = TextEditingController();
  final _damagedPartsController = TextEditingController();
  final _repairCostController = TextEditingController();

  String? _selectedVehicleId;
  List<Map<String, dynamic>> _insuredVehicles = [];
  DateTime? _selectedAccidentDate; // Store the selected date

  @override
  void initState() {
    super.initState();
    _fetchInsuredVehicles();
  }

  Future<void> _fetchInsuredVehicles() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final vehicleDocs = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .where('isInsured', isEqualTo: true)
        .get();

    setState(() {
      _insuredVehicles = vehicleDocs.docs
          .map((doc) => {
                'id': doc.id,
                'model': doc['model'],
                'registrationNumber': doc['registrationNumber'],
                'currentEstimatedPrice': doc['currentEstimatedPrice'],
              })
          .toList();
    });
  }

  @override
  void dispose() {
    _accidentDateController.dispose();
    _damagedPartsController.dispose();
    _repairCostController.dispose();
    super.dispose();
  }

  // Function to show date picker
  Future<void> _pickAccidentDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedAccidentDate) {
      setState(() {
        _selectedAccidentDate = pickedDate;
        _accidentDateController.text =
            DateFormat.yMMMMd().format(pickedDate); // Format selected date
      });
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
          "Submit Accident Report",
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
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                decoration: _inputDecoration(
                    label: 'Select Insured Vehicle',
                    icon: Icons.directions_car),
                onChanged: (String? newValue) {
                  setState(() => _selectedVehicleId = newValue);
                },
                items: _insuredVehicles.map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle['id'],
                    child: Text(
                        '${vehicle['model']} - ${vehicle['registrationNumber']}'),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? '*Please select a vehicle' : null,
              ),
              const SizedBox(height: 16),

              // Date Picker for Accident Date
              GestureDetector(
                onTap: _pickAccidentDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _accidentDateController,
                    decoration: _inputDecoration(
                      label: 'Accident Date',
                      hint: 'Select accident date',
                      icon: Icons.calendar_today,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? '*Accident date is required'
                        : null,
                    readOnly:
                        true, // Makes the field read-only since it will be filled using the date picker
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _damagedPartsController,
                icon: Icons.build,
                label: 'Damaged Parts',
                hint: 'Enter damaged parts',
                validator: (value) => value == null || value.isEmpty
                    ? '*Damaged parts required'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _repairCostController,
                icon: Icons.attach_money,
                label: 'Repair Cost',
                hint: 'e.g. 2500',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final cost = double.tryParse(value ?? '');
                  if (value == null || value.isEmpty)
                    return '*Repair cost required';
                  if (cost == null || cost <= 0) return '*Invalid repair cost';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAccidentReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Submit Report',
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
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
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
    );
  }

  Future<void> _submitAccidentReport() async {
    if (!_formKey.currentState!.validate()) return;

    final double repairCost =
        double.tryParse(_repairCostController.text) ?? 0.0;

    final vehicleDoc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(_selectedVehicleId)
        .get();

    if (!vehicleDoc.exists) {
      _showStyledSnackbar(context, 'Vehicle not found!', isError: true);
      return;
    }

    final carValue = vehicleDoc['currentEstimatedPrice'];
    final escalatedConsumptionRate = repairCost > carValue * 0.4 ? 0.15 : 0.10;

    try {
      await FirebaseFirestore.instance.collection('accidents').add({
        'vehicleId': _selectedVehicleId,
        'accidentDate':
            _selectedAccidentDate ?? DateTime.now(), // Store the selected date
        'damagedParts': _damagedPartsController.text,
        'repairCost': repairCost,
        'escalatedConsumptionRate': escalatedConsumptionRate,
        'submittedAt': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(_selectedVehicleId)
          .update({'hasAccidentBefore': true});

      _showStyledSnackbar(context, 'Accident report submitted successfully!',
          isError: false);
      Navigator.pop(context);
    } catch (e) {
      _showStyledSnackbar(context, 'Error submitting report: $e', isError: true);
    }
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
}
