import 'dart:convert';
import 'package:beni_newlook/Rapports/Facturelogement.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FacturesLogement_date extends StatefulWidget {
  final int identreprise;
  const FacturesLogement_date({super.key, required this.identreprise});

  @override
  State<FacturesLogement_date> createState() => _FacturesLogement_dateState();
}

class _FacturesLogement_dateState extends State<FacturesLogement_date> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  List<dynamic> _factures = [];
  bool _isLoading = false;

  // Fonction pour récupérer les données de l'API
  Future<void> _fetchFactures() async {
    if (_dateDebutController.text.isEmpty || _dateFinController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://riphin-salemanager.com/beni_newlook_API/facturesLogement.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "entreprise": widget.identreprise,
          "date1": _dateDebutController.text,
          "date2": _dateFinController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // On s'attend à recevoir une liste directement ou via une clé 'data'
          _factures = data is List ? data : (data['data'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la récupération : $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Sélecteur de date (Calendrier)
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
      // Le filtrage est automatique dès que les deux dates sont sélectionnées
      if (_dateDebutController.text.isNotEmpty && _dateFinController.text.isNotEmpty) {
        _fetchFactures();
      }
    }
  }


  // Nouvelle méthode pour imprimer une facture existante
  Future<void> _printFacture(Map<String, dynamic> facture) async {
    try {
      final entrepriseResponse = await http.post(
        Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"idEse": widget.identreprise}),
      );
      final entrepriseData = jsonDecode(entrepriseResponse.body)['data'];

      await generateThermalFacturePDF(entrepriseData, facture);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'impression: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Évolution des Factures de Logement"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateDebutController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date Début",
                          prefixIcon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onTap: () => _selectDate(context, _dateDebutController),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dateFinController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date Fin",
                          prefixIcon: const Icon(Icons.event, color: Color.fromARGB(255, 121, 169, 240)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onTap: () => _selectDate(context, _dateFinController),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _factures.isEmpty
                      ? const Center(child: Text("Sélectionnez une période pour afficher les données"))
                      : Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                                columns: const [
                                  DataColumn(label: Text("ID_Facture", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Date Facture ", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Client", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Chambre/Espace", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Arrivée", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Départ", style: TextStyle(fontWeight: FontWeight.bold))),
                                  //DataColumn(label: Text("Jours", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                                  //DataColumn(label: Text("Statut", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _factures.map((facture) {
                                  return DataRow(cells: [
                                    DataCell(Text(facture['IdFacture']?.toString() ?? "")),
                                    DataCell(Text(facture['dateFacturation']?.toString() ?? "")),
                                    DataCell(Text(facture['client_name']?.toString() ?? "")),
                                    DataCell(Text(facture['designationEspace']?.toString() ?? "")),
                                    DataCell(Text(facture['DateArrivee']?.toString() ?? "")),
                                    DataCell(Text(facture['DateDepart']?.toString() ?? "")),
                                    //DataCell(Text(facture['NbreJours']?.toString() ?? "")),
                                    DataCell(Text("${facture['Totalpayer']} \$", style: const TextStyle(fontWeight: FontWeight.bold))), // Changed from FontWeight.FontWeight.bold to FontWeight.bold
                                    //DataCell(Text(facture['statutReservation']?.toString() ?? "")),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.print, color: Color.fromARGB(255, 121, 169, 240)),
                                        tooltip: "Réimprimer la facture",
                                        onPressed: () => _printFacture(Map<String, dynamic>.from(facture)),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}