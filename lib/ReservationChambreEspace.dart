import 'dart:convert';

import 'package:beni_newlook/pages/facturationChambreEspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class Reservation extends StatefulWidget {
  final int identreprise;
  const Reservation({super.key, required this.identreprise});

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation> {
  final _formKey = GlobalKey<FormState>();
  //DateTime selectedDateReservation = DateTime.now();
  int? selectedChambreId;
  int? selectedClientId;
  List<Map<String, dynamic>> chambres = [];
  List<Map<String, dynamic>> client = [];
  final _prixReservationController = TextEditingController();
  DateTime? selectedDateEntree;
  final _dateEntreeController = TextEditingController();
  DateTime? selectedDateSortie;
  final _dateSortieController = TextEditingController();
  final _searchClientController = TextEditingController();
  final _nombreJoursController = TextEditingController();
  final _prixTotalController = TextEditingController();
  final _nbreOccupantsController = TextEditingController();
  final String _statutReservation = "En_attente";
  final _observationsController = TextEditingController();

  bool _isLoading = false;
  late Future<List<dynamic>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    fetchChambresEspaces();
    _reservationsFuture = displayReservations();
    fetchClients(
      entrepriseId: widget.identreprise,
      nameClient: "",
    ).then((data) {
      setState(() {
        client = data;
      });
    }).catchError((error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement des clients: $error"), backgroundColor: Colors.red),
      );
    });
  }

@override
  void dispose() {
    _prixReservationController.dispose();
    _dateEntreeController.dispose();
    _dateSortieController.dispose();
    _nombreJoursController.dispose();
    _prixTotalController.dispose();
    _nbreOccupantsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
  
  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 121, 169, 240)),
      border: const OutlineInputBorder(),
    );
  }

  void _calculateDaysAndTotal() {
    setState(() {
      if (selectedDateEntree != null && selectedDateSortie != null) {
        final difference = selectedDateSortie!.difference(selectedDateEntree!).inDays;
        _nombreJoursController.text = difference > 0 ? difference.toString() : "0";
      }

      final int prix = int.tryParse(_prixReservationController.text) ?? 0;
      final int jours = int.tryParse(_nombreJoursController.text) ?? 0;
      _prixTotalController.text = (prix * jours).toString();
    });
  }

  void resetForm() {
    _formKey.currentState!.reset();
    _prixReservationController.clear();
    _dateEntreeController.clear();
    _dateSortieController.clear();
    _nombreJoursController.clear();
    _prixTotalController.clear();
    _nbreOccupantsController.clear();
    _observationsController.clear();
    setState(() {
      selectedChambreId = null;
      selectedClientId = null;
      selectedDateEntree = null;
      selectedDateSortie = null;
    });
  }

  void _refreshReservations() {
    setState(() {
      _reservationsFuture = displayReservations();
    });
  }

  Future<void> addReservation() async {
  setState(() => _isLoading = true);

  
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AddReservation.php");

    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "date": DateTime.now().toLocal().toString().split(' ')[0],
        "espace": selectedChambreId,
        "client": selectedClientId,
        "dateArrivee": _dateEntreeController.text,
        "dateDepart": _dateSortieController.text,
        "prix": _prixReservationController.text,
        "nbreJours": _nombreJoursController.text,
        "total": _prixTotalController.text,
        "nbreOccupants": _nbreOccupantsController.text,
        "status": _statutReservation,
        "observation": _observationsController.text,
        "entreprise": widget.identreprise,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      // ✅ Cas où l’API renvoie un tableau vide []
      if (data is List && data.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text("Succès"),
            content: const Text("Réservation enregistrée avec succès"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetForm();
                  _refreshReservations();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ Cas normal avec objet JSON
      if (data is Map && data.containsKey('success')) {
        if (data['success'] == true) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: const Text("Succès"),
              content: Text(data['message'] ?? "Réservation enregistrée avec succès"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FacturationchambreEspace(identreprise: widget.identreprise)));
                    
                    resetForm();
                    _refreshReservations();
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.error, color: Colors.red, size: 48),
              title: const Text("Erreur"),
              content: Text(data['message'] ?? "Une erreur est survenue lors de l'enregistrement de la réservation ${response.body}"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
              ],
            ),
          );
        }
      } else {
        throw Exception("Réponse inattendue du serveur : ${response.body}");
      }
    }
      else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text("Erreur"),
            content: Text("Erreur HTTP ${response.statusCode} : ${response.body}"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
            ],
          ),
        );
      }
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

// Fetch chambres et espaces from the API
  Future<void> fetchChambresEspaces() async {
    try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/DisplayChambreEspace.php");
      var response = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'}, 
        body: json.encode({"entreprise": widget.identreprise}));
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        setState(() {
          if (responseData is List) {
            chambres = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map && responseData['success'] == true) {
            chambres = List<Map<String, dynamic>>.from(responseData['data']);
          } else {
            chambres = [];
          }
        });
      } else {
        return Future.error("Erreur de chargement des chambres et espaces: ${response.statusCode}");
      }
    } catch (e) {
      return Future.error("Erreur de connexion: $e");
    }
  }

  // Fetch clients from the API
  Future<List<Map<String, dynamic>>> fetchClients({
  required int entrepriseId,
  required String nameClient,
}) async {
  final url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/FetchClient.php");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "entreprise": entrepriseId.toString(),
      "nameclient": nameClient,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) {
      return data.map<Map<String, dynamic>>((client) => {
        "client_id": client["client_id"],
        "client_name": client["client_name"],
      }).toList();
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
        title: const Text('Réservation'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  backgroundColor: Colors.white,
                  title: const Row(
                    children: [
                      Icon(Icons.bookmark_add, color: Color.fromARGB(255, 121, 169, 240)),
                      SizedBox(width: 12),
                      Text(
                        "Effectuer une Réservation",
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
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Chambre/Espace',
                                      prefixIcon: Icon(Icons.bedroom_parent, color: Color.fromARGB(255, 121, 169, 240)),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: chambres.map((chambre) {
                                      return DropdownMenuItem<int>(
                                        value: chambre['IdEspace'] as int,
                                        child: Text(chambre['designationEspace'] as String),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedChambreId = value;
                                        var selected = chambres.firstWhere((c) => c['IdEspace'] == value);
                                        if (selected.containsKey('PrixEspace')) {
                                          _prixReservationController.text = selected['PrixEspace'].toString();
                                          _calculateDaysAndTotal();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TypeAheadField<Map<String, dynamic>>(
                                    controller: _searchClientController,
                                    builder: (context, controller, focusNode) => TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: _inputDecoration(
                                        labelText: 'Rechercher client',
                                        icon: Icons.person_search,
                                      ),
                                      validator: (value) => value == null || value.isEmpty
                                          ? 'Veuillez entrer un client'
                                          : null,
                                    ),
                                    suggestionsCallback: (pattern) async {
                                      if (pattern.isEmpty || pattern.length < 2) return [];
                                      return await fetchClients(
                                        entrepriseId: widget.identreprise,
                                        nameClient: pattern,
                                      );
                                    },
                                    itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion['client_name'])),
                                    onSelected: (suggestion) {
                                      setState(() {
                                        _searchClientController.text = suggestion['client_name'];
                                        selectedClientId = suggestion['client_id'];
                                      });
                                    },
                                  )
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _prixReservationController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Prix de réservation',
                                      prefixIcon: Icon(Icons.attach_money, color: Color.fromARGB(255, 121, 169, 240)),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _calculateDaysAndTotal(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _dateEntreeController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Date d\'entrée',
                                      prefixIcon: Icon(Icons.login, color: Color.fromARGB(255, 121, 169, 240)),
                                      border: OutlineInputBorder(),
                                    ),
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          selectedDateEntree = pickedDate;
                                          _dateEntreeController.text = "${pickedDate.toLocal()}".split(' ')[0];
                                          _calculateDaysAndTotal();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dateSortieController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Date de sortie',
                                      prefixIcon: Icon(Icons.logout, color: Color.fromARGB(255, 121, 169, 240)),
                                      border: OutlineInputBorder(),
                                    ),
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          selectedDateSortie = pickedDate;
                                          _dateSortieController.text = "${pickedDate.toLocal()}".split(' ')[0];
                                          _calculateDaysAndTotal();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nombreJoursController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre de jours',
                                      prefixIcon: Icon(Icons.calendar_month, color: Color.fromARGB(255, 121, 169, 240)),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _prixTotalController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Prix total',
                                      prefixIcon: Icon(Icons.calculate, color: Color.fromARGB(255, 121, 169, 240)),
                                      fillColor: Color.fromARGB(255, 240, 240, 240),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nbreOccupantsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre d\'occupants',
                                      prefixIcon: Icon(Icons.group, color: Color.fromARGB(255, 121, 169, 240)),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _observationsController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Observations',
                                prefixIcon: Icon(Icons.note, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () {
                                if (_formKey.currentState!.validate()) {
                                  addReservation();
                                }
                              },
                              icon: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save),
                              label: Text(_isLoading ? 'Chargement...' : 'Enregistrer la réservation'),
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
            // --- Tableau des Réservations ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _reservationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 121, 169, 240)));
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
                                  DataColumn(label: Text("Client", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Espace", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Arrivée", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Départ", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Jours", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Total", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Statut", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                ],
                                rows: snapshot.data!.reversed.toList().asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var item = entry.value;
                                  return DataRow(
                                    color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255)),
                                    cells: [
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
                                            color: item['statutReservation'] == "Confirmée" 
                                                ? Colors.green.withOpacity(0.1) 
                                                : Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item['statutReservation']?.toString() ?? '',
                                            style: TextStyle(
                                              color: item['statutReservation'] == "Confirmée" 
                                                  ? Colors.green 
                                                  : Colors.orange,
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
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
