// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/screens/add_vehicle.dart';
import 'package:project/screens/insurance_Report.dart';
import 'package:project/screens/offers.dart';
import 'package:project/screens/vehicle_details.dart';
import 'package:project/screens/accident_Report.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          "My Vehicles",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      drawer: Drawer(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userName = userData['name'];

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E7FF),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Color(0xFF4F46E5),
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  accountName: Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  accountEmail: Text(
                    FirebaseAuth.instance.currentUser!.email ?? '',
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Insurance Report'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const InsurancePolicyReportPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.car_crash),
                  title: const Text('Accident Report'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccidentReportScreen(
                            // vehicleId: 'exampleVehicleId',
                            // vehicleData: {},
                            ),
                      ),
                    );
                  },
                ),
                const Divider(),
              ],
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a vehicle ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(
                    'No registered vehicles',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ));
                }

                final filteredVehicles = snapshot.data!.docs.where((doc) {
                  final registrationNumber =
                      doc['registrationNumber'].toString().toLowerCase();
                  final model = doc['model'].toString().toLowerCase();
                  final chassisNumber =
                      doc['chassisNumber'].toString().toLowerCase();
                  final year =
                      doc['manufacturingYear'].toString().toLowerCase();
                  final passengers =
                      doc['numPassengers'].toString().toLowerCase();

                  return registrationNumber.contains(_searchQuery) ||
                      model.contains(_searchQuery) ||
                      chassisNumber.contains(_searchQuery) ||
                      year.contains(_searchQuery) ||
                      passengers.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = filteredVehicles[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VehicleDetailsPage(vehicleId: vehicle.id),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey.shade200,
                            child: const Icon(Icons.directions_car,
                                size: 28, color: Colors.white),
                          ),
                          title: Text(
                            vehicle['model'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reg#: ${vehicle['registrationNumber']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                'chassis#: ${vehicle['chassisNumber']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                'Year: ${vehicle['manufacturingYear']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                'Passengers: ${vehicle['numPassengers']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          trailing: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('insurance_requests')
                                .where('vehicleId', isEqualTo: vehicle.id)
                                .limit(1)
                                .snapshots(),
                            builder: (context, insuranceSnapshot) {
                              if (insuranceSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              String buttonText;
                              Color backgroundColor;
                              Color textColor;
                              bool isButtonDisabled = false;
                              String? status;

                              if (insuranceSnapshot.hasData &&
                                  insuranceSnapshot.data!.docs.isNotEmpty) {
                                final request =
                                    insuranceSnapshot.data!.docs.first;
                                status = request['status'];
                                if (status == 'approved') {
                                  buttonText = 'Insured';
                                  backgroundColor = Colors.green.shade100;
                                  textColor = Colors.green.shade700;
                                  isButtonDisabled = false;
                                } else {
                                  if (status!.contains('_')) {
                                    var parts = status.split('_');
                                    parts[0] = parts[0][0].toUpperCase() +
                                        parts[0].substring(1);
                                    parts[1] = parts[1][0].toUpperCase() +
                                        parts[1].substring(1);
                                    buttonText = parts.join(' ');
                                  } else {
                                    buttonText = status[0].toUpperCase() +
                                        status.substring(1);
                                  }
                                  if (status == 'offer_selected' ||
                                      status == 'approved' ||
                                      status == 'payment_done' ||
                                      status == 'pending') {
                                    isButtonDisabled = true;
                                  }
                                  if (status != 'rejected') {
                                    backgroundColor = Colors.blue.shade100;
                                    textColor = Colors.blue.shade700;
                                  } else {
                                    backgroundColor = Colors.red.shade100;
                                    textColor = Colors.red.shade700;
                                    isButtonDisabled = false;
                                  }
                                }
                              } else {
                                buttonText = 'Not Insured';
                                backgroundColor = Colors.red.shade100;
                                textColor = Colors.red.shade700;
                                isButtonDisabled = false;
                              }

                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextButton(
                                  onPressed: isButtonDisabled
                                      ? null
                                      : () {
                                          if (status == 'offers_sent' ||
                                              status == 'rejected') {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        OfferSelectionPage(
                                                            vehicleId:
                                                                vehicle.id)));
                                          } else if (status ==
                                              'awaiting_payment') {
                                            final requestDoc = insuranceSnapshot
                                                .data!.docs.first;
                                            final requestId = requestDoc.id;

                                            FirebaseFirestore.instance
                                                .collection(
                                                    'insurance_requests')
                                                .doc(requestId)
                                                .update({
                                              'status': 'payment_done'
                                            }).then((_) {
                                              _showStyledSnackbar(context,
                                                  'Payment confirmed successfully!',
                                                  isError: false);
                                              setState(() {});
                                            }).catchError((error) {
                                              _showStyledSnackbar(context,
                                                  'Failed to update payment: $error',
                                                  isError: true);
                                            });
                                          } else {
                                            _showInsuranceDialog(
                                                context, vehicle.id);
                                          }
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    buttonText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VehicleFormScreen()),
          );
        },
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInsuranceDialog(BuildContext context, String vehicleId) async {
    bool hasAccident = false;

    // Fetch vehicle insurance status beforehand
    final vehicleSnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .get();

    final vehicleData = vehicleSnapshot.data() as Map<String, dynamic>;
    final isInsured = vehicleData['isInsured'] == true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Insurance Request"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Please provide the necessary details for insurance:"),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: hasAccident,
                    onChanged: (value) {
                      setState(() {
                        if (value != null) {
                          hasAccident = value;
                        }
                      });
                    },
                    title: const Text('Has the vehicle had an accident?'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      String userId = FirebaseAuth.instance.currentUser!.uid;

                      final insuranceRequestRef = FirebaseFirestore.instance
                          .collection('insurance_requests')
                          .doc();

                      final requestData = {
                        'vehicleId': vehicleId,
                        'userId': userId,
                        'requestType': isInsured ? 'renew' : 'new',
                        'submittedAt': Timestamp.now(),
                        'status': 'pending',
                        'adminResponse': {
                          'offerOptions': [],
                          'validityPeriod': null,
                        },
                        'selectedOffer': null,
                        'paymentConfirmed': false,
                      };

                      await insuranceRequestRef.set(requestData);

                      if (hasAccident) {
                        final vehicleRef = FirebaseFirestore.instance
                            .collection('vehicles')
                            .doc(vehicleId);
                        await vehicleRef.update({
                          'hasAccidentBefore': true,
                        });
                      }

                      Navigator.of(context).pop();
                      _showStyledSnackbar(
                          context, 'Insurance request submitted!',
                          isError: false);
                      setState(() {});
                    } catch (e) {
                      _showStyledSnackbar(
                          context, 'Error submitting insurance request: $e',
                          isError: true);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
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
