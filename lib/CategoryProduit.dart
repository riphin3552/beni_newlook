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



  @override
  void initState() {
    super.initState();
    fetchTypeProduits();

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text("Categorie du produit"),
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
                              Text("Ajouter une nouvelle catégorie ", style: TextStyle(fontWeight: FontWeight.bold),),
                              SizedBox(height: 20,),
                              TextFormField(
                                controller: _designationCategController,
                                decoration: InputDecoration(
                                  labelText: 'Designation',
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
                                controller: _descriptionCategController,
                                decoration: InputDecoration(
                                  labelText: 'Description',
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
                                  )
                                ),
                                items: typeProduits.map((type) {
                                  return DropdownMenuItem<int>(
                                    value: type['Id_typeProduit'], // Assurez-vous que 'id' correspond à l'identifiant du type de produit
                                    child: Text(type['designationType']), // Affichez la désignation du type de produit
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    selectedTypeProduit = newValue;
                                  });
                                },
                                ),
                              SizedBox(height: 16,),
                    
                              ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Traiter la connexion
                                  addCategoryProduit();
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