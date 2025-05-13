// accident_report_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

class AccidentReportPage extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const AccidentReportPage({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  @override
  State<AccidentReportPage> createState() => _AccidentReportPageState();
}

class _AccidentReportPageState extends State<AccidentReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _damagedPartsController = TextEditingController();
  final _repairCostController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _accidentDate;
  bool _isLoading = false;
  double? _consumptionRate;
  double? _carValue;

  @override
  void initState() {
    super.initState();
    _carValue = double.tryParse(widget.vehicleData['priceWhenNew']?.toString() ?? '0');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _accidentDate) {
      setState(() {
        _accidentDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _calculateConsumptionRate() {
    if (_repairCostController.text.isEmpty || _carValue == null) return;
    
    final repairCost = double.tryParse(_repairCostController.text) ?? 0;
    final percentage = (repairCost / _carValue!) * 100;

    setState(() {
      _consumptionRate = percentage > 40 ? 15 : 10;
    });
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Calculate final values
        final repairCost = double.tryParse(_repairCostController.text) ?? 0;
        final percentage = (repairCost / _carValue!) * 100;
        final finalConsumptionRate = percentage > 40 ? 15 : 10;

        // Here you would typically save to Firestore
        /*
        await FirebaseFirestore.instance.collection('accident_reports').add({
          'vehicleId': widget.vehicleId,
          'accidentDate': _accidentDate,
          'damagedParts': _damagedPartsController.text,
          'repairCost': repairCost,
          'consumptionRate': finalConsumptionRate,
          'submittedAt': Timestamp.now(),
          'status': 'pending',
        });
        */

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accident report submitted successfully! Consumption rate: $finalConsumptionRate%'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
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
          "Accident Report",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Info Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Vehicle Information",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Model: ${widget.vehicleData['model'] ?? 'N/A'}",
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        "CRN: ${widget.vehicleData['registrationNumber'] ?? 'N/A'}",
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        "Current Value: ${_carValue?.toStringAsFixed(2) ?? 'N/A'} BH",
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Accident Date Field
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Accident Date*',
                  hintText: 'Select date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select accident date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Damaged Parts Field
              TextFormField(
                controller: _damagedPartsController,
                decoration: InputDecoration(
                  labelText: 'Damaged Parts*',
                  hintText: 'Describe the damaged parts',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe damaged parts';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Repair Cost Field
              TextFormField(
                controller: _repairCostController,
                decoration: InputDecoration(
                  labelText: 'Repair Cost (BH)*',
                  hintText: 'Enter estimated repair cost',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: 'BH',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateConsumptionRate(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter repair cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (_repairCostController.text.isNotEmpty && _carValue != null)
                Text(
                  'Repair cost is ${((double.tryParse(_repairCostController.text) ?? 0) / _carValue! * 100).toStringAsFixed(2)}% of car value',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),

              // Consumption Rate Indicator
              if (_consumptionRate != null)
                Card(
                  color: _consumptionRate! > 10 
                      ? Colors.orange[100]
                      : Colors.green[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _consumptionRate! > 10 
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle,
                          color: _consumptionRate! > 10 
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consumption Rate',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _consumptionRate! > 10
                                    ? '15% (High damage - exceeds 40% of car value)'
                                    : '10% (Normal damage)',
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          'Submit Report',
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

  @override
  void dispose() {
    _damagedPartsController.dispose();
    _repairCostController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}