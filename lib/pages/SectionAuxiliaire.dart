// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Sectionauxiliaire extends StatefulWidget {
  final int iDentreprise;
  const Sectionauxiliaire({super.key, required this.iDentreprise});

  @override
  State<Sectionauxiliaire> createState() => _SectionauxiliaireState();
}

class _SectionauxiliaireState extends State<Sectionauxiliaire> {
  final _formKey = GlobalKey<FormState>();
  final _designationSectionAuxiliaireController = TextEditingController();
  bool _isLoading = false;
  late Future<List<dynamic>> _futureSectionAuxiliaire;



@override
  void initState() {
    super.initState();
    _futureSectionAuxiliaire = fetchSectionsAuxiliaires(widget.iDentreprise);
  }


  void resetForm() {
    _designationSectionAuxiliaireController.clear();
  }

  void _refreshSections() {
    setState(() {
      _futureSectionAuxiliaire = fetchSectionsAuxiliaires(widget.iDentreprise);
    });
  }

  Future<void> ajouterSectionAuxiliaire() async {
    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/SectionsAuxiliaires.php");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "descriptionsectauxi": _designationSectionAuxiliaireController.text,
          "entreprise": widget.iDentreprise.toString(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Succès"),
                  content: Text(data['message']?.toString() ?? "Section ajoutée"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        resetForm();
                        _refreshSections();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          if (mounted) {
            final errorMsg = data['message']?.toString() ?? data['error']?.toString() ?? "Erreur inconnue";
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Erreur"),
                  content: Text(errorMsg),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Erreur serveur"),
                content: Text("Code: ${response.statusCode}"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Erreur"),
              content: Text("Une erreur de connexion est survenue : $e"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // afficher section auxiliaires existantes
  Future<List<dynamic>> fetchSectionsAuxiliaires(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AffcherSectionAuxi.php");
  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"entreprise": entrepriseId.toString()}),
  );
  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    if (data is List) {
      return data;
    } else if (data is Map && data['success'] == true) {
      return data['data']; // retourne la liste des sections
    } else {
      return [];
    }
  } else {
    throw Exception("Erreur HTTP : ${response.statusCode}");
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sections auxiliaires"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // --- Formulaire repliable ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  collapsedBackgroundColor: const Color.fromARGB(255, 245, 248, 255),
                  backgroundColor: Colors.white,
                  title: Row(
                    children: [
                      const Icon(Icons.add_box, color: Color.fromARGB(255, 121, 169, 240)),
                      const SizedBox(width: 12),
                      const Text(
                        "Ajouter une Section Auxiliaire",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 121, 169, 240),
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
                              controller: _designationSectionAuxiliaireController,
                              decoration: InputDecoration(
                                labelText: "Désignation",
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: const Icon(Icons.label, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une désignation' : null,
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        ajouterSectionAuxiliaire();
                                      }
                                    },
                              icon: const Icon(Icons.check),
                              label: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Enregistrer', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 121, 169, 240),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            // --- Tableau des sections ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _futureSectionAuxiliaire,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 121, 169, 240)));
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
                            Expanded(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red))),
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
                              "Aucune section auxiliaire trouvée",
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
                          // Calcul des largeurs pour remplir le tableau (20% ID, 80% Désignation)
                          double availableWidth = constraints.maxWidth - 48; // 48 = marges (24 * 2)
                          double idWidth = availableWidth * 0.2;
                          double designationWidth = availableWidth * 0.8;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
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
                                  DataColumn(label: SizedBox(width: idWidth, child: const Text("ID", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold)))),
                                  DataColumn(label: SizedBox(width: designationWidth, child: const Text("Section auxiliaire", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold)))),
                                ],
                                rows: snapshot.data!.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var section = entry.value;
                                  // Adapting to likely keys based on SectionsPrincipales and add method
                                  var id = section['idSectionAuxi'];
                                  var designation = section['designationSectionAuxi'];

                                  return DataRow(
                                    color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255)),
                                    cells: [
                                      DataCell(SizedBox(width: idWidth, child: Text(id.toString(), style: const TextStyle(fontWeight: FontWeight.w500)))),
                                      DataCell(SizedBox(width: designationWidth, child: Text(designation.toString()))),
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