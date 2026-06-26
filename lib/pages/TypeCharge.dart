// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TypeCharge extends StatefulWidget {
  final int identreprise;
  const TypeCharge({super.key, required this.identreprise});

  @override
  State<TypeCharge> createState() => _TypeChargeState();
}

class _TypeChargeState extends State<TypeCharge> {
  final _formKey = GlobalKey<FormState>();
  final _designationController = TextEditingController();
  bool _isLoading = false;
  late Future<List<dynamic>> _futureTypeCharges;

  static const _primaryColor = Color.fromARGB(255, 121, 169, 240);

  @override
  void initState() {
    super.initState();
    _futureTypeCharges = fetchTypeCharges(widget.identreprise);
  }

  @override
  void dispose() {
    _designationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _designationController.clear();
  }

  void _refresh() {
    setState(() {
      _futureTypeCharges = fetchTypeCharges(widget.identreprise);
    });
  }

  Future<List<dynamic>> fetchTypeCharges(int entrepriseId) async {
    var url = Uri.parse(
        "https://riphin-salemanager.com/beni_newlook_API/AfficherTypeCharges.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"entreprise": entrepriseId}),
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data is List) return data;
      if (data is Map && data['success'] == true) return data['data'] ?? [];
      return [];
    } else {
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }

  Future<void> _addTypeCharge() async {
    setState(() => _isLoading = true);

    try {
      var url = Uri.parse(
          "https://riphin-salemanager.com/beni_newlook_API/AddTypeCharge.php");
      var response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "designation": _designationController.text,
              "entreprise": widget.identreprise,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success'] == true) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: const Text('Succès'),
              content: const Text("Type de charge ajouté avec succès."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _resetForm();
                    _refresh();
                  },
                  child: const Text('OK', style: TextStyle(color: _primaryColor)),
                ),
              ],
            ),
          );
        } else {
          _showErrorDialog("Erreur d'enregistrement: ${data['error'] ?? data['message']}");
        }
      } else {
        _showErrorDialog("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog("Erreur de connexion: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Types de charges'),
        backgroundColor: _primaryColor,
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // --- Formulaire ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  collapsedBackgroundColor: const Color.fromARGB(255, 245, 248, 255),
                  backgroundColor: Colors.white,
                  title: const Row(
                    children: [
                      Icon(Icons.add_box, color: _primaryColor),
                      SizedBox(width: 12),
                      Text(
                        "Ajouter un Type de charge",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _designationController,
                              decoration: InputDecoration(
                                labelText: 'Désignation',
                                labelStyle: const TextStyle(color: _primaryColor),
                                prefixIcon: const Icon(Icons.label_outline, color: _primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _primaryColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _primaryColor, width: 2),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Veuillez entrer la désignation'
                                  : null,
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _addTypeCharge();
                                      }
                                    },
                              icon: const Icon(Icons.check),
                              label: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Enregistrer',
                                      style: TextStyle(
                                          fontSize: 14.0, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Tableau ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _futureTypeCharges,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                    );
                  } else if (snapshot.hasError) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text("Erreur: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              "Aucun type de charge trouvé",
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double available = constraints.maxWidth - 48;
                          double idWidth = available * 0.2;
                          double designationWidth = available * 0.8;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    _primaryColor.withValues(alpha: 0.15)),
                                headingRowHeight: 56,
                                // ignore: deprecated_member_use
                                dataRowHeight: 48,
                                columnSpacing: 0,
                                horizontalMargin: 24,
                                border: TableBorder(
                                  horizontalInside: BorderSide(color: Colors.grey[300]!),
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                  top: BorderSide(color: Colors.grey[300]!),
                                ),
                                columns: [
                                  DataColumn(
                                    label: SizedBox(
                                      width: idWidth,
                                      child: const Text("ID",
                                          style: TextStyle(
                                              color: _primaryColor,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: designationWidth,
                                      child: const Text("Désignation",
                                          style: TextStyle(
                                              color: _primaryColor,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                                rows: snapshot.data!.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var charge = entry.value;
                                  return DataRow(
                                    color: WidgetStateProperty.all(index.isEven
                                        ? Colors.white
                                        : const Color.fromARGB(255, 245, 248, 255)),
                                    cells: [
                                      DataCell(SizedBox(
                                        width: idWidth,
                                        child: Text(
                                          charge['IdCharge'].toString(),
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      )),
                                      DataCell(SizedBox(
                                        width: designationWidth,
                                        child: Text(charge['DesignationCharge'] ?? ""),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
