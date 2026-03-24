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
  final bool _isLoading = false;
  int? idEtatSelected;
  int? idTypeEspaceSelected;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _designationEspaceController = TextEditingController();
  final TextEditingController _prixEspaceController = TextEditingController();
  final TextEditingController _equipementEspaceController = TextEditingController();
  final TextEditingController _capaciteEspaceController = TextEditingController();



    @override
  void initState() {
    super.initState();
    fetchEtats();
    fetchTypesEspace();
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
            const SizedBox(height: 16),
            // Formulaire d'ajout d'un espace de chambre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      value: idEtatSelected,
                      onChanged: (value) {
                        setState(() {
                          idTypeEspaceSelected = value;
                        });
                      },
                      items: typesEspace_chambre.map((espaceChambre) {
                        return DropdownMenuItem<int>(
                          value: espaceChambre['IdSectionAuxi'], // Assurez-vous que 'id' correspond à la clé de l'identifiant dans votre API
                          child: Text(espaceChambre['designationSectionAuxi']), // Affichez la désignation de l'état
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une désignation';
                        }
                        return null;
                      },
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
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
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
                          value: etat['idEtat'], // Assurez-vous que 'id' correspond à la clé de l'identifiant dans votre API
                          child: Text(etat['libelle']), // Affichez la désignation de l'état
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
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une capacité';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre entier valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
      ]
      ),
    )
    );
  }

}

              