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


  void resetFields() {
    _designationStockController.clear();
    _descriptionStockController.clear();
  }



  Future<void> addTypeStock() async {
    // logique d'ajout de type de produit

    try{
        var url=Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AddTypeStock.php");
        var response=await http.post(
        url,
        headers:{'Content-Type':'application/json'},
        body: json.encode({
          "designation":_designationStockController.text,
          "description":_descriptionStockController.text,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Type de Stock'),
      ),

      body: 
                 
            Container(
              color: const Color.fromARGB(255, 211, 225, 247),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          color: Colors.white,
                          child: Padding(padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text("Nouveau type de stock", style: TextStyle(fontSize: 20),),
                              SizedBox(height: 20,),
                              TextFormField(
                                controller: _designationStockController,
                                decoration: InputDecoration(
                                  labelText: 'Designation stock',
                                  labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                  hintText: 'Designation',
                                  prefixIcon: Icon(Icons.category_outlined, color: Color.fromARGB(255, 121, 169, 240)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if(value==null || value.isEmpty){
                                    return 'veuillez entrer la designation';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16,),

                              TextFormField(
                                controller: _descriptionStockController,
                                decoration: InputDecoration(
                                  labelText: 'Description stock',
                                  labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                  hintText: 'Description',
                                  prefixIcon: Icon(Icons.description_outlined, color: Color.fromARGB(255, 121, 169, 240)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if(value==null || value.isEmpty){
                                    return 'veuillez entrer la description';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16,),
                    
                              
                    
                              ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Traiter la connexion
                                  addTypeStock();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 121, 169, 240),
                                // Utilise double.infinity pour que le bouton prenne la largeur maximale disponible
                                  minimumSize: Size(double.infinity, 50),
                                ),
                              child: Text('Ajouter', style: TextStyle(fontSize: 12.0,color: Colors.white),
                            ),
                        )
                    
                            ],
                          )
                          
                          ),
                          
                        )
                      ],
                    ),
                  )
                ),
              )
            )
    );
  }
}