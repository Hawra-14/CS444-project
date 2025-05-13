import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class InsurancePolicyReportPage extends StatefulWidget {
  const InsurancePolicyReportPage({super.key});

  @override
  State<InsurancePolicyReportPage> createState() => _InsurancePolicyReportPageState();
}

class _InsurancePolicyReportPageState extends State<InsurancePolicyReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<int> _years = List.generate(20, (index) => DateTime.now().year - index);

  String _searchQuery = '';
  bool _filterByCRN = false;
  int? _selectedYear;

  // Stream that fetches and filters insurance policies
  Stream<List<QueryDocumentSnapshot>> _buildPolicyStream() async* {
    // Fetch all policies from the collection
    final querySnapshot = await FirebaseFirestore.instance
        .collection('insurance_policies')
        .orderBy('year', descending: true)
        .get();

    List<QueryDocumentSnapshot> allDocs = querySnapshot.docs;

    // Apply CRN filter (only current policies)
    if (_filterByCRN) {
      allDocs = allDocs.where((doc) => doc['isCurrent'] == true).toList();
    }

    // Apply search query (contains) for registration number
    if (_searchQuery.isNotEmpty) {
      allDocs = allDocs
          .where((doc) => doc['registrationNumber']
              .toString()
              .toLowerCase()
              .contains(_searchQuery))
          .toList();
    }

    // Apply year filter
    if (_selectedYear != null) {
      allDocs = allDocs.where((doc) => doc['year'] == _selectedYear).toList();
    }

    // Yield the filtered list
    yield allDocs;
  }

  // Helper method to build each policy card
  Widget _buildPolicyCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Model: ${data['model']}", style: _titleStyle()),
            const SizedBox(height: 4),
            Text("Registration Number: ${data['registrationNumber']}", style: _bodyStyle()),
            Text("Year: ${data['year']}", style: _bodyStyle()),
            Text("Policy Value: ${data['policyValue']} BD", style: _bodyStyle()),
            if (data['isCurrent'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  label: const Text('Current Policy'),
                  backgroundColor: Colors.green[100],
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // TextStyle helpers for consistent typography
  TextStyle _titleStyle() => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);
  TextStyle _bodyStyle() => GoogleFonts.poppins(fontSize: 14, color: Colors.black87);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E7FF).withOpacity(0.95),
        elevation: 6,
        shadowColor: Colors.black38,
        centerTitle: true,
        toolbarHeight: 70,
        title: Text(
          "Insurance Policy Reports",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by registration number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),

            // Filter Options (Row layout for chips)
            Row(
              children: [
                // CRN filter
                ChoiceChip(
                  label: const Text("Filter by CRN"),
                  selected: _filterByCRN,
                  onSelected: (selected) {
                    setState(() {
                      _filterByCRN = selected;
                    });
                  },
                  selectedColor: const Color(0xFF4F46E5),
                  labelStyle: TextStyle(
                    color: _filterByCRN ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),

                // Year filter (Dropdown)
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Filter by Year',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _years
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                ),
                if (_selectedYear != null)
                  IconButton(
                    tooltip: 'Clear Year',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedYear = null;
                      });
                    },
                  )
              ],
            ),

            const SizedBox(height: 16),

            // Results - Displaying the list of policies
            Expanded(
              child: StreamBuilder<List<QueryDocumentSnapshot>>(
                stream: _buildPolicyStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No insurance policies found."));
                  }

                  final docs = snapshot.data!;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      return _buildPolicyCard(docs[index].data() as Map<String, dynamic>);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
