// insurance_report_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/screens/accident_Report.dart';

class InsuranceReportPage extends StatefulWidget {
  const InsuranceReportPage({super.key});

  @override
  State<InsuranceReportPage> createState() => _InsuranceReportPageState();
}

class _InsuranceReportPageState extends State<InsuranceReportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'CRN'; // Default filter
  bool _isLoading = false;

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
          "Insurance Report",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search insured vehicles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Filter Options
                Row(
                  children: [
                    Text(
                      "Filter by: ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text("CRN"),
                      selected: _filterType == 'CRN',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = selected ? 'CRN' : _filterType;
                        });
                      },
                      selectedColor: const Color(0xFF4F46E5),
                      labelStyle: TextStyle(
                        color: _filterType == 'CRN' ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Year"),
                      selected: _filterType == 'Year',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = selected ? 'Year' : _filterType;
                        });
                      },
                      selectedColor: const Color(0xFF4F46E5),
                      labelStyle: TextStyle(
                        color: _filterType == 'Year' ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Vehicles List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .where('isInsured', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No insured vehicles found',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }

                final vehicles = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchField = _filterType == 'CRN' 
                      ? data['registrationNumber'].toString().toLowerCase()
                      : data['manufacturingYear'].toString().toLowerCase();
                  
                  return searchField.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final data = vehicle.data() as Map<String, dynamic>;
                    final photos = data['photos'] as List<dynamic>?;
                    final firstPhoto = photos?.isNotEmpty == true ? photos![0] : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: firstPhoto != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(firstPhoto),
                                radius: 25,
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.directions_car),
                              ),
                        title: Text(
                          data['model'] ?? 'Unknown Model',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'CRN: ${data['registrationNumber'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccidentReportPage(
                                  vehicleId: vehicle.id,
                                  vehicleData: data,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Accident Report',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}