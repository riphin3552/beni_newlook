//modification au 14/05/2023
import 'dart:convert';

import 'package:beni_newlook/Rapports/Facture.dart';
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
    // if (quantite > (produitDetails["QuantiteDisponible"] ?? 0)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Quantité trop élevée par rapport au stock disponible")),
    //   );
    //   return;
    // }

    //verification de la quantité par rapport a l'unité de mesure
    if (produitDetails["uniteMesure"] != "Plat" && quantite > produitDetails["QuantiteDisponible"].toInt()) {
      
      if (quantite > (produitDetails["QuantiteDisponible"] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantité trop élevée par rapport au stock disponible")),
      );
      return;
    }
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
      "statutcommande": "Facturée",
      "prixtotal": total,
      "montantEntreeCaisse": total,
      "sourceMontant": selectedSection,
      "MotifsEnteeCaisse": "vente du jour",
      "dateEntreeCaisse": _dateController.text,
      "details": details // ⚠️ envoi du panier complet
    }),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    print("Response API: $data"); // Debug: afficher la réponse complète
    if (data['success']) {
      // ignore: use_build_context_synchronously
      showDialog(context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Succès"),
          content: const Text("La commande a été enregistrée et facturée avec succès!"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                int? idcommande = data['idCommande']; // Récupérer l'ID de la commande créée
                print("ID de la commande créée: $idcommande");
                //recuperer la facture et les details de la commande pour les afficher dans la page de facture
                final factureResponse=await http.post(
                  Uri.parse("https://riphin-salemanager.com/beni_newlook_API/facture.php"),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "entreprise": widget.idEntreprise,
                    "idCommande": idcommande}),
                );
                final factureData=jsonDecode(factureResponse.body);
                if(factureData['success'] && factureData['data'] != null){
                  // recupere infos entreprise
                  final entrepriseResponse=await http.post(
                    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({"idEse": widget.idEntreprise}),
                  );
                  final entrepriseData=jsonDecode(entrepriseResponse.body)['data'];
                    //generer le pdf thermiaque de la facture
                    await generateThermalFacturePDF(entrepriseData, factureData['data']);
                    print("FactureData utiliser pour le PDF: ${factureData['data']}"); // Debug: afficher les données de la facture
                }else{
                  //Gestion erreur si la fqcture non trouvable
                  showDialog(context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Erreur"),
                      content: Text("La facture de la commande n'a pas pu être récupérée: ${factureData['message']}"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  });
                }
                },
                  
              child: const Text("OK"),
            ),
          ],
        );
      });
    } else {
      // ignore: use_build_context_synchronously
      showDialog(context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Erreur"),
          content: Text("Échec de l'enregistrement de la commande: ${data['message']}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      });
    }
  } else {
    // ignore: use_build_context_synchronously
    showDialog(context: context, 
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Erreur"),
        content: Text("Erreur serveur: ${response.statusCode}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    });
  }
}




  InputDecoration _inputDecoration(
      {required String labelText, required IconData icon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle Commande", style: TextStyle(color: Colors.white)), centerTitle: true,
      backgroundColor:Color.fromARGB(255, 54, 67, 87)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("1. Informations générales"),
              _buildInformationsGeneralesCard(),
              const SizedBox(height: 24),
              _buildSectionTitle("2. Détails produit"),
              _buildDetailsProduitCard(),
              const SizedBox(height: 24),
              _buildSectionTitle("3. Panier"),
              _buildCartCard(),
              const SizedBox(height: 24),
              _buildTotalAndValidateSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationsGeneralesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TypeAheadField<Map<String, dynamic>>(
                    controller: _clientController,
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty || pattern.length < 2) return [];
                      final response = await http.post(
                        Uri.parse(
                            'https://riphin-salemanager.com/beni_newlook_API/FetchANDaddClient.php'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'client': pattern,
                          'entreprise': widget.idEntreprise
                        }),
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
                    builder: (context, controller, focusNode) =>
                        TextFormField(
                      controller: _clientController,
                      focusNode: focusNode,
                      decoration: _inputDecoration(
                          labelText: 'Rechercher client',
                          icon: Icons.person_search),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Veuillez entrer un client'
                          : null,
                    ),
                    itemBuilder: (context, suggestion) =>
                        ListTile(title: Text(suggestion['client_name'])),
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
                    decoration: _inputDecoration(
                        labelText: 'Source commande', icon: Icons.inventory_2),
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
                      if (selectedSection != null && selectedProduit != null) {
                        fetchProduitDansStock();
                      }
                    },
                    validator: (value) => value == null
                        ? 'Veuillez sélectionner une section'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: _inputDecoration(
                  labelText: 'Date commande', icon: Icons.calendar_today),
              readOnly: true,
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
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsProduitCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypeAheadField<Map<String, dynamic>>(
            key: UniqueKey(), // ✅ force rebuild après chaque commande
            controller: _produitController,
            suggestionsCallback: _suggestionProduits,
            builder: (context, controller, focusNode) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _inputDecoration(
                labelText: "Rechercher produit",
                icon: Icons.search,
              ),
            ),
            itemBuilder: (context, suggestion) =>
                ListTile(title: Text(suggestion["designationProduit"])),
            onSelected: (suggestion) async {
              selectedProduit = int.parse(suggestion["id"].toString());
              final produit = await fetchProduitDansStock();
              setState(() {
                produitDetails = produit;
                _produitController.text = produit["designationProduit"];
                prixController.text = produit["PrixVente"].toString();
                stockController.text = produit["QuantiteDisponible"].toString();
                uniteController.text = produit["uniteMesure"];
                seuilController.text = produit["seuil_minimum"].toString();
              });
            },
          ),

          if (produitDetails != null) ...[
            const SizedBox(height: 16),
            Text("Détails du produit",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: prixController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    labelText: "Prix de vente",
                    icon: Icons.attach_money,
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
                  decoration: _inputDecoration(
                    labelText: "Qte disponible",
                    icon: Icons.inventory,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: uniteController,
                  readOnly: true,
                  decoration: _inputDecoration(
                    labelText: "Unité",
                    icon: Icons.square_foot,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: seuilController,
                  readOnly: true,
                  decoration: _inputDecoration(
                    labelText: "Seuil minimum",
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ),
            ]),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    labelText: "Quantité à commander",
                    icon: Icons.production_quantity_limits,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Veuillez entrer une quantité"
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (produitDetails != null) {
                        _ajouterAuPanier(produitDetails!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Veuillez sélectionner un produit d'abord."),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Ajouter au panier"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildCartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text("Produit",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text("Quantité",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text("Prix Unitaire",
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text("Sous-total",
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 48), // Space for delete icon
              ],
            ),
            Divider(),
            if (panier.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Le panier est vide."),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: panier.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = panier[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 4, child: Text(item["produit"])),
                        Expanded(
                            flex: 2,
                            child: Text(item["quantite"].toString(),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 3,
                            child: Text("${item["prixUnitaire"]}",
                                textAlign: TextAlign.right)),
                        Expanded(
                            flex: 3,
                            child: Text(
                                "${item["quantite"] * item["prixUnitaire"]}",
                                textAlign: TextAlign.right)),
                        SizedBox(
                          width: 48,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                panier.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAndValidateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Total à payer TTC : $total F",
            textAlign: TextAlign.right,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text("Valider la commande et Facturer"),
          onPressed: ()  {
              addCommande();
              setState(() {
                panier.clear();
                _clientController.clear();
                _produitController.clear();
                _dateController.text = "";
                produitDetails = null;
                selectedClient = null;
                selectedSection = null;
              });
            
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
