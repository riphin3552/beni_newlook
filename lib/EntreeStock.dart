import 'dart:convert';

//import 'package:beni_newlook/Rapports/RapportEntrees.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
//import 'package:google_fonts/google_fonts.dart';






// ignore: must_be_immutable
class Entreestock extends StatefulWidget {
  int identreprise;
   Entreestock({super.key, required this.identreprise});

  @override
  State<Entreestock> createState() => _EntreestockState();
}

class _EntreestockState extends State<Entreestock> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> produits = [];
  int? selectedProduit;
  List<Map<String, dynamic>> typesStock = [];
  int? selectedTypeStock;
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixUnitaireController = TextEditingController();
  DateTime? selectedDate;
  final TextEditingController _dateController = TextEditingController();
  List <Map<String, dynamic>> fournisseurs = [];
  final TextEditingController _fournisseurController = TextEditingController();
  int? selectedFournisseur;
  final TextEditingController _searchProductController = TextEditingController();
  final TextEditingController _filterStartDateController = TextEditingController();
  final TextEditingController _filterEndDateController = TextEditingController();
  
  late Future<List<dynamic>> entreesFuture;



    @override
  void initState() {
    super.initState();
    fetchproduits();
    fetchTypesStock();
      entreesFuture = fetchEntreeProduits(widget.identreprise);
  }

   Future<void> fetchTypesStock() async {
    // logique pour récupérer les types de stock depuis l'API 
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherStocks.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.identreprise,
        }),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          typesStock=List<Map<String, dynamic>>.from(data);
        });
        //print(typesStock);
      }
   
  }

  Future<void> fetchproduits() async {
    // logique pour récupérer les types de produits depuis l'API 
    
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficheNamesProduits.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.identreprise,
        }),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          produits=List<Map<String, dynamic>>.from(data);
        });
        //print(produits);
      }
   
  }


// fonction pour ajouter une entrée en stock
Future<void> ajouterEntreeStock() async {
  try {
  final url = Uri.parse('https://riphin-salemanager.com/beni_newlook_API/EntreeProduit.php');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'idproduit': selectedProduit,
      'idstock': selectedTypeStock,
      'quantite': _quantiteController.text,
      'prixUnitaire': _prixUnitaireController.text,
      'date': _dateController.text,
      'fournisseur_id': selectedFournisseur,
      'entreprise': widget.identreprise,
    }),
  ).timeout(Duration(seconds: 10)); // Timeout after 10 seconds
   
   if(response.statusCode == 200){
    final json = jsonDecode(response.body);
    if(json['success']){
      // ✅ Appelle le dialogue dans un délai pour éviter les conflits
            Future.delayed(Duration.zero, () {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
                    title: Text('Succès'),
                    content: Text('Produit entré en stock avec succès !'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                      ),
                    ],
                  ),
                );
                setState(() {
                  selectedProduit = null;
                  selectedTypeStock = null;
                  _quantiteController.clear();
                  _prixUnitaireController.clear();
                  _dateController.clear();
                  _fournisseurController.clear();
                  selectedFournisseur = null;
                  entreesFuture = fetchEntreeProduits(widget.identreprise);
                }); // Réinitialise les champs après l'enregistrement
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
                      content: Text("Échec d'enregistrement: ${json['error']}"),
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
});
    }
  }

//Afficher liste des entrees en stock
// Future<List<dynamic>> fetchEntreeProduits(int entrepriseId) async {
//   var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherEntreeProduits.php");
//   var response = await http.post(
//     url,
//     headers: {'Content-Type': 'application/json'},
//     body: json.encode({"entreprise": entrepriseId}),
//   );

//   if (response.statusCode == 200) {
//     var data = json.decode(response.body);

//     // ⚠️ Ton API renvoie directement une liste
//     if (data is List) {
//       return data;
//     } else {
//       return [];
//     }
//   } else {
//     throw Exception("Erreur serveur: ${response.statusCode}");
//   }
// }


Future<List<Map<String, dynamic>>> fetchEntreeProduits(int entrepriseId) async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherEntreeProduits.php");
  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({"entreprise": entrepriseId}),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);

    // ⚠️ Ton API renvoie une liste d’objets JSON
    if (data is List) {
      // 👇 conversion explicite en List<Map<String, dynamic>>
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
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
        title: Text('Entrée en stock'),
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
                      Icon(Icons.playlist_add, color: Color.fromARGB(255, 121, 169, 240)),
                      SizedBox(width: 12),
                      Text(
                        "Ajouter une Entrée",
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
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Produit',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.inventory, color: Color.fromARGB(255, 121, 169, 240)),
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
                              onChanged: (newValue) {
                                setState(() {
                                  selectedProduit = newValue;
                                });
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un produit' : null,
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Type de stock',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.storage, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              items: typesStock.map((type) {
                                return DropdownMenuItem<int>(
                                  value: type['IdStock'],
                                  child: Text(type['designationStock']),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedTypeStock = newValue;
                                });
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un type de stock' : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _quantiteController,
                              decoration: InputDecoration(
                                labelText: 'Quantité',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.countertops, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une quantité' : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _prixUnitaireController,
                              decoration: InputDecoration(
                                labelText: 'Prix unitaire',
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
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un prix unitaire' : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'Date d\'entrée',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode());
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (pickedDate != null) {
                                  String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                  setState(() {
                                    _dateController.text = formattedDate;
                                  });
                                }
                              },
                              keyboardType: TextInputType.datetime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer une date d\'entrée';
                                }
                                try {
                                  DateTime.parse(value);
                                  return null;
                                } catch (e) {
                                  return 'Veuillez entrer une date valide (YYYY-MM-DD)';
                                }
                              },
                            ),
                            SizedBox(height: 20),
                            TypeAheadField<Map<String, dynamic>>(
                              controller: _fournisseurController,
                              suggestionsCallback: (pattern) async {
                                if (pattern.isEmpty || pattern.length < 2) return [];

                                final response = await http.post(
                                  Uri.parse('https://riphin-salemanager.com/beni_newlook_API/FetchANDaddFournisseur.php'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({'fournisseur': pattern, 'entreprise': widget.identreprise}),
                                );

                                if (response.statusCode == 200) {
                                  final json = jsonDecode(response.body);

                                  if (json['fournisseur'] != null) {
                                    return [
                                      {
                                        "fournisseur_id": json['fournisseur']['id'],
                                        "fournisseur_name": json['fournisseur']['fournisseur_name'],
                                        "Id_Ese": json['fournisseur']['Id_Ese'],
                                      }
                                    ];
                                  } else {
                                    return [];
                                  }
                                } else {
                                  return [];
                                }
                              },
                              builder: (context, controller, focusNode) => TextFormField(
                                controller: _fournisseurController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Rechercher fournisseur',
                                  labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                  prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 121, 169, 240)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un fournisseur' : null,
                              ),
                              itemBuilder: (context, suggestion) => ListTile(
                                title: Text(suggestion['fournisseur_name']),
                              ),
                              onSelected: (suggestion) {
                                setState(() {
                                  _fournisseurController.text = suggestion['fournisseur_name'];
                                  selectedFournisseur = suggestion['fournisseur_id'];
                                });
                              },
                            ),
                            SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ajouterEntreeStock();
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
            // Filtres de recherche
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TypeAheadField<Map<String, dynamic>>(
                          controller: _searchProductController,
                          suggestionsCallback: (pattern) {
                            return produits.where((prod) =>
                                prod['designationProduit'].toString().toLowerCase().contains(pattern.toLowerCase())
                            ).toList();
                          },
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Rechercher produit',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                isDense: true,
                              ),
                              onChanged: (value) => setState(() {}),
                            );
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion['designationProduit']),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              _searchProductController.text = suggestion['designationProduit'];
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _filterStartDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date début',
                            labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                            prefixIcon: Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            isDense: true,
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              setState(() {
                                _filterStartDateController.text = formattedDate;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _filterEndDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date fin',
                            labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                            prefixIcon: Icon(Icons.event, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            isDense: true,
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              setState(() {
                                _filterEndDateController.text = formattedDate;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async{
                          // Action d'impression
                          final entrees = await fetchEntreeProduits(widget.identreprise);
                          // ⚠️ Conversion explicite en List<Map<String, dynamic>>
                      
                          final entreesList=entrees.map((e)=> Map<String, dynamic>.from(e)).toList();
                          // 👉 Ouvrir la page de prévisualisation PDF
                            Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfPrevisualiserPage(
                                  idEse: widget.identreprise,
                                  entrees: entreesList,
                                ),
                              ),
                            );

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 121, 169, 240),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.all(14),
                        ),
                        child: Icon(Icons.print),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Affichage de la liste des entrées en stock
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchEntreeProduits(widget.identreprise),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 121, 169, 240)),
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
                            Expanded(
                              child: Text("Erreur: ${snapshot.error}",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    var entrees = snapshot.data ?? [];
                    
                    // Filtrage des données
                    var filteredEntrees = entrees.where((e) {
                      bool matchesProduct = _searchProductController.text.isEmpty ||
                          (e['designationProduit'] ?? "").toString().toLowerCase().contains(_searchProductController.text.toLowerCase());
                      bool matchesStartDate = _filterStartDateController.text.isEmpty ||
                          (e['DateEntree'] ?? "").compareTo(_filterStartDateController.text) >= 0;
                      bool matchesEndDate = _filterEndDateController.text.isEmpty ||
                          (e['DateEntree'] ?? "").compareTo(_filterEndDateController.text) <= 0;
                      return matchesProduct && matchesStartDate && matchesEndDate;
                    }).toList();

                    if (filteredEntrees.isEmpty) {
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
                                entrees.isEmpty ? "Aucune entrée en stock" : "Aucun résultat trouvé",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Utilisez le formulaire ci-dessus pour ajouter une entrée",
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
                          headingRowColor: WidgetStateProperty.all(
                              // ignore: deprecated_member_use
                              Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                          headingRowHeight: 56,
                          // ignore: deprecated_member_use
                          dataRowHeight: 48,
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                          columns: const [
                            
                            DataColumn(label: Text("Produit", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Quantité", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("PU", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Stock", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Fournisseur", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          ],
                          rows: List.generate(filteredEntrees.length, (index) {
                            final e = filteredEntrees[index];
                            return DataRow(
                              color: WidgetStateProperty.all(
                                index.isEven
                                    ? Colors.white
                                    : Color.fromARGB(255, 245, 248, 255),
                              ),
                              cells: [
                                
                                DataCell(Text(e['designationProduit'] ?? "", 
                                    style: TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(e['Quantite'].toString())),
                                DataCell(Text(e['prixUnitaire'].toString())),
                                DataCell(Text(e['DateEntree'] ?? "")),
                                DataCell(Text(e['designationStock'] ?? "")),
                                DataCell(Text(e['fournisseur_name'] ?? "")),
                                DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () {
                                          //modification 
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          //Suppression
                                        },
                                      ),
                                    ],
                                  ),),
                              ],
                            );
                          }),
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






// ------------------ Modèle Entreprise ------------------
class EntrepriseInfos {
  final String denomination;
  final String adresse;
  final String telephone;
  final String email;
  final String logoPath; // 👈 ajout du logo

  EntrepriseInfos({
    required this.denomination,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.logoPath,
  });

  factory EntrepriseInfos.fromJson(Map<String, dynamic> json) {
    return EntrepriseInfos(
      denomination: json['Denomination'],
      adresse: json['Adresse'],
      telephone: json['Telephone'],
      email: json['Email'],
      logoPath: json['logo_path'], // 👈 récupération du logo depuis l’API
    );
  }
}

// ------------------ Fonctions utilitaires ------------------

// Récupérer infos entreprise
Future<EntrepriseInfos> fetchEntreprise(int idEse) async {
  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"idEse": idEse}),
  );

  final data = jsonDecode(response.body);
  return EntrepriseInfos.fromJson(data['data']);
}

// Construire le PDF à partir des entrées
Future<pw.Document> buildPdf(int idEse, List<Map<String, dynamic>> entrees) async {
  // Charger Roboto 
final fontRegular = pw.Font.ttf(await rootBundle.load("assets/fonts/Roboto-Regular.ttf"));
final fontBold = pw.Font.ttf(await rootBundle.load("assets/fonts/Roboto-Bold.ttf"));

  final entreprise = await fetchEntreprise(idEse);

  final pdf = pw.Document();

  // Charger le logo depuis l’URL
  final logo = entreprise.logoPath.isNotEmpty ? await networkImage(entreprise.logoPath) : null;

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        // Entête entreprise avec logo
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(entreprise.denomination,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text("Adresse: ${entreprise.adresse}"),
                pw.Text("Téléphone: ${entreprise.telephone}"),
                pw.Text("Email: ${entreprise.email}"),
              ],
            ),
            if (logo != null)
              pw.Container(
                height: 60,
                width: 60,
                child: pw.Image(logo), // 👈 affichage du logo
              ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Titre centré et en gras
        pw.Center(
          child: pw.Text(
            "Rapport des Entrées en Stock",
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),

        // Tableau des entrées
        // ignore: deprecated_member_use
        pw.Table.fromTextArray(
          headers: [
            "Produit",
            "Quantité",
            "PU",
            "Date",
            "Stock",
            "Fournisseur",
          ],
          data: entrees.map((e) => [
            e['designationProduit'] ?? "",
            e['Quantite'].toString(),
            e['prixUnitaire'].toString(),
            e['DateEntree'] ?? "",
            e['designationStock'] ?? "",
            e['fournisseur_name'] ?? "",
          ]).toList(),
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
          cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9), // 👈 texte réduit
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
        ),
      ],
    ),
  );

  return pdf;
}

// ------------------ Page d’aperçu PDF ------------------
class PdfPrevisualiserPage extends StatelessWidget {
  final int idEse;
  final List<Map<String, dynamic>> entrees;

  const PdfPrevisualiserPage({super.key, required this.idEse, required this.entrees});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aperçu du rapport")),
      body: FutureBuilder<pw.Document>(
        future: buildPdf(idEse, entrees),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Aucun document généré"));
          }

          final pdf = snapshot.data!;
          return PdfPreview(
            build: (format) async => pdf.save(),
            allowPrinting: true,   // 👈 permet d’imprimer après aperçu
            allowSharing: true,    // 👈 permet de partager/exporter
          );
        },
      ),
    );
  }
}