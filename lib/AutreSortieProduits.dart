import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutreSortieProduits extends StatefulWidget {
  final int identreprise;
  const AutreSortieProduits({super.key, required this.identreprise});

  @override
  State<AutreSortieProduits> createState() => _AutreSortieProduitsState();
}

class _AutreSortieProduitsState extends State<AutreSortieProduits> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> stocks = [];
  int? selectedStock;

  final List<String> motifsSortie = [
    'Bouteilles cassées',
    'Bouteilles abîmées',
    'Périmées',
    'Perte/Vol',
    'Don',
    'Usage interne',
  ];
  String? selectedMotif;

  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _filterStockController = TextEditingController();
  final TextEditingController _filterStartDateController = TextEditingController();
  final TextEditingController _filterEndDateController = TextEditingController();

  late Future<List<Map<String, dynamic>>> sortiesFuture;

  @override
  void initState() {
    super.initState();
    fetchStocks();
    sortiesFuture = fetchSorties(widget.identreprise);
  }

  Future<void> fetchStocks() async {
    final url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherStocks.php");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"entreprise": widget.identreprise}),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        stocks = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> enregistrerSortie() async {
    try {
      final url = Uri.parse('https://riphin-salemanager.com/beni_newlook_API/AjouterAutreSortieProduit.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idstock': selectedStock,
          'quantite': _quantiteController.text,
          'motifSortie': selectedMotif,
          'datesortie': _dateController.text,
          'entreprise': widget.identreprise,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success']) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  title: const Text('Succès'),
                  content: const Text('Sortie enregistrée avec succès !'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                    ),
                  ],
                ),
              );
              setState(() {
                selectedStock = null;
                selectedMotif = null;
                _quantiteController.clear();
                _dateController.clear();
                sortiesFuture = fetchSorties(widget.identreprise);
              });
            }
          });
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
                title: const Text('Erreur'),
                content: Text("Échec d'enregistrement: ${json['error']}"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
              title: const Text('Erreur'),
              content: Text("Échec de la requête: ${response.statusCode}"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Erreur de Connexion'),
          content: Text("Erreur de connexion: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
            ),
          ],
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchSorties(int entrepriseId) async {
    final url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherAutresSortieProduits.php");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"entreprise": entrepriseId}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } else {
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autre Sortie Produits'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Formulaire d'ajout
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
                    children: const [
                      Icon(Icons.remove_circle_outline, color: Color.fromARGB(255, 121, 169, 240)),
                      SizedBox(width: 12),
                      Text(
                        "Enregistrer une Sortie",
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
                            // Dropdown Stock
                            DropdownButtonFormField<int>(
                              value: selectedStock,
                              decoration: InputDecoration(
                                labelText: 'Désignation du stock',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: const Icon(Icons.storage, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              items: stocks.map((stock) {
                                return DropdownMenuItem<int>(
                                  value: stock['IdStock'],
                                  child: Text(stock['designationStock']),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => selectedStock = value),
                              validator: (value) => value == null ? 'Veuillez sélectionner un stock' : null,
                            ),
                            const SizedBox(height: 20),
                            // Dropdown Motif de sortie
                            DropdownButtonFormField<String>(
                              value: selectedMotif,
                              decoration: InputDecoration(
                                labelText: 'Motif de sortie',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              items: motifsSortie.map((motif) {
                                return DropdownMenuItem<String>(
                                  value: motif,
                                  child: Text(motif),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => selectedMotif = value),
                              validator: (value) => value == null ? 'Veuillez sélectionner un motif' : null,
                            ),
                            const SizedBox(height: 20),
                            // Quantité
                            TextFormField(
                              controller: _quantiteController,
                              decoration: InputDecoration(
                                labelText: 'Quantité',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: const Icon(Icons.countertops, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une quantité' : null,
                            ),
                            const SizedBox(height: 20),
                            // Date de sortie
                            TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Date de sortie',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode());
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _dateController.text =
                                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez sélectionner une date' : null,
                            ),
                            const SizedBox(height: 28),
                            // Bouton Enregistrer
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  enregistrerSortie();
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text(
                                'Enregistrer',
                                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                              ),
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

            // Filtres de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _filterStockController,
                          decoration: InputDecoration(
                            labelText: 'Rechercher stock',
                            labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                            prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _filterStartDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date début',
                            labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                            prefixIcon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            isDense: true,
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _filterStartDateController.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _filterEndDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date fin',
                            labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                            prefixIcon: const Icon(Icons.event, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            isDense: true,
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _filterEndDateController.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // DataTable des sorties
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: sortiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 121, 169, 240)),
                        ),
                      ),
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
                  } else {
                    var sorties = snapshot.data ?? [];

                    // Filtrage
                    var filtered = sorties.where((s) {
                      bool matchesStock = _filterStockController.text.isEmpty ||
                          (s['designationStock'] ?? '').toString().toLowerCase().contains(_filterStockController.text.toLowerCase());
                      bool matchesStart = _filterStartDateController.text.isEmpty ||
                          (s['datesortie'] ?? '').compareTo(_filterStartDateController.text) >= 0;
                      bool matchesEnd = _filterEndDateController.text.isEmpty ||
                          (s['datesortie'] ?? '').compareTo(_filterEndDateController.text) <= 0;
                      return matchesStock && matchesStart && matchesEnd;
                    }).toList();

                    if (filtered.isEmpty) {
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
                                sorties.isEmpty ? "Aucune sortie enregistrée" : "Aucun résultat trouvé",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Utilisez le formulaire ci-dessus pour enregistrer une sortie",
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color.fromARGB(255, 121, 169, 240).withValues(alpha: 0.15),
                          ),
                          headingRowHeight: 56,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                          columns: const [
                            DataColumn(label: Text("Stock", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Quantité", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Motif", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          ],
                          rows: List.generate(filtered.length, (index) {
                            final s = filtered[index];
                            return DataRow(
                              color: WidgetStateProperty.all(
                                index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255),
                              ),
                              cells: [
                                DataCell(Text(s['designationStock'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(s['Quantite'].toString())),
                                DataCell(Text(s['MotifSortie'] ?? '')),
                                DataCell(Text(s['datesortie'] ?? '')),
                              ],
                            );
                          }),
                        ),
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
