import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EvolutionReservations extends StatefulWidget {
  final int identreprise;
  const EvolutionReservations({super.key, required this.identreprise});

  @override
  State<EvolutionReservations> createState() => _EvolutionReservationsState();
}

class _EvolutionReservationsState extends State<EvolutionReservations> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  List<dynamic> _reservations = [];
  bool _isLoading = false;

  // Fonction pour récupérer les données de l'API
  Future<void> _fetchReservations() async {
    if (_dateDebutController.text.isEmpty || _dateFinController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://riphin-salemanager.com/beni_newlook_API/ReservationsPar_DateEntree.php"),
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
          _reservations = data is List ? data : (data['data'] ?? []);
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
        _fetchReservations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Évolution des Réservations"),
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
                  : _reservations.isEmpty
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
                                  DataColumn(label: Text("Client", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Chambre/Espace", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Arrivée", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Départ", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Jours", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Statut", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _reservations.map((res) {
                                  return DataRow(cells: [
                                    DataCell(Text(res['client_name']?.toString() ?? "")),
                                    DataCell(Text(res['designationEspace']?.toString() ?? "")),
                                    DataCell(Text(res['DateArrivee']?.toString() ?? "")),
                                    DataCell(Text(res['DateDepart']?.toString() ?? "")),
                                    DataCell(Text(res['NbreJours']?.toString() ?? "")),
                                    DataCell(Text("${res['Totalpayer']} \$", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(res['statutReservation']?.toString() ?? "")),
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