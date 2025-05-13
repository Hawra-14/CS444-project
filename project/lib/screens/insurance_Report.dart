import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class InsurancePolicyReportPage extends StatefulWidget {
  const InsurancePolicyReportPage({super.key});

  @override
  State<InsurancePolicyReportPage> createState() => _InsurancePolicyReportPageState();
}

class _InsurancePolicyReportPageState extends State<InsurancePolicyReportPage> {
  final TextEditingController _registrationController = TextEditingController();
  final List<int> _years = List.generate(20, (index) => DateTime.now().year - index); // Last 20 years
  String? _regFilter;
  int? _yearFilter;

  Stream<QuerySnapshot> _buildPolicyStream() {
    Query query = FirebaseFirestore.instance.collection('insurance_policies');

    if (_regFilter != null && _regFilter!.isNotEmpty) {
      query = query.where('registrationNumber', isEqualTo: _regFilter);
    }

    if (_yearFilter != null) {
      query = query.where('year', isEqualTo: _yearFilter);
    }

    return query.orderBy('year', descending: true).snapshots();
  }

  void _applyFilters() {
    setState(() {
      _regFilter = _registrationController.text.trim();
    });
  }

  void _clearFilters() {
    _registrationController.clear();
    setState(() {
      _regFilter = null;
      _yearFilter = null;
    });
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
            // Filters Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _registrationController,
                    decoration: InputDecoration(
                      labelText: 'Registration Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Filter by Year',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _yearFilter,
                    items: _years
                        .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                        .toList(),
                    onChanged: (value) => setState(() => _yearFilter = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text("Apply Filters"),
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear Filters',
                        onPressed: _clearFilters,
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Active Filters Display
            if (_regFilter != null || _yearFilter != null)
              Wrap(
                spacing: 8,
                children: [
                  if (_regFilter != null && _regFilter!.isNotEmpty)
                    Chip(label: Text("Reg: $_regFilter")),
                  if (_yearFilter != null)
                    Chip(label: Text("Year: $_yearFilter")),
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
