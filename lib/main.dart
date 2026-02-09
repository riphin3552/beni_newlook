// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'dart:convert';


import 'package:beni_newlook/CategoryProduit.dart';
import 'package:beni_newlook/IdentificationProduit.dart';
import 'package:beni_newlook/TypesStock.dart';
import 'package:beni_newlook/pages/TypeProduit.dart';
import 'package:beni_newlook/pages/Utilisateurs.dart';
import 'package:beni_newlook/pages/entreprise.dart';
import 'package:beni_newlook/pages/login.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';


import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp(titre: "G-Newlook"));
  doWhenWindowReady(() {
    const initialSize = Size(600, 600);
    appWindow.minSize = const Size(400, 300); // taille minimale de la fenêtre
    appWindow.size = initialSize; // taille initiale de la fenêtre
    appWindow.alignment = Alignment.center; // centre la fenêtre
    appWindow.title = "G-HOTEL"; // titre de la fenêtre

    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  final String titre;
  

  const MyApp({super.key, required this.titre});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: titre,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const Login(),
    );
  }
}

class MainMenu extends StatefulWidget {
  final int identreprise;
  const MainMenu({super.key, required this.identreprise});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  String username = 'Utilisateur';
  String entrepriseName= 'Chargement...';
  int idEntreprise = 0;
  
  late String currentDate;
  late Timer _timer;


  @override
  void initState() {
    super.initState();

    // 👇 Maximiser la fenêtre principale
  Future.delayed(Duration.zero, () {
    appWindow.maximize();
  });



    // initialise la date
    currentDate = _getCurrentDate();
    // met à jour chaque seconde
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        currentDate = _getCurrentDate();
      });
    });
    loadUserName();

  }

  @override
  void dispose() {
    _timer.cancel(); // arrête le timer quand on quitte la page
    super.dispose();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
  }

  // Pages affichées selon l'index
  Widget _widgetOptions(int index) {
    switch (index) {
      case 0:
        return const _Page(title: 'Accueil');
      case 1:
        return StockMenu(titreGestionStockMenu: 'Gestion du stock', identreprise: widget.identreprise); // contenu menu gestion stock
      case 2:
        return const _Page(title: 'Logements');
      case 3:
        return const _Page(title: 'Caisse');
      case 4:
        return const _Page(title: 'Facturation');
      case 5:
        return const _Page(title: 'Commandes');
      case 6:
        return const _Page(title: 'Ressources humaines');
      case 7:
        return const _Page(title: 'Équipements');
      case 8:
        return const _Page(title: 'Fournisseurs');
      case 9:
        return const _Page(title: 'Rapports');
      case 10:
        return  ParametresMenu(titreMenuParametres: 'Paramètres',identreprise: widget.identreprise);
      default:
        return const _Page(title: 'Accueil');
    }
  }


  // charger le token depuis le shared preferences

  void loadUserName() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';


    final response = await http.get(
      Uri.parse('https://riphin-salemanager.com/beni_newlook_API/NLvalidate_Token.php'),
      headers: {
        'Authorization': token, // 👈 envoie le token brut
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));


    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (data['user']['Nom_utilisateur'] != null) {
        setState(() {
          username = data['user']['Nom_utilisateur'] ?? 'Utilisateur'; // valeur par défaut si null
          idEntreprise = data['user']['entreprise']; // recuperation de l'id de l'entreprise
        });

        selectEntrepriseName(idEntreprise); // appel de la fonction pour selectionner le nom de l'entreprise
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des informations utilisateur')),
        );

      }
    } else {
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur serveur: ${response.statusCode}')),
      );
    }
  }



  // fonction pour selectionner le nom de l'entreprise
  Future<void> selectEntrepriseName(
    int entrepriseId
  ) async {

    var url = Uri.parse('https://riphin-salemanager.com/beni_newlook_API/Getname_Ese.php');
    var response = await http.post(url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'ID_entreprise': idEntreprise,
    })
    ).timeout(const Duration(seconds: 10));

    if (!mounted) return;

    if (response.statusCode == 200) {
        var data = json.decode(response.body);

      if (data['success']) {
        setState(() {
          entrepriseName = data['entreprise']?? 'Entreprise';
        });

      } else {
        // Échec de la récupération
        // ignore: duplicate_ignore
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Échec de la récupération du nom de l\'entreprise')),
        );
      }
    } else {
      // Erreur serveur
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur serveur: ${response.statusCode}')),
      );
    }
  }



    @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title:  Text(
          entrepriseName,
          style: TextStyle(color: Color.fromARGB(255, 236, 210, 210)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                currentDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // 👉 Barre latérale
                Container(
                  width: 260,
                  color: bgColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildMenuItem(Icons.home, "Accueil", 0),
                            _buildMenuItem(Icons.inventory_2, "Stock", 1),
                            _buildMenuItem(Icons.house, "Logements", 2),
                            _buildMenuItem(Icons.point_of_sale, "Caisse", 3),
                            _buildMenuItem(Icons.receipt_long, "Facturation", 4),
                            _buildMenuItem(Icons.shopping_cart, "Commandes", 5),
                            _buildMenuItem(Icons.people, "RH", 6),
                            _buildMenuItem(Icons.build, "Équipements", 7),
                            _buildMenuItem(Icons.local_shipping, "Fournisseurs", 8),
                            _buildMenuItem(Icons.bar_chart, "Rapports", 9),
                            _buildMenuItem(Icons.settings, "Paramètres", 10),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Color(0xFF0D47A1)),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(width: 1, thickness: 1),

                // 👉 Panneau principal
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _widgetOptions(_selectedIndex),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Fonction pour construire chaque ligne du menu
  Widget _buildMenuItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

}









// Page de contenu basique
class _Page extends StatelessWidget {
  final String title;
  const _Page({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Contenu…'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// contenu menu gestion stock
class StockMenu extends StatefulWidget {
  final String titreGestionStockMenu;
  final int identreprise;

  const StockMenu({
    super.key,
    required this.titreGestionStockMenu,
    required this.identreprise,
  });

  @override
  State<StockMenu> createState() => _StockMenuState();
}

class _StockMenuState extends State<StockMenu> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D47A1);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  // ignore: deprecated_member_use
                  color: primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titreGestionStockMenu,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez vos produits et stocks efficacement',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          
          // Content Grid
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.start,
                  children: [
                  _buildSmartCard(
                    context,
                    index: 0,
                    icon: Icons.category,
                    title: 'Types de Produits',
                    description: 'Créer et gérer',
                    color: Color(0xFF1976D2),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 500,
                              child: TypeProduit(
                                identreprise: widget.identreprise,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 1,
                    icon: Icons.list_rounded,
                    title: 'Catégories',
                    description: 'Organiser',
                    color: Color(0xFF388E3C),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 500,
                              child: Categoryproduit(
                                identreprise: widget.identreprise,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 2,
                    icon: Icons.article,
                    title: 'Identification',
                    description: 'Produits détaillés',
                    color: Color(0xFFF57C00),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 720,
                              height: 580,
                              child: Identificationproduit(
                                identreprise: widget.identreprise,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 3,
                    icon: Icons.storage,
                    title: 'Types de Stocks',
                    description: 'Configuration',
                    color: Color(0xFF7B1FA2),
                    onTap: () {
                      // code
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 500,
                              child: TypeStock(
                                identreprise: widget.identreprise,
                              ),
                            ),
                          );
                    },
                  );
                },
                  ),
                  _buildSmartCard(
                    context,
                    index: 4,
                    icon: Icons.input,
                    title: 'Entrées',
                    description: 'Stock entrant',
                    color: Color(0xFFD32F2F),
                    onTap: () {
                      // code
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 5,
                    icon: Icons.inventory,
                    title: 'Liste Produits',
                    description: 'Tous vos produits',
                    color: Color(0xFF0097A7),
                    onTap: () {
                      // code
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 6,
                    icon: Icons.warehouse,
                    title: 'Nos Stocks',
                    description: 'Quantités actuelles',
                    color: Color(0xFF00796B),
                    onTap: () {
                      // code
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 7,
                    icon: Icons.unarchive,
                    title: 'Mouvements',
                    description: 'Historique complet',
                    color: Color(0xFF5E35B1),
                    onTap: () {
                      // code
                    },
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: color.withOpacity(isHovered ? 0.25 : 0.08),
                blurRadius: isHovered ? 20 : 8,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
              // ignore: deprecated_member_use
              color: isHovered ? color.withOpacity(0.5) : Colors.grey[200]!,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Transform.scale(
            scale: isHovered ? 1.02 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Icon Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: color.withOpacity(isHovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: isHovered ? 44 : 38,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Title
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  
                  // Description
                  Flexible(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  if (isHovered) ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}





//contenu menu parametres

class ParametresMenu extends StatefulWidget {
  final String titreMenuParametres;
  final int identreprise;

  const ParametresMenu({
    super.key,
    required this.titreMenuParametres,
    required this.identreprise,
  });

  @override
  State<ParametresMenu> createState() => _ParametresMenuState();
}

class _ParametresMenuState extends State<ParametresMenu> {
  late Future<List<Map<String, dynamic>>> _futureUtilisateurs;

  @override
  void initState() {
    super.initState();
    _futureUtilisateurs = fetchUtilisateurs();
  }

  Future<List<Map<String, dynamic>>> fetchUtilisateurs() async {
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherUtilisateurs.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"entreprise": widget.identreprise}),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success']) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['erro'] ?? "Erreur inconnue");
      }
    } else {
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }

  Future<void> supprimerUtilisateur(int idUtilisateur) async {
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/DeleteUtilisateur.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"id": idUtilisateur}),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur supprimé avec succès")),
        );
        setState(() {
          _futureUtilisateurs = fetchUtilisateurs();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${data['error']}")),
        );
      }
    }
  }

  void modifierUtilisateur(Map<String, dynamic> user) {
    final TextEditingController nomController =
        TextEditingController(text: user['Nom_utilisateur']);
    final TextEditingController telController =
        TextEditingController(text: user['telephone']);
    final TextEditingController passwordController =
        TextEditingController(text: user['Motdepass']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: 400,
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Modifier Utilisateur",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: nomController,
                    decoration: const InputDecoration(labelText: "Nom"),
                  ),
                  TextField(
                    controller: telController,
                    decoration: const InputDecoration(labelText: "Téléphone"),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: "Mot de pass"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      var url = Uri.parse(
                          "https://riphin-salemanager.com/beni_newlook_API/ModifierUtilisateur.php");
                      var response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          "id": user['ID_utilisateur'],
                          "name": nomController.text,
                          "phone": telController.text,
                          "keypassword":passwordController.text
                        }),
                      );

                      if (response.statusCode == 200) {
                        var data = json.decode(response.body);
                        if (data['success']==true) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Utilisateur modifié avec succès")),
                          );
                          //print(user['ID_utilisateur']);
                          setState(() {
                            _futureUtilisateurs = fetchUtilisateurs();
                          });
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        } else {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erreur: ${data['error']}")),
                          );
                        }
                      }
                    },
                    child: const Text("Enregistrer"),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👇 Titre + IconButtons sur la même ligne
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.titreMenuParametres,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person, size: 30, color: Colors.blue),
                    tooltip: "Utilisateurs",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 500,
                              child: Utilisateurs(identreprise: widget.identreprise),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.house_sharp, size: 30, color: Colors.green),
                    tooltip: "Entreprise",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 500,
                              child: Entreprise(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureUtilisateurs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucun utilisateur trouvé"));
                  }

                  final utilisateurs = snapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                          headingRowHeight: 56,
                          dataRowHeight: 56,
                          columnSpacing: 16,
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                          columns: const [
                            DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Nom", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Mot de passe", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Téléphone", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Entreprise", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          ],
                          rows: utilisateurs.asMap().entries.map((entry) {
                            int index = entry.key;
                            dynamic user = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.all(
                                index.isEven ? Colors.white : Color.fromARGB(255, 245, 248, 255),
                              ),
                              cells: [
                                  DataCell(Text(user['ID_utilisateur'].toString())),
                                  DataCell(Text(user['Nom_utilisateur'] ?? '')),
                                  DataCell(Text(user['Motdepass'] ?? '')),
                                  DataCell(Text(user['telephone'] ?? '')),
                                  DataCell(Text(user['Denomination'] ?? '')),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () {
                                          modifierUtilisateur(user);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          supprimerUtilisateur(user['ID_utilisateur']);
                                        },
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}