import 'dart:convert';

import 'package:beni_newlook/Rapports/FactureAutresServices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
//import 'package:shared_preferences/shared_preferences.dart';

class FactureAutreServices extends StatefulWidget {
  final int idEntreprise;
  const FactureAutreServices({super.key, required this.idEntreprise});

  @override
  State<FactureAutreServices> createState() => _FactureAutreServicesState();
}

class _FactureAutreServicesState extends State<FactureAutreServices> {
  final _formKey = GlobalKey<FormState>();
final TextEditingController _dateFacturationController = TextEditingController();
final TextEditingController _montantPayerController = TextEditingController();
final _clientController = TextEditingController();
DateTime? selectedDate;
int? selectedServiceId;
int? selectedClientId;
List<Map<String, dynamic>> services = [];
bool _isFormExpanded = true; // State to control form expansion
bool _isSubmitting = false;

late List<Map<String, dynamic>> facturesAutresServices = [];
late Future<List<dynamic>> facturesAutresServicesFuture;



  @override
  void initState() {
    super.initState();
    facturesAutresServicesFuture = fetchFacturationAutresServices(widget.idEntreprise);
    fetchSectionsauxriliaires(widget.idEntreprise);
  }

  //reset les champs du formulaire
  void resetForm() {
    _dateFacturationController.clear();
    _montantPayerController.clear();
    _clientController.clear();
    setState(() {
      selectedServiceId = null;
      selectedClientId = null;
    });
  }


Future<List<dynamic>> fetchFacturationAutresServices(int entrepriseId) async {
  
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherFacturationsautresService.php");
  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({"entreprise": entrepriseId}),
  );
  
  if (response.statusCode == 200) {
    var data = json.decode(response.body);

    // ⚠️ Ton API renvoie directement une liste
    if (data is List) {
      return data;
    } else {
      return [];
      
    }
    
  } else {
    throw Exception("Erreur serveur: ${response.statusCode}");
  }
}


//afficher autres services
Future<void> fetchSectionsauxriliaires(int entrepriseId) async {
     
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/displaySectionsAuxiCombobox.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": entrepriseId,
        }),
        ).timeout(const Duration(seconds: 10));
           

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body); // Assume API returns a list of sections
        setState(() {
          services=List<Map<String, dynamic>>.from(data); // Convertir la liste dynamique en liste de maps
        });
        //print(services);
      }
   
  }


  //enregistrer la facture
  Future<void> submitFacture() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/FacturationAutreServices.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "date": _dateFacturationController.text,
          "section": selectedServiceId,
          "montant": _montantPayerController.text,
          "client": selectedClientId,
          "entreprise": widget.idEntreprise,
        }),
      );

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (data['success']){
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Succès"),
                    content: const Text("La facture a été enregistrée avec succès."),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          
                          int? idFacture = data['idFacturationAutresServices'];

                          // 1. Récupérer les détails de la facture spécifique
                          final factureResponse = await http.post(
                            Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherFacturationsautresService.php"),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              "entreprise": widget.idEntreprise,
                              "idFacturationAutresServices": idFacture
                            }),
                          );
                          final List factureData = jsonDecode(factureResponse.body);

                          // 2. Récupérer les informations de l'entreprise
                          final entrepriseResponse = await http.post(
                            Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({"idEse": widget.idEntreprise}),
                          );
                          final entrepriseData = jsonDecode(entrepriseResponse.body)['data'];

                          if (factureData.isNotEmpty) {
                            await generateThermalFacturePDF(entrepriseData, factureData[0]);
                          }

                          resetForm();
                          setState(() {
                            facturesAutresServicesFuture = fetchFacturationAutresServices(widget.idEntreprise);
                          });
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                  
                },
              );
            }
            else {
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Erreur"),
                    content: Text(data['message'] ?? "Une erreur est survenue lors de l'enregistrement de la facture."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Erreur"),
                  content: Text("Une erreur est survenue lors de l'enregistrement de la facture. Code d'erreur: ${response.statusCode}"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
        }
      }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facturation Autres Services"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Wrap the form in an ExpansionTile
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ExpansionTile(
                initiallyExpanded: _isFormExpanded,
                collapsedBackgroundColor: const Color.fromARGB(255, 245, 248, 255),
                backgroundColor: Colors.white,
                title: const Row(
                  children: [
                    Icon(Icons.add_box, color: Color.fromARGB(255, 121, 169, 240)),
                    SizedBox(width: 12),
                    Text(
                      "Enregistrer une Facturation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color.fromARGB(255, 121, 169, 240),
                      ),
                    ),
                  ],
                ),
                onExpansionChanged: (bool expanded) {
                  setState(() => _isFormExpanded = expanded);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _dateFacturationController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date de Facturation",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              _dateFacturationController.text = "${picked.year}/${picked.month}/${picked.day}";
                            });
                          }
                        },
                        validator: (value) => value!.isEmpty ? "Veuillez sélectionner une date" : null,
                      ),
                      const SizedBox(height: 16),
                      TypeAheadField<Map<String, dynamic>>(
                        controller: _clientController,
                        suggestionsCallback: (pattern) async {
                          if (pattern.isEmpty || pattern.length < 2) return [];
                          final response = await http.post(
                            Uri.parse('https://riphin-salemanager.com/beni_newlook_API/FetchANDaddClient.php'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'client': pattern,
                              'entreprise': widget.idEntreprise
                            }),
                          );
                          if (response.statusCode == 200) {
                            final json = jsonDecode(response.body);
                            if (json['client'] != null) {
                              return [
                                {
                                  "client_id": json['client']['id'],
                                  "client_name": json['client']['client_name'],
                                }
                              ];
                            }
                          }
                          return [];
                        },
                        builder: (context, controller, focusNode) => TextFormField(
                          controller: _clientController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Rechercher client",
                            prefixIcon: const Icon(Icons.person_search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un client' : null,
                        ),
                        itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion['client_name'])),
                        onSelected: (suggestion) {
                          setState(() {
                            _clientController.text = suggestion['client_name'];
                            selectedClientId = suggestion['client_id'];
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Sélectionner un service",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.room_service),
                        ),
                        items: services.map((service) {
                          return DropdownMenuItem<int>(
                            value: service['IdSectionAuxi'], // Assurez-vous que 'id' correspond à la clé de l'identifiant du service
                            child: Text(service['designationSectionAuxi']), // Assurez-vous que 'nom' correspond à la clé du nom du service
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedServiceId = value;
                          });
                        },
                        validator: (value) => value == null ? "Veuillez sélectionner un service" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montantPayerController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Montant à Payer",
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value!.isEmpty ? "Veuillez entrer le montant à payer" : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : submitFacture,
                            icon: _isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle),
                            label: Text(_isSubmitting ? 'Traitement...' : 'Valider la Facturation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 121, 169, 240),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      const SizedBox(height: 16), 
                    ],
                  ),
                ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // --- Tableau des Facturations Autres Services ---
            FutureBuilder<List<dynamic>>(
              future: facturesAutresServicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 121, 169, 240))));
                } else if (snapshot.hasError) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Erreur: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red))),
                  );
                } else {
                  final factures = snapshot.data ?? [];
                  if (factures.isEmpty) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: Text("Aucune facturation trouvée",
                                style: TextStyle(color: Colors.grey))),
                      ),
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            const Color.fromARGB(255, 121, 169, 240)
                                .withOpacity(0.15)),
                        headingRowHeight: 56,
                        dataRowHeight: 48,
                        border: TableBorder(
                          horizontalInside:
                              BorderSide(color: Colors.grey[300]!),
                          bottom: BorderSide(color: Colors.grey[300]!),
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                        columns: const [
                          DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Client", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Service", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Montant", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                        ],
                        rows: factures.map((facture) {
                          return DataRow(
                            cells: [
                              DataCell(Text(facture['idFacturationAutresServices']?.toString() ?? "")),
                              DataCell(Text(facture['dateFacturation'] ?? "")),
                              DataCell(Text(facture['client_name'] ?? "")),
                              DataCell(Text(facture['designationSectionAuxi'] ?? "")),
                              DataCell(Text("${facture['MontantPayer'] ?? "0"} \$")),
                            ],
                          );
                        }).toList(),
                      ),
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