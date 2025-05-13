import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AccidentReportScreen extends StatefulWidget {
  const AccidentReportScreen({Key? key}) : super(key: key);

  @override
  _AccidentReportScreenState createState() => _AccidentReportScreenState();
}

class _AccidentReportScreenState extends State<AccidentReportScreen> {
  final _accidentDateController = TextEditingController();
  final _damagedPartsController = TextEditingController();
  final _repairCostController = TextEditingController();

  String _accidentDate = '';
  String _damagedParts = '';
  double _repairCost = 0.0;
  String? _selectedVehicleId; // Store selected vehicle ID
  List<Map<String, dynamic>> _insuredVehicles = []; // Store list of insured vehicles

  @override
  void initState() {
    super.initState();
    _fetchInsuredVehicles();
  }

  // Fetch insured vehicles from Firestore
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit Accident Report',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for selecting insured vehicle
            DropdownButton<String>(
              hint: Text("Select Insured Vehicle"),
              value: _selectedVehicleId,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedVehicleId = newValue;
                });
              },
              items: _insuredVehicles.map((vehicle) {
                return DropdownMenuItem<String>(
                  value: vehicle['id'],
                  child: Text('${vehicle['model']} - ${vehicle['registrationNumber']}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Accident Date TextField
            TextField(
              controller: _accidentDateController,
              decoration: const InputDecoration(
                labelText: 'Accident Date',
                hintText: 'Enter the date of the accident',
              ),
              onChanged: (value) {
                setState(() {
                  _accidentDate = value;
                });
              },
            ),
            const SizedBox(height: 10),

            // Damaged Parts TextField
            TextField(
              controller: _damagedPartsController,
              decoration: const InputDecoration(
                labelText: 'Damaged Parts',
                hintText: 'Enter the parts that were damaged',
              ),
              onChanged: (value) {
                setState(() {
                  _damagedParts = value;
                });
              },
            ),
            const SizedBox(height: 10),

            // Repair Cost TextField
            TextField(
              controller: _repairCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost of Repair',
                hintText: 'Enter the cost of repair',
              ),
              onChanged: (value) {
                setState(() {
                  _repairCost = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _submitAccidentReport,
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  // Submit the accident report
  Future<void> _submitAccidentReport() async {
    if (_selectedVehicleId == null) {
      _showStyledSnackbar(context, 'Please select a vehicle first', isError: true);
      return;
    }

    // Fetch the selected vehicle data
    final vehicleDoc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(_selectedVehicleId)
        .get();

    if (vehicleDoc.exists) {
      final carValue = vehicleDoc['currentEstimatedPrice'];
      final escalatedConsumptionRate = _repairCost > carValue * 0.4 ? 0.15 : 0.10;

      try {
        // Add the accident report to Firestore
        final accidentReportRef = FirebaseFirestore.instance.collection('accidents').doc();

        final accidentData = {
          'vehicleId': _selectedVehicleId,
          'accidentDate': _accidentDate,
          'damagedParts': _damagedParts,
          'repairCost': _repairCost,
          'escalatedConsumptionRate': escalatedConsumptionRate,
          'submittedAt': Timestamp.now(),
        };

        await accidentReportRef.set(accidentData);

        await FirebaseFirestore.instance.collection('vehicles').doc(_selectedVehicleId).update({
          'hasAccidentBefore': true,
        });

        // Show confirmation snackbar
        _showStyledSnackbar(context, 'Accident report submitted successfully!', isError: false);
        Navigator.pop(context);
      } catch (e) {
        _showStyledSnackbar(context, 'Error submitting accident report: $e', isError: true);
      }
    } else {
      _showStyledSnackbar(context, 'Vehicle not found!', isError: true);
    }
  }

  // Display styled snackbar
  void _showStyledSnackbar(BuildContext context, String message, {bool isError = true}) {
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
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        showCloseIcon: true,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
