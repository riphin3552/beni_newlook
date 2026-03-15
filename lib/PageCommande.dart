//modification au 14/05/2023
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class CommandePage extends StatefulWidget {
  final int idEntreprise;
  const CommandePage({super.key, required this.idEntreprise});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _produitController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _dateController = TextEditingController();

  // Déclare des contrôleurs pour les champs details produit (prix, stock, unité, seuil)
final TextEditingController prixController = TextEditingController();
final TextEditingController stockController = TextEditingController();
final TextEditingController uniteController = TextEditingController();
final TextEditingController seuilController = TextEditingController();

  List<Map<String, dynamic>> sections = [];
  DateTime? selectedDate;
  int? selectedClient;
  int? selectedSection;
  int? selectedProduit;
  int? selectedStockId;
  
  List<Map<String, dynamic>> stock= [];




  @override
  void initState() {
    super.initState();
    fetchSections();
  }


  // Exemple de produit trouvé (normalement tu récupères ça via ton API)
  Map<String, dynamic>? produitDetails;

  final List<Map<String, dynamic>> panier = [];

  Future<List<Map<String, dynamic>>> _suggestionProduits(String pattern) async {
  if (pattern.isEmpty || pattern.length < 2) return [];

  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/FetchProduit.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "produit": pattern,
      "entreprise": widget.idEntreprise.toString(),
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    if (data['success'] == true && data['produit'] != null) {
      final produits = data['produit'];

      // Si l’API renvoie une liste
      if (produits is List) {
        return produits.map<Map<String, dynamic>>((p) => {
          "id": p['id'], // ⚠️ c’est l’IdProduit que tu veux utiliser ensuite
          "designationProduit": p['designationProduit'],
        }).toList();
      }

      // Si l’API renvoie un seul objet
      else if (produits is Map) {
        return [
          {
            "id": produits['id'],
            "designationProduit": produits['designationProduit'],
          }
        ];
      }
    }
  }
  return [];
}



Future<Map<String, dynamic>> fetchProduitDansStock() async {
  final url = Uri.parse(
    "https://riphin-salemanager.com/beni_newlook_API/FetchProduit_inStock_F(X)ese_idprod_idsection.php",
  );

  final body = jsonEncode({
    "entreprise": widget.idEntreprise,
    "section": selectedSection,
    "produit": selectedProduit,
  });

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data["success"] == true && data["data"] != null) {
      final List produits = data["data"];

      if (produits.isNotEmpty) {
        final p = produits.first; // ⚠️ on prend le premier élément

        return {
          "IdStock": p['IdStock'],
          "designationStock": p['designationStock'],
          "IdProduit": p['IdProduit'],
          "designationProduit": p['designationProduit'],
          "PrixVente": int.tryParse(p['PrixVente'].toString()) ?? 0,
          "uniteMesure": p['uniteMesure'],
          "seuil_minimum": p['seuil_minimum'],
          "QuantiteDisponible": p['QuantiteDisponible'],
          "idSection": p['idSection'],
          "descptionSection": p['descptionSection'],
          "Id_Ese": p['Id_Ese'],
        };
      } else {
        throw Exception("Aucun produit trouvé dans le stock");
      }
    } else {
      throw Exception("Produit introuvable ou données invalides");
    }
  } else {
    throw Exception("Erreur serveur: ${response.statusCode}");
  }
}


    //ajouter au panier
   void _ajouterAuPanier(Map<String, dynamic> produitDetails) {
  if (produitDetails.isNotEmpty && _quantiteController.text.isNotEmpty) {
    final quantite = int.tryParse(_quantiteController.text);

    if (quantite == null || quantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer une quantité valide")),
      );
      return;
    }

    // Vérification du stock disponible
    if (quantite > (produitDetails["QuantiteDisponible"] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantité trop élevée par rapport au stock disponible")),
      );
      return;
    }

    // Vérifier si le produit existe déjà dans le panier
    final index = panier.indexWhere((item) => item["id"] == produitDetails["IdProduit"]);
    if (index != -1) {
      // Mettre à jour la quantité et recalculer le total
      panier[index]["quantite"] += quantite;
      panier[index]["prixTotal"] =
          panier[index]["quantite"] * panier[index]["prixUnitaire"];
    } else {
      // Ajouter un nouveau produit
      panier.add({
        "id": produitDetails["IdProduit"],
        "idStock": produitDetails["IdStock"],
        "idSection": produitDetails["idSection"],
        "produit": produitDetails["designationProduit"],
        "quantite": quantite,
        "prixUnitaire": produitDetails["PrixVente"],
        "prixTotal": quantite * (produitDetails["PrixVente"] ?? 0),
      });
    }

    setState(() {});
    _produitController.clear();
    _quantiteController.clear();
    
  }
}

  double get total {
    return panier.fold(0, (sum, item) => sum + (item["quantite"] * item["prixUnitaire"]));
  }


  //afficher sections commande
  Future<void> fetchSections() async {
     
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherSectionsPrincipales.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.idEntreprise,
        }),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body); // Assume API returns a list of sections
        setState(() {
          sections=List<Map<String, dynamic>>.from(data); // Convertir la liste dynamique en liste de maps
        });
        //print(produits);
      }
   
  }


  //afficher le stock sur base de la idsection, idproduit et Id_Ese
  Future<void> fetchProduitInStock() async {
  // Vérifie que les paramètres sont renseignés
  if (selectedSection == null || selectedClient== null) {
    debugPrint("⚠️ Données manquantes: un ou plusieurs paramètres sont null");
    setState(() {
      stock = [];
      selectedStockId = null;
    });
    return;
  }

  final url = Uri.parse(
    "https://riphin-salemanager.com/beni_newlook_API/FetchProduit_inStock_F(X)ese_idprod_idsection.php",
  );

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "section": selectedSection,
      "produit": selectedProduit,
      "entreprise": widget.idEntreprise,
    }),
  );

  if (response.statusCode == 200) {
    final dynamic data = jsonDecode(response.body);

    // Cas 1: réponse single produit -> liste d'enregistrements
    if (data is List) {
      // Exemple: [ { IdStock: .., ... }, {...} ]
      final List<Map<String, dynamic>> records = List<Map<String, dynamic>>.from(
        data.map((e) => Map<String, dynamic>.from(e)),
      );

      setState(() {
        stock = records;
        selectedStockId = records.isNotEmpty ? int.tryParse(records[0]['IdStock']?.toString() ?? '') : null;
      });
      return;
    }

    // Cas 2: réponse multi produits -> { "results": [ { "entreprise":..., "section":..., "produit":..., "data":[ ...records... ] }, ... ] }
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      final List<dynamic> results = data['results'];
      // Fusionner tous les enregistrements trouvés dans un seul tableau (volontairement)
      final List<Map<String, dynamic>> allRecords = [];

      for (final item in results) {
        if (item is Map<String, dynamic> && item.containsKey('data')) {
          final dataList = item['data'];
          if (dataList is List) {
            allRecords.addAll(List<Map<String, dynamic>>.from(
              dataList.map((r) => Map<String, dynamic>.from(r)),
            ));
          }
        }
      }

      setState(() {
        stock = allRecords;
        selectedStockId = allRecords.isNotEmpty ? int.tryParse(allRecords[0]['IdStock']?.toString() ?? '') : null;
      });
      return;
    }

    // Cas inattendu
    debugPrint("⚠️ Réponse inattendue: $data");
    setState(() {
      stock = [];
      selectedStockId = null;
    });
  } else {
    debugPrint("Erreur HTTP: ${response.statusCode}");
  }
}



//Enregistrer une commande 
Future<void> addCommande() async {
  var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/RegisterCommandeANDFacturer.php");

  // Calcul du total de la commande
  double total = panier.fold(0, (sum, item) => sum + (item["quantite"] * item["prixUnitaire"]));

  // Préparer la liste des détails
  List<Map<String, dynamic>> details = panier.map((item) => {
    "idProduit": item["id"],        // ✅ correspond à la clé du panier
    "idStock": item["idStock"],     // ✅ correspond à la clé du panier
    "idSection": item["idSection"], // ✅ correspond à la clé du panier
    "quantiteCommande": item["quantite"],
    "prixUnitaire": item["prixUnitaire"],
    "sousTotal": item["quantite"] * item["prixUnitaire"],
  }).toList();

  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "entreprise": widget.idEntreprise,
      "client": selectedClient,
      "datecommande": _dateController.text,
      "statutcommande": "Commandé",
      "prixtotal": total,
      "montantEntreeCaisse": total,
      "sourceMontant": selectedSection,
      "MotifsEnteeCaisse": "vente du jour",
      "dateEntreeCaisse": _dateController.text,
      "details": details // ⚠️ envoi du panier complet
    }),
  );

  if (response.statusCode == 200) {
    print("Réponse API: ${response.body}");
    print("le panier est: $details");
  } else {
    print("Erreur HTTP: ${response.statusCode}");
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commande"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
  children: [
    // Ligne 1 : Recherche client + Source commande
    Row(
      children: [
        Expanded(
          child: TypeAheadField<Map<String, dynamic>>(
            controller: _clientController,
            suggestionsCallback: (pattern) async {
              if (pattern.isEmpty || pattern.length < 2) return [];
              final response = await http.post(
                Uri.parse('https://riphin-salemanager.com/beni_newlook_API/FetchANDaddClient.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'client': pattern, 'entreprise': widget.idEntreprise}),
              );
              if (response.statusCode == 200) {
                final json = jsonDecode(response.body);
                if (json['client'] != null) {
                  return [
                    {
                      "client_id": json['client']['id'],
                      "client_name": json['client']['client_name'],
                      "Id_Ese": json['client']['Id_Ese'],
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
                labelText: 'Rechercher client',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez entrer un fournisseur'
                  : null,
            ),
            itemBuilder: (context, suggestion) => ListTile(
              title: Text(suggestion['client_name']),
            ),
            onSelected: (suggestion) {
              setState(() {
                _clientController.text = suggestion['client_name'];
                selectedClient = suggestion['client_id'];
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Source commande',
              prefixIcon: const Icon(Icons.inventory, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
            items: sections.map((produit) {
              return DropdownMenuItem<int>(
                value: produit['idSection'],
                child: Text(produit['descptionSection']),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedSection = newValue;
                
              });
              //declencher fetchStock
                if(selectedSection!=null && selectedProduit!=null ){
                  fetchProduitDansStock();
                }
              
            },
            validator: (value) =>
                value == null ? 'Veuillez sélectionner une section' : null,
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),

    // Ligne 2 : Choisir date + Recherche produit
    Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: _dateController,
        decoration: InputDecoration(
          labelText: 'Date commande',
          labelStyle: const TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
          prefixIcon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
          ),
        ),
        readOnly: true, // ⚠️ important pour éviter le clavier
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            String formattedDate =
                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
            setState(() {
              _dateController.text = formattedDate;
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer une date';
          }
          try {
            DateTime.parse(value);
            return null;
          } catch (e) {
            return 'Format invalide (YYYY-MM-DD)';
          }
        },
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: TypeAheadField<Map<String, dynamic>>(
  controller: _produitController,
  suggestionsCallback: _suggestionProduits,
  builder: (context, controller, focusNode) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    decoration: InputDecoration(
      labelText: "Rechercher produit",
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    ),
  ),
  itemBuilder: (context, suggestion) => ListTile(
    title: Text(suggestion["designationProduit"]),
  ),
  onSelected: (suggestion) async {
    // Stocker l'Id du produit sélectionné
    selectedProduit = int.parse(suggestion["id"].toString());

    // Charger les détails depuis le stock
    final produit = await fetchProduitDansStock();

    setState(() {
      produitDetails = produit; // ⚠️ Map<String, dynamic> avec les détails
      _produitController.text = produit["designationProduit"];
      prixController.text = produit["PrixVente"].toString();
      stockController.text = produit["QuantiteDisponible"].toString();
      uniteController.text = produit["uniteMesure"];
      seuilController.text = produit["seuil_minimum"].toString();
    });
  },
),
    ),
  ],
),


              
              const SizedBox(height: 16),

              // Détails produit
              if (produitDetails != null)
  Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Détails produit", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: prixController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Prix de vente",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  onChanged: (val) {
                    produitDetails!["PrixVente"] =
                        int.tryParse(val) ?? produitDetails!["PrixVente"];
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: stockController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Quantité disponible",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: uniteController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Unité de mesure",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: seuilController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Seuil minimum",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
              const SizedBox(height: 16),

              // Quantité
             Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: _quantiteController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Quantité à commander",
          prefixIcon: Icon(Icons.confirmation_num),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Veuillez entrer une quantité" : null,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: FilledButton.icon(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _ajouterAuPanier(produitDetails!);
          }
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text("Ajouter au panier"),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ),
  ],
),




              const SizedBox(height: 24),

              // Tableau panier
              const Text("Détails commande", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DataTable(
                columns: const [
                  
                  DataColumn(label: Text("Produit")),
                  DataColumn(label: Text("Quantité")),
                  DataColumn(label: Text("Prix unitaire")),
                  DataColumn(label: Text("Sous-total")),
                ],
                rows: panier.map((item) {
                  return DataRow(cells: [
                    
                    DataCell(Text(item["produit"])),
                    DataCell(Text(item["quantite"].toString())),
                    DataCell(Text("${item["prixUnitaire"]}")),
                    DataCell(Text("${item["quantite"] * item["prixUnitaire"]}")),
                  ]);
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Total
              Text("Total à payer TTC : $total",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Valider commande
              FilledButton(
                onPressed: () {
                  addCommande();

                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Valider commande et Facturer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}







