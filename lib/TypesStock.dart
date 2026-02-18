import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class TypeStock extends StatefulWidget {
  int identreprise;
  TypeStock({super.key, required this.identreprise});

  @override
  State<TypeStock> createState() => _TypeStockState();
}

class _TypeStockState extends State<TypeStock> {
  final _formKey = GlobalKey<FormState>();
  final _designationStockController = TextEditingController();
  final _descriptionStockController = TextEditingController();
  List<Map<String, dynamic>> produits = [];
  int? selectedProduit;
  late Future<List<dynamic>> typeStocksFuture;


  void resetFields() {
    _designationStockController.clear();
    _descriptionStockController.clear();
    selectedProduit = null;
  }

  @override
  void initState() {
    super.initState();
    fetchProduits();
    typeStocksFuture = fetchTypeStocks(widget.identreprise);
  }

  
  // Fonction pour récupérer les produits depuis l'API
  Future<void> fetchProduits() async {
    // logique pour récupérer les types de produits depuis l'API 
    
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/GetNameProduit.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          produits =List<Map<String, dynamic>>.from(data);
        });
        //print(produits);
      }
   
  }



  Future<void> addTypeStock(double quantite) async {
    // logique d'ajout de type de produit

    try{
        var url=Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AddTypeStock.php");
        var response=await http.post(
        url,
        headers:{'Content-Type':'application/json'},
        body: json.encode({
          "designation":_designationStockController.text,
          "description":_descriptionStockController.text,
          "produit":selectedProduit,
          "entreprise": widget.identreprise,
          "quantiteDisponible": quantite,
        })

      );

      if(response.statusCode==200){
        var data=json.decode(response.body);
        if(data['success']){
          // ignore: use_build_context_synchronously
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
                title: Text('Succès'),
                content: Text("Type de stock ajouté avec succès"),
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
          resetFields();
          setState(() {
            typeStocksFuture = fetchTypeStocks(widget.identreprise);
          });
        }else{
          // ignore: use_build_context_synchronously
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
                title: Text('Erreur'),
                content: Text("Erreur d'enregistrement: ${data['error']}"),
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


  // Afficher les types de stocks dans une DataTable
  Future<List<dynamic>> fetchTypeStocks(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherTypeStocks.php");
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
        title: Text('Type de Stock'),
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
                        "Ajouter un Type de Stock",
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
                              controller: _designationStockController,
                              decoration: InputDecoration(
                                labelText: 'Désignation stock',
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
                              controller: _descriptionStockController,
                              decoration: InputDecoration(
                                labelText: 'Description stock',
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
                                labelText: 'Produit associé',
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
                              items: produits.map((produit) {
                                return DropdownMenuItem<int>(
                                  value: produit['Idproduit'],
                                  child: Text(produit['designationProduit']),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedProduit = newValue;
                                });
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un produit' : null,
                            ),
                            SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  addTypeStock(0);
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
                future: typeStocksFuture,
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
                    final types = snapshot.data ?? [];
                    if (types.isEmpty) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: Text("Aucun type de stock trouvé", style: TextStyle(color: Colors.grey[600]))),
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: Card(
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
                            columns: const [
                             
                              DataColumn(label: Text("Désignation", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                              DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                              DataColumn(label: Text("Produit", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                              DataColumn(label: Text("Qté disponible", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            ],
                            rows: types.map((type) {
                              return DataRow(
                                cells: [
                                
                                  DataCell(Text(type['designationStock'] ?? "")),
                                  DataCell(Text(type['Description_stock'] ?? "")),
                                  DataCell(Text(type['designationProduit'] ?? "")),
                                  DataCell(Text(type['QuantiteDisponible'].toString())),
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