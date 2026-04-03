import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FacturationchambreEspace extends StatefulWidget {
  final int identreprise;
  const FacturationchambreEspace({super.key, required this.identreprise});

  @override
  State<FacturationchambreEspace> createState() => _FacturationchambreEspaceState();
}

class _FacturationchambreEspaceState extends State<FacturationchambreEspace> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<dynamic>> _reservationsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _reservationsFuture = displayReservations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch the list of reservations to display in the table
  Future<List<dynamic>> displayReservations() async {
    try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficheReservations.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"entreprise": widget.identreprise.toString()}),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['success'] == true) return data['data'];
        return [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération des réservations: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturation Chambre Espace'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un client...',
                  prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 121, 169, 240)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                  ),
                ),
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: _reservationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color.fromARGB(255, 121, 169, 240)));
                } else if (snapshot.hasError) {
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text("Aucune réservation trouvée", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                } else {
                  final filteredList = snapshot.data!.where((item) {
                    final clientName = item['client_name']?.toString().toLowerCase() ?? '';
                    return clientName.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredList.isEmpty) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text("Aucun résultat pour '$_searchQuery'", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                              headingRowHeight: 56,
                              dataRowHeight: 48,
                              horizontalMargin: 24,
                              border: TableBorder(
                                horizontalInside: BorderSide(color: Colors.grey[300]!),
                                bottom: BorderSide(color: Colors.grey[300]!),
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                              columns: const [
                                DataColumn(label: Text("ID", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Client", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Espace", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Arrivée", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Départ", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Jours", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Total", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Statut", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredList.reversed.toList().asMap().entries.map((entry) {
                                int index = entry.key;
                                var item = entry.value;
                                return DataRow(
                                  color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255)),
                                  cells: [
                                    DataCell(Text(item['IdReservation']?.toString() ?? '')),
                                    DataCell(Text(item['client_name']?.toString() ?? '')),
                                    DataCell(Text(item['designationEspace']?.toString() ?? '')),
                                    DataCell(Text(item['DateArrivee']?.toString() ?? '')),
                                    DataCell(Text(item['DateDepart']?.toString() ?? '')),
                                    DataCell(Text(item['NbreJours']?.toString() ?? '0')),
                                    DataCell(Text("${item['Totalpayer']} \$", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item['statutReservation'] == "Confirmée" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['statutReservation']?.toString() ?? '',
                                          style: TextStyle(
                                            color: item['statutReservation'] == "Confirmée" ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
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
          ],
        ),
      ),
    );
  }
}
