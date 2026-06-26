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
    //print("Response API: $data"); // Debug: afficher la réponse complète
    //print("datecommande envoyée: ${_dateController.text}"); // Debug: vérifier la date envoyée
    if (data['success']) {
      final pageContext = context; // contexte parent stable
      // ignore: use_build_context_synchronously
      showDialog(context: pageContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Succès"),
          content: const Text("La commande a été enregistrée et facturée avec succès!"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                int? idcommande = data['idCommande'];
                final factureResponse=await http.post(
                  Uri.parse("https://riphin-salemanager.com/beni_newlook_API/facture.php"),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "entreprise": widget.idEntreprise,
                    "idCommande": idcommande}),
                );
                final factureData=jsonDecode(factureResponse.body);
                if(factureData['success'] && factureData['data'] != null){
                  final entrepriseResponse=await http.post(
                    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({"idEse": widget.idEntreprise}),
                  );
                  final entrepriseData=jsonDecode(entrepriseResponse.body)['data'];
                  if (pageContext.mounted) {
                    Navigator.push(
                      pageContext,
                      MaterialPageRoute(
                        builder: (context) => FacturePreviewPage(
                          entreprise: entrepriseData,
                          facture: factureData['data'],
                        ),
                      ),
                    );
                  }
                }else{
                  if (pageContext.mounted) {
                    showDialog(context: pageContext,
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




  static const Color _primary   = Color(0xFF0D47A1);
  static const Color _accent    = Color(0xFF1976D2);
  static const Color _bgLight   = Color(0xFFF5F8FF);
  static const Color _green     = Color(0xFF388E3C);

  InputDecoration _inputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _accent),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionHeader(String numero, String titre, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(numero,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(titre,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _styledCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text('Nouvelle Commande',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('1', 'Informations générales', Icons.info_outline, _accent),
              _buildInformationsGeneralesCard(),
              const SizedBox(height: 22),
              _sectionHeader('2', 'Sélection du produit', Icons.inventory_2_outlined, const Color(0xFF7B1FA2)),
              _buildDetailsProduitCard(),
              const SizedBox(height: 22),
              _sectionHeader('3', 'Panier de commande', Icons.shopping_cart_outlined, _green),
              _buildCartCard(),
              const SizedBox(height: 22),
              _buildTotalAndValidateSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationsGeneralesCard() {
    return _styledCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      return [{
                        "client_id": json['client']['id'],
                        "client_name": json['client']['client_name'],
                        "Id_Ese": json['client']['Id_Ese'],
                      }];
                    }
                  }
                  return [];
                },
                builder: (context, controller, focusNode) => TextFormField(
                  controller: _clientController,
                  focusNode: focusNode,
                  decoration: _inputDecoration(labelText: 'Rechercher client', icon: Icons.person_search_outlined),
                  validator: (v) => v == null || v.isEmpty ? 'Veuillez entrer un client' : null,
                ),
                itemBuilder: (context, s) => ListTile(
                  leading: const Icon(Icons.person, color: _accent),
                  title: Text(s['client_name']),
                ),
                onSelected: (s) => setState(() {
                  _clientController.text = s['client_name'];
                  selectedClient = s['client_id'];
                }),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: _inputDecoration(labelText: 'Source / Section', icon: Icons.storefront_outlined),
                items: sections.map((s) => DropdownMenuItem<int>(
                  value: s['idSection'],
                  child: Text(s['descptionSection']),
                )).toList(),
                onChanged: (v) {
                  setState(() => selectedSection = v);
                  if (selectedSection != null && selectedProduit != null) fetchProduitDansStock();
                },
                validator: (v) => v == null ? 'Veuillez sélectionner une section' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsProduitCard() {
    return _styledCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypeAheadField<Map<String, dynamic>>(
              key: UniqueKey(),
              controller: _produitController,
              suggestionsCallback: _suggestionProduits,
              builder: (context, controller, focusNode) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: _inputDecoration(labelText: 'Rechercher un produit', icon: Icons.search),
              ),
              itemBuilder: (context, s) => ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF7B1FA2)),
                title: Text(s['designationProduit']),
              ),
              onSelected: (s) async {
                selectedProduit = int.parse(s['id'].toString());
                final produit = await fetchProduitDansStock();
                setState(() {
                  produitDetails = produit;
                  _produitController.text = produit['designationProduit'];
                  prixController.text = produit['PrixVente'].toString();
                  stockController.text = produit['QuantiteDisponible'].toString();
                  uniteController.text = produit['uniteMesure'];
                  seuilController.text = produit['seuil_minimum'].toString();
                });
              },
            ),

            if (produitDetails != null) ...[
              const SizedBox(height: 16),
              // Fiche produit compacte
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF7B1FA2), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _infoChip(Icons.attach_money, 'Prix', '${produitDetails!["PrixVente"]} CDF',
                              const Color(0xFF388E3C)),
                          _infoChip(Icons.inventory, 'Stock', stockController.text,
                              const Color(0xFF1976D2)),
                          _infoChip(Icons.square_foot, 'Unité', uniteController.text,
                              const Color(0xFFF57C00)),
                          _infoChip(Icons.warning_amber_rounded, 'Seuil', seuilController.text,
                              const Color(0xFFD32F2F)),
                        ],
                      ),
                    ),
                    // Champ prix modifiable
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: prixController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(labelText: 'Prix vente', icon: Icons.edit),
                        onChanged: (val) {
                          produitDetails!['PrixVente'] =
                              int.tryParse(val) ?? produitDetails!['PrixVente'];
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
                        labelText: 'Quantité à commander',
                        icon: Icons.production_quantity_limits),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Veuillez entrer une quantité' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (produitDetails != null) {
                          _ajouterAuPanier(produitDetails!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Veuillez sélectionner un produit d\'abord.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Ajouter au panier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
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

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text('$label: ', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildCartCard() {
    return _styledCard(
      child: Column(
        children: [
          // En-tête panier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(flex: 4,
                    child: Text('Produit',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _green, fontSize: 13))),
                Expanded(flex: 2,
                    child: Text('Qté',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, color: _green, fontSize: 13))),
                Expanded(flex: 3,
                    child: Text('Prix unit.',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w700, color: _green, fontSize: 13))),
                Expanded(flex: 3,
                    child: Text('Sous-total',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w700, color: _green, fontSize: 13))),
                const SizedBox(width: 44),
              ],
            ),
          ),
          const Divider(height: 1),

          if (panier.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('Le panier est vide',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: panier.length,
              separatorBuilder: (_, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = panier[index];
                final isEven = index.isEven;
                return Container(
                  color: isEven ? Colors.white : _bgLight,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(item['produit'],
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(item['quantite'].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: _accent)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('${item["prixUnitaire"]}',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${item["quantite"] * item["prixUnitaire"]}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: _green),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => setState(() => panier.removeAt(index)),
                          tooltip: 'Retirer',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTotalAndValidateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL À PAYER',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${total.toStringAsFixed(2)} CDF',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bouton valider
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 22),
          label: const Text('Valider la commande et Facturer',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          onPressed: panier.isEmpty
              ? null
              : () async {
                  await addCommande();
                  setState(() {
                    panier.clear();
                    _clientController.clear();
                    _produitController.clear();
                    _dateController.text = '';
                    produitDetails = null;
                    selectedClient = null;
                    selectedSection = null;
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
        ),
      ],
    );
  }
}
