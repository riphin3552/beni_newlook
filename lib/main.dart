import 'dart:convert';

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
  const MainMenu({super.key});

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
        return const _Page(title: 'Gestion du stock');
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
        return const _Page(title: 'Paramètres');
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
    'ID_entreprise': entrepriseId,
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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Échec de la récupération du nom de l\'entreprise')),
      );
    }
  } else {
    // Erreur serveur
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
                          _buildMenuItem(Icons.inventory_2, "Stock Stock", 1),
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