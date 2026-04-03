import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Chambreespace extends StatefulWidget {
  final int identreprise;
  const Chambreespace({super.key, required this.identreprise});

  @override
  State<Chambreespace> createState() => _ChambreespaceState();
}

class _ChambreespaceState extends State<Chambreespace> {
  List<Map<String, dynamic>> Etats = [];
  List<Map<String, dynamic>> typesEspace_chambre = [];
  bool _isLoading = false;
  int? idEtatSelected;
  int? idTypeEspaceSelected;
  final _formKey = GlobalKey<FormState>();
  late Future<List<dynamic>> _futureChambres;
  final TextEditingController _designationEspaceController = TextEditingController();
  final TextEditingController _prixEspaceController = TextEditingController();
  final TextEditingController _equipementEspaceController = TextEditingController();
  final TextEditingController _capaciteEspaceController = TextEditingController();

  



    @override
  void initState() {
    super.initState();
    fetchEtats();
    fetchTypesEspace();
    _futureChambres = fetchChambresEspaces(widget.identreprise);
  }

  void _refreshList() {
    setState(() {
      _futureChambres = fetchChambresEspaces(widget.identreprise);
    });
  }

void resetForm() {
    _formKey.currentState!.reset();
    _designationEspaceController.clear();
    _prixEspaceController.clear();
    _equipementEspaceController.clear();
    _capaciteEspaceController.clear();
    setState(() {
      idEtatSelected = null;
      idTypeEspaceSelected = null;
    });
  }


   //afficher les etats de chambre
  Future<void> fetchEtats() async {
     
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherEtats.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.identreprise,
        }),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body); // Assume API returns a list of sections
        setState(() {
          Etats=List<Map<String, dynamic>>.from(data); // Convertir la liste dynamique en liste de maps
        });
        //print(produits);
      }
   
  }


  //afficher les Sections auxiliaires de chambre ou types espace de chambre
  Future<void> fetchTypesEspace() async {
     
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherSectionsAuxi.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.identreprise,
        }),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body); // Assume API returns a list of sections
        setState(() {
          typesEspace_chambre=List<Map<String, dynamic>>.from(data); // Convertir la liste dynamique en liste de maps
        });
        //print(produits);
      }
   
  }

  // Ajouter un espace de chambre
  Future<void> addEspaceChambre() async {
    print(widget.identreprise);
    print(idTypeEspaceSelected);
    print(idEtatSelected);
   try { 
    setState(() {
      _isLoading = true;
    });
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AddEspaceChambre.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "idchambreespace": idTypeEspaceSelected,
        "designationChambreEspace": _designationEspaceController.text,
        "prixChambreEspace": _prixEspaceController.text,
        "equipementChambreEspace": _equipementEspaceController.text,
        "capaciteChambreEspace": _capaciteEspaceController.text,
        "idEtatChambreEspace": idEtatSelected,
        "entreprise": widget.identreprise,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _isLoading = false;
      });
      
      var responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
      // Succès
      showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
                title: Text('Succès'),
                content: Text("Chambre/Espace ajouté avec succès"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                  ),
                ],
              );
            },
          );
          resetForm();
          _refreshList();
         
        }else{
          // ignore: use_build_context_synchronously
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
                title: Text('Erreur'),
                content: Text("Erreur d'enregistrement: ${responseData['error']}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch(e){
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
            title: Text('Erreur de Connexion'),
            content: Text("Erreur de connexion: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
              ),
            ],
          );
        },
      );
    }
  }
    
  
  //Affichage liste des chambres/espaces
  Future<List<dynamic>> fetchChambresEspaces(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherChambreEspace.php");
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
        title: const Text('Espace de chambre'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Formulaire d'ajout d'un espace de chambre
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
                      Icon(Icons.add_box, color: Color.fromARGB(255, 121, 169, 240)),
                      SizedBox(width: 12),
                      Text(
                        "Ajouter une Chambre / Espace",
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Type d\'espace ou chambre',
                                border: OutlineInputBorder(),
                              ),
                              value: idTypeEspaceSelected,
                              onChanged: (value) {
                                setState(() {
                                  idTypeEspaceSelected = value;
                                });
                              },
                              items: typesEspace_chambre.map((espaceChambre) {
                                return DropdownMenuItem<int>(
                                  value: espaceChambre['IdSectionAuxi'],
                                  child: Text(espaceChambre['designationSectionAuxi']),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _designationEspaceController,
                              decoration: const InputDecoration(
                                labelText: 'Désignation de l\'espace',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une désignation' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _prixEspaceController,
                              decoration: const InputDecoration(
                                labelText: 'Prix de l\'espace',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Veuillez entrer un prix';
                                if (double.tryParse(value) == null) return 'Veuillez entrer un nombre valide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _equipementEspaceController,
                              decoration: const InputDecoration(
                                labelText: 'Équipements de l\'espace',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'État de l\'espace',
                                border: OutlineInputBorder(),
                              ),
                              value: idEtatSelected,
                              onChanged: (value) {
                                setState(() {
                                  idEtatSelected = value;
                                });
                              },
                              items: Etats.map((etat) {
                                return DropdownMenuItem<int>(
                                  value: etat['idEtat'],
                                  child: Text(etat['libelle']),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _capaciteEspaceController,
                              decoration: const InputDecoration(
                                labelText: 'Capacité de l\'espace',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Veuillez entrer une capacité';
                                if (int.tryParse(value) == null) return 'Veuillez entrer un nombre entier valide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () {
                                if (_formKey.currentState!.validate()) {
                                  addEspaceChambre();
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
            const SizedBox(height: 32),
            // --- Tableau des chambres et espaces ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _futureChambres,
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
                              "Aucune chambre ou espace trouvé",
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
                                // ignore: deprecated_member_use
                                dataRowHeight: 48,
                                horizontalMargin: 24,
                                border: TableBorder(
                                  horizontalInside: BorderSide(color: Colors.grey[300]!),
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                  top: BorderSide(color: Colors.grey[300]!),
                                ),
                                columns: const [
                                  DataColumn(label: Text("ID", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Catégorie", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Désignation", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Prix", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Equipements", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("État", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                ],
                                rows: snapshot.data!.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var item = entry.value;
                                  return DataRow(
                                    color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255)),
                                    cells: [
                                      DataCell(Text(item['IdEspace'].toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text(item['designationSectionAuxi']?.toString() ?? '')),
                                      DataCell(Text(item['designationEspace']?.toString() ?? '')),
                                      DataCell(Text("${item['PrixEspace']} \$")),
                                      DataCell(Text(item['Equipement']?.toString() ?? '')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item['libelle'] == "Disponible" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item['libelle']?.toString() ?? '',
                                            style: TextStyle(
                                              color: item['libelle'] == "Disponible" ? Colors.green : Colors.orange,
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

              