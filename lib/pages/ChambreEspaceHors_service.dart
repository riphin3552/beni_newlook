import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChambreespacehorsService extends StatefulWidget {
  final int identreprise;
  const ChambreespacehorsService({super.key, required this.identreprise});

  @override
  State<ChambreespacehorsService> createState() => _ChambreespacehorsServiceState();
}

class _ChambreespacehorsServiceState extends State<ChambreespacehorsService> {
  final formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> listChambreEspace = [];
  String? _statutChambreEspaceSelected;
  int? _idChambreEspaceSelected;
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  DateTime? _selectedDateDebut;
  DateTime? _selectedDateFin;
  late Future<List<dynamic>> _futureHorsService;


  //methode pour afficher les chambres et espaces dans un combobox
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
            listChambreEspace = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map && responseData['success'] == true) {
            listChambreEspace = List<Map<String, dynamic>>.from(responseData['data']);
          } else {
            listChambreEspace = [];
          }
        });
      } else {
        return Future.error("Erreur de chargement des chambres et espaces: ${response.statusCode}");
      }
    } catch (e) {
      return Future.error("Erreur de connexion: $e");
    }
  }
  
  @override
  void initState() {
    super.initState();
    fetchChambresEspaces();
    _futureHorsService = fetchChambresEspaceshorService(widget.identreprise);
  }

  void _refreshList() {
    setState(() {
      _futureHorsService = fetchChambresEspaceshorService(widget.identreprise);
    });
  }


  //reset les champs du formulaire après une mise à jour réussie
  void resetForm() {
    formKey.currentState!.reset();
    setState(() {
      _idChambreEspaceSelected = null;
      _statutChambreEspaceSelected = null;
      _dateDebutController.clear();
      _dateFinController.clear();
      _selectedDateDebut = null;
      _selectedDateFin = null;
    });
  }
  
  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 121, 169, 240)),
      border: const OutlineInputBorder(),
    );
  }

  // Enregistrer la mise hors service d'une chambre/espace
  Future<void> updateChambreEspaceStatus() async {
    try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/EspacehorService.php");

      final bodyData = {
        "chambre": _idChambreEspaceSelected,
        "statut": _statutChambreEspaceSelected,
        "datedebut": _dateDebutController.text,
        "datefin": _dateFinController.text,
        "entreprise": widget.identreprise,
      };

      // Impression du body pour le débogage
      //print("DEBUG (updateChambreEspaceStatus) - Request Body: ${json.encode(bodyData)}");

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyData),
      );
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          if (!mounted) return;
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.check_circle, color: Colors.green),
                title: const Text("chambre/espace mis hors service avec succès"),
                //content: Text(responseData['message']),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      resetForm(); // Réinitialiser le formulaire après une mise à jour réussie
                      fetchChambresEspaces(); // Rafraîchir la liste après mise à jour
                      _refreshList(); // Rafraîchir le tableau
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
            
          );
        } else {
          if (!mounted) return;
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.error, color: Colors.red),
                title: const Text("Erreur de mise hors service"),
                content: Text(responseData['message']),
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
      } else {
        return Future.error("Erreur de mise à jour du statut: ${response.statusCode}");  
      }
    } catch (e) {
      return Future.error("Erreur de connexion: $e");
    }
  }


  //Affichage liste des chambres/espaces
  Future<List<dynamic>> fetchChambresEspaceshorService(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/afficherChambresEspaceHorService.php");
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
      return data['data']; // retourne la liste des chambres/espaces
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
        title: const Text('Chambre/Espace Hors Service'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              initiallyExpanded: true,
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.room_preferences, color: Color.fromARGB(255, 121, 169, 240)),
                  SizedBox(width: 12),
                  Text(
                    "Gérer le statut des Chambres/Espaces",
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
                    key: formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: _inputDecoration(labelText: 'Chambre/Espace', icon: Icons.bedroom_parent),
                          initialValue: _idChambreEspaceSelected,
                          items: listChambreEspace.map((chambre) {
                            return DropdownMenuItem<int>(
                              value: chambre['IdEspace'] as int,
                              child: Text(chambre['designationEspace'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _idChambreEspaceSelected = value;
                            });
                          },
                          validator: (value) => value == null ? 'Veuillez sélectionner une chambre/espace' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(labelText: 'Statut', icon: Icons.info_outline),
                          initialValue: _statutChambreEspaceSelected,
                          items: ["Disponible", "Occupé", "Maintenance", "Bloquée"].map((String val) {
                            return DropdownMenuItem<String>(value: val, child: Text(val));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _statutChambreEspaceSelected = value;
                            });
                          },
                          validator: (value) => value == null ? 'Veuillez sélectionner un statut' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateDebutController,
                                readOnly: true,
                                decoration: _inputDecoration(
                                  labelText: 'Date Début',
                                  icon: Icons.calendar_today,
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
                                      _selectedDateDebut = pickedDate;
                                      _dateDebutController.text = "${pickedDate.toLocal()}".split(' ')[0];
                                    });
                                  }
                                },
                                validator: (value) => value == null || value.isEmpty ? 'Veuillez choisir une date' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _dateFinController,
                                readOnly: true,
                                decoration: _inputDecoration(
                                  labelText: 'Date Fin',
                                  icon: Icons.event,
                                ),
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDateDebut ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _selectedDateFin = pickedDate;
                                      _dateFinController.text = "${pickedDate.toLocal()}".split(' ')[0];
                                    });
                                  }
                                },
                                validator: (value) => value == null || value.isEmpty ? 'Veuillez choisir une date' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              updateChambreEspaceStatus();
                              
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Mettre à jour le statut'),
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
          const SizedBox(height: 32),
          // --- Tableau des chambres et espaces hors service ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<List<dynamic>>(
              future: _futureHorsService,
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
                            "Aucun historique hors service trouvé",
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
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                              headingRowHeight: 56,
                              horizontalMargin: 24,
                              border: TableBorder(
                                horizontalInside: BorderSide(color: Colors.grey[300]!),
                                bottom: BorderSide(color: Colors.grey[300]!),
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                              columns: const [
                                DataColumn(label: Text("Désignation", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("État", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Date Début", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Date Fin", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                              ],
                              rows: snapshot.data!.asMap().entries.map((entry) {
                                int index = entry.key;
                                var item = entry.value;
                                return DataRow(
                                  color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255)),
                                  cells: [
                                    DataCell(Text(item['designationEspace']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                                    DataCell(
                                      Text(
                                        item['nouveauStatut']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataCell(Text(item['DateDebut']?.toString() ?? '')),
                                    DataCell(Text(item['DateFin']?.toString() ?? '')),
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