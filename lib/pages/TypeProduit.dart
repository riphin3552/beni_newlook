import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TypeProduit extends StatefulWidget {
  final int identreprise;
  const TypeProduit({super.key, required this.identreprise});

  @override
  State<TypeProduit> createState() => _TypeProduitState();
}

class _TypeProduitState extends State<TypeProduit> {
  final _formKey = GlobalKey<FormState>();
  final _designationController = TextEditingController();
  final _descriptionController = TextEditingController();
  late Future<List<dynamic>> typeProduitsFuture; 
  
  @override void initState() { 
    super.initState();
   typeProduitsFuture = fetchTypeProduits(widget.identreprise);
    }



void resetFields() {
    _designationController.clear();
    _descriptionController.clear();
  }


  Future<void> addTypeProduit() async {
    // logique d'ajout de type de produit

    try{
        var url=Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AddTypeProduit.php");
        var response=await http.post(
        url,
        headers:{'Content-Type':'application/json'},
        body: json.encode({
          "designation":_designationController.text,
          "description":_descriptionController.text,
          "entreprise": widget.identreprise,
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
                content: Text("Type de produit ajouté avec succès"),
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
            typeProduitsFuture = fetchTypeProduits(widget.identreprise);
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

  //Afficher les types de produits
  Future<List<dynamic>> fetchTypeProduits(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherTypeProduits.php");
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
        title: Text('Type de produit'),
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
                        "Ajouter un Type",
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
                              controller: _designationController,
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
                              controller: _descriptionController,
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
                            SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  addTypeProduit();
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
                future: typeProduitsFuture,
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
                          child: Center(child: Text("Aucun type de produit trouvé", style: TextStyle(color: Colors.grey[600]))),
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
                            ],
                            rows: types.map((type) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(type['Id_typeProduit'].toString())),
                                  DataCell(Text(type['designationType'] ?? "")),
                                  DataCell(Text(type['descriptiontype'] ?? "")),
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