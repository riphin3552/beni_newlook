import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Identificationproduit extends StatefulWidget {
  final int identreprise;
  const Identificationproduit({super.key, required this.identreprise});

  @override
  State<Identificationproduit> createState() => _IdentificationproduitState();
}

class _IdentificationproduitState extends State<Identificationproduit> {
  final _formKey = GlobalKey<FormState>();
  final _designationProduitController = TextEditingController();
  final _prixUnitaireVenteController = TextEditingController();
  final unitemesureController = TextEditingController();
  final _seuilAlerteController = TextEditingController();
  int? selectedCategoryProduit;
  List<Map<String, dynamic>> categoryProduits = [];
  late Future<List<dynamic>> produitsFuture; // Future pour stocker les produits
  


  // reset fields
  void resetFields(){
    _designationProduitController.clear();
    _prixUnitaireVenteController.clear();
    _seuilAlerteController.clear();
    selectedCategoryProduit=null;
  }

  @override
  void initState(){
    super.initState();
    resetFields();
    fetchCategoryProduits();
    produitsFuture = fetchProduits(widget.identreprise); // Charger les produits au démarrage
  }


  Future <void> fetchCategoryProduits() async {
    // logique pour récupérer les catégories de produits depuis l'API 
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/Get_CategoryProduit.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          categoryProduits=List<Map<String, dynamic>>.from(data);
        });
        //print(categoryProduits);
      }
  }

  //identifier nouveau produit
  Future<bool> identifyProduit() async {
  try {
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/IdentifierProduit.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "designation": _designationProduitController.text,
        "prixvente": _prixUnitaireVenteController.text,
        "unite": unitemesureController.text,
        "seuilalerte": _seuilAlerteController.text,
        "categorie": selectedCategoryProduit,
        "entreprise": widget.identreprise,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data['success'] == true) {
        if (mounted) {
          // ✅ Affiche un message de succès
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
                title: Text('Succès'),
                content: Text("Produit ajouté avec succès"),
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

          // ✅ Réinitialise les champs
          resetFields();

          // ✅ Rafraîchit la liste des produits
          setState(() {
            produitsFuture = fetchProduits(widget.identreprise);
          });
        }
        return true;
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
                title: Text('Erreur'),
                content: Text("Échec d'enregistrement: ${data['error']}"),
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
        return false;
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(Icons.warning_amber, color: Colors.orange, size: 48),
              title: Text('Erreur'),
              content: Text("Échec de la requête: ${response.statusCode}"),
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
      return false;
    }
  } catch (e) {
    if (!mounted) return false;
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
    return false;
  }
}


  // afficher la liste des produits
  Future<List<dynamic>> fetchProduits(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherProduits.php");
  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({"entreprise": entrepriseId}),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    if (data['success'] == true) {
      return data['data'];
    } else {
      return [];
    }
  } else {
    throw Exception("Erreur serveur: ${response.statusCode}");
  }
}



  
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Identification des Produits'),
      backgroundColor: Color.fromARGB(255, 121, 169, 240),
      elevation: 2,
      centerTitle: true,
    ),
    backgroundColor: const Color.fromARGB(255, 245, 248, 255),
    body: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16),
          // --- Formulaire repliable ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                initiallyExpanded: true,
                collapsedBackgroundColor: Color.fromARGB(255, 245, 248, 255),
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    Icon(Icons.add_box, color: Color.fromARGB(255, 121, 169, 240)),
                    SizedBox(width: 12),
                    Text(
                      "Ajouter un Produit",
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
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _designationProduitController,
                            decoration: InputDecoration(
                              labelText: 'Désignation',
                              labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                              prefixIcon: Icon(Icons.label, color: Color.fromARGB(255, 121, 169, 240)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer la désignation'
                                    : null,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _prixUnitaireVenteController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Prix Unitaire de Vente',
                              labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                              prefixIcon: Icon(Icons.attach_money, color: Color.fromARGB(255, 121, 169, 240)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer le prix'
                                    : null,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: unitemesureController,
                            decoration: InputDecoration(
                              labelText: 'Unité de Mesure',
                              labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                              prefixIcon: Icon(Icons.straighten, color: Color.fromARGB(255, 121, 169, 240)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer l\'unité'
                                    : null,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _seuilAlerteController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Seuil d\'Alerte',
                              labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                              prefixIcon: Icon(Icons.warning_amber, color: Color.fromARGB(255, 121, 169, 240)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Veuillez entrer le seuil'
                                    : null,
                          ),
                          SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Catégorie de Produit',
                              labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                              prefixIcon: Icon(Icons.category, color: Color.fromARGB(255, 121, 169, 240)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                              ),
                            ),
                            items: categoryProduits.map((categorie) {
                              return DropdownMenuItem<int>(
                                value: categorie['idCategorie'],
                                child: Text(categorie['designationCategorie']),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                selectedCategoryProduit = newValue;
                              });
                            },
                            validator: (value) =>
                                value == null
                                    ? 'Veuillez sélectionner une catégorie'
                                    : null,
                          ),
                          SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                var success = await identifyProduit();
                                if (success) {
                                  setState(() {
                                    produitsFuture = fetchProduits(widget.identreprise);
                                  });
                                }
                              }
                            },
                            icon: Icon(Icons.check),
                            label: Text('Ajouter le Produit', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 121, 169, 240),
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 54),
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

          SizedBox(height: 24),

          // --- Tableau des produits ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder(
              future: produitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
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
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 24),
                          SizedBox(width: 12),
                          Expanded(child: Text("Erreur: ${snapshot.error}", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  );
                } else {
                  final produits = snapshot.data as List<dynamic>;
                  if (produits.isEmpty) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                            SizedBox(height: 12),
                            Text(
                              "Aucun produit disponible",
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Utilisez le formulaire ci-dessus pour ajouter un produit",
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
                        // ignore: deprecated_member_use
                        headingRowColor: WidgetStateProperty.all(Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                        headingRowHeight: 56,
                        // ignore: deprecated_member_use
                        dataRowHeight: 48,
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey[300]!),
                          bottom: BorderSide(color: Colors.grey[300]!),
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                        columns: [
                          DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Désignation", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Prix", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Unité", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Seuil", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          DataColumn(label: Text("Catégorie", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                        ],
                        rows: produits.asMap().entries.map((entry) {
                          int index = entry.key;
                          dynamic prod = entry.value;
                          return DataRow(
                            color: WidgetStateProperty.all(
                              index.isEven ? Colors.white : Color.fromARGB(255, 245, 248, 255),
                            ),
                            cells: [
                              DataCell(Text(prod['Idproduit'].toString(), style: TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(prod['designationProduit'])),
                              DataCell(Text(prod['PrixVente'].toString())),
                              DataCell(Text(prod['uniteMesure'])),
                              DataCell(Text(prod['seuil_minimum'].toString())),
                              DataCell(Text(prod['designationCategorie'])),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    ),
  );
}
}