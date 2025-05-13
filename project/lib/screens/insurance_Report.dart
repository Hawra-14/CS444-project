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

  Stream<QuerySnapshot> _buildPolicyStream() {
    Query query = FirebaseFirestore.instance.collection('insurance_policies');

    if (_searchQuery.isNotEmpty && _filterByCRN) {
      query = query.where('registrationNumber', isEqualTo: _searchQuery);
    }

    if (_selectedYear != null) {
      query = query.where('year', isEqualTo: _selectedYear);
    }

    return query.orderBy('year', descending: true).snapshots();
  }

  Widget _buildPolicyCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Registration Number: ${data['registrationNumber']}", style: _titleStyle()),
            const SizedBox(height: 4),
            Text("Model: ${data['model']}", style: _bodyStyle()),
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

  TextStyle _titleStyle() => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);
  TextStyle _bodyStyle() => GoogleFonts.poppins(fontSize: 14, color: Colors.black87);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insurance Policy Report', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.indigo[100],
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

            // Filter Options
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

                // Year filter
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

            // Results
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildPolicyStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No insurance policies found."));
                  }

                  final docs = snapshot.data!.docs;

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