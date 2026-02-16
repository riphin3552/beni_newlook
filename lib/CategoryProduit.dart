import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Categoryproduit extends StatefulWidget {
  final int identreprise;

  const Categoryproduit({super.key, required this.identreprise});

  @override
  State<Categoryproduit> createState() => _CategoryproduitState();
}

class _CategoryproduitState extends State<Categoryproduit> {
  final _formKey = GlobalKey<FormState>();
  final _designationCategController = TextEditingController();
  final _descriptionCategController = TextEditingController();
  int? selectedTypeProduit; // variable pour stocker le type de produit sélectionné
  List<Map<String, dynamic>> typeProduits = []; // liste pour stocker les types de produits

  late List<Map<String, dynamic>> categories = [];
  late Future<List<dynamic>> categoriesFuture;



  @override
  void initState() {
    super.initState();
    fetchTypeProduits();
    categoriesFuture = fetchCategoriesProduits(widget.identreprise);

  }

  void resetFields() {
    _designationCategController.clear();
    _descriptionCategController.clear();
    selectedTypeProduit = null;
  }

  

  Future<void> fetchTypeProduits() async {
    // logique pour récupérer les types de produits depuis l'API 
    
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/Get_TypeProduit.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          typeProduits=List<Map<String, dynamic>>.from(data);
        });
        //print(typeProduits);
      }
   
  }


  Future<void> addCategoryProduit() async {
    // logique d'ajout de catégorie de produit

    try{
        var url=Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AddCategoryProduit.php");
        var response=await http.post(
        url,
        headers:{'Content-Type':'application/json'},
        body: json.encode({
          "designation":_designationCategController.text,
          "description":_descriptionCategController.text,
          "typeproduit": selectedTypeProduit,
          "entreprise": widget.identreprise,
        })

      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse['error'] == null) {
            // ✅ Appelle le dialogue dans un délai pour éviter les conflits
            Future.delayed(Duration.zero, () {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
                    title: Text('Succès'),
                    content: Text('Catégorie ajoutée avec succès'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                      ),
                    ],
                  ),
                );
                resetFields(); // Réinitialise les champs après l'enregistrement
                setState(() {
                  categoriesFuture = fetchCategoriesProduits(widget.identreprise);
                });
              }
            });
        } else {
            if (mounted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
                      title: Text('Erreur'),
                      content: Text("Échec d'enregistrement: ${jsonResponse['error']}"),
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
        }
    } catch (e) {
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


// afficher les catégories de produits existantes
Future<List<dynamic>> fetchCategoriesProduits(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherCategoryProduit.php");
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catégorie de produit'),
        backgroundColor: Color.fromARGB(255, 121, 169, 240),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
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
                        "Ajouter une Catégorie",
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
                              controller: _designationCategController,
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
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la désignation' : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionCategController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.description, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la description' : null,
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Type de produit',
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
                              items: typeProduits.map((type) {
                                return DropdownMenuItem<int>(
                                  value: type['Id_typeProduit'],
                                  child: Text(type['designationType']),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedTypeProduit = newValue;
                                });
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un type' : null,
                            ),
                            SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  addCategoryProduit();
                                }
                              },
                              icon: Icon(Icons.check),
                              label: Text('Enregistrer', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600)),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 121, 169, 240))));
                  } else if (snapshot.hasError) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(padding: EdgeInsets.all(20), child: Text("Erreur: ${snapshot.error}", style: TextStyle(color: Colors.red))),
                    );
                  } else {
                    final categories = snapshot.data ?? [];
                    if (categories.isEmpty) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: Text("Aucune catégorie trouvée", style: TextStyle(color: Colors.grey[600]))),
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                            headingRowHeight: 56,
                            // ignore: deprecated_member_use
                            dataRowHeight: 48,
                            border: TableBorder(
                              horizontalInside: BorderSide(color: Colors.grey[300]!),
                              bottom: BorderSide(color: Colors.grey[300]!),
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                            columns: const [
                              DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                              DataColumn(label: Text("Désignation", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                              DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                              DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            ],
                            rows: categories.map((categ) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(categ['idCategorie'].toString())),
                                  DataCell(Text(categ['designationCategorie'] ?? "")),
                                  DataCell(Text(categ['descriptionCategorie'] ?? "")),
                                  DataCell(Text(categ['designationType'] ?? "")),
                                ],
                              );
                            }).toList(),
                          ),
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