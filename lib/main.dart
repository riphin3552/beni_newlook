// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'dart:convert';


import 'package:beni_newlook/AutreSortieProduits.dart';
import 'package:beni_newlook/CategoryProduit.dart';
import 'package:beni_newlook/EntreeStock.dart';
import 'package:beni_newlook/IdentificationProduit.dart';
import 'package:beni_newlook/PageCommande.dart';
import 'package:beni_newlook/api_config.dart';
import 'package:beni_newlook/session_utilisateur.dart';
//import 'package:beni_newlook/PageCommande.dart';
import 'package:beni_newlook/Rapports/ListeProduits.dart';
import 'package:beni_newlook/TypesStock.dart';
import 'package:beni_newlook/pages/MenuLogement.dart';
import 'package:beni_newlook/pages/MenuCaisse.dart';
import 'package:beni_newlook/pages/MenuFacturation.dart';
import 'package:beni_newlook/pages/MenuRapports.dart';
import 'package:beni_newlook/pages/TypeProduit.dart';
import 'package:beni_newlook/pages/Utilisateurs.dart';
import 'package:beni_newlook/pages/bridgeSection.dart';
import 'package:beni_newlook/pages/entreprise.dart';
import 'package:beni_newlook/pages/login.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';


import 'package:shared_preferences/shared_preferences.dart';
import 'package:beni_newlook/Rapports/RapportStocks.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp(titre: "G-Newlook"));
  doWhenWindowReady(() {
    appWindow.title = "G-HOTEL";
    // Petite fenêtre centrée pour l'écran de connexion
    appWindow.size = const Size(460, 600);
    appWindow.alignment = Alignment.center;
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
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
  int idUtilisateur = 0;
  String role = 'Serveur';
  int? idSection;

  late String currentDate;
  late Timer _timer;


  @override
  void initState() {
    super.initState();

    // Maximiser et définir taille minimale pour l'app principale
    Future.delayed(Duration.zero, () {
      appWindow.minSize = const Size(1024, 600);
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
        return  MenuGestionlogement(titreMenuGestionLogement: "Logement", identreprise: widget.identreprise,); // contenu menu logement
      case 3:
        return MenuCaisse(titreMenuCaisse: 'Gestion de Caisse', identreprise: widget.identreprise, idUtilisateur: idUtilisateur,); // contenu menu caisse
      case 4:
        return Menufacturation(idEntreprise: widget.identreprise, titreMenuFacturation: 'Facturation'); // contenu menu facturation
      case 5:
        return CommandesMenu(titreMenuCommandes: 'Commande', identreprise: widget.identreprise); // contenu menu commandes
      case 6:
        return const _Page(title: 'Ressources humaines');
      case 7:
        return const _Page(title: 'Équipements');
      case 8:
        return const _Page(title: 'Fournisseurs');
      case 9:
        return MenuRapports(titreMenuRapports: 'Rapports', identreprise: widget.identreprise, idUtilisateur: idUtilisateur);
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

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/NLvalidate_Token.php'),
        headers: {
          'Authorization': token, // 👈 envoie le token brut
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      final data = json.decode(response.body);

      if (response.statusCode == 403) {
        // Compte desactive entre-temps par le Gerant : on force la deconnexion.
        await _forceLogout(data['message'] ?? 'Compte desactive');
        return;
      }

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['user']['Nom_utilisateur'] != null) {
          setState(() {

            username = data['user']['Nom_utilisateur'] ?? 'Utilisateur'; // valeur par défaut si null
            idEntreprise = data['user']['entreprise']; // recuperation de l'id de l'entreprise
            idUtilisateur = data['user']['ID_utilisateur']; // recuperation de l'id de l'utilisateur
            role = data['user']['role'] ?? 'Serveur';
            idSection = data['user']['idSection'];
          });

          SessionUtilisateur.token = token;
          SessionUtilisateur.idUtilisateur = idUtilisateur;
          SessionUtilisateur.idEntreprise = idEntreprise;
          SessionUtilisateur.nomUtilisateur = username;
          SessionUtilisateur.role = role;
          SessionUtilisateur.idSection = idSection;

          selectEntrepriseName(idEntreprise); // appel de la fonction pour selectionner le nom de l'entreprise
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors du chargement des informations utilisateur')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur serveur (${response.statusCode}): ${data['message'] ?? response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger le profil utilisateur : $e')),
      );
    }
  }

  // Deconnecte l'utilisateur (token invalide ou compte desactive) et revient a l'ecran de connexion.
  Future<void> _forceLogout(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    SessionUtilisateur.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }




  // fonction pour selectionner le nom de l'entreprise
  Future<void> selectEntrepriseName(
    int entrepriseId
  ) async {
    try {
      var url = Uri.parse('$apiBaseUrl/Getname_Ese.php');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Échec de la récupération du nom de l\'entreprise')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur serveur: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de récupérer le nom de l\'entreprise : $e')),
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
                          children: _buildMenuItemsPourRole(),
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
                            IconButton(
                              tooltip: 'Déconnexion',
                              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                              onPressed: () => _forceLogout('Vous êtes déconnecté(e).'),
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

  // Construit la liste des entrees du menu visibles selon le role de l'utilisateur connecte.
  // Regle : Gerant, Comptable et Caissier ont acces a tout le systeme (sauf Parametres,
  // reserve au Gerant seul). Le Serveur n'a acces qu'a Rapports (Fiche de Stock de sa
  // section, filtre cote serveur) et Facturation.
  List<Widget> _buildMenuItemsPourRole() {
    final bool accesComplet = role == 'Gerant' || role == 'Comptable' || role == 'Caissier';

    final items = <Widget>[
      _buildMenuItem(Icons.home, "Accueil", 0), // tous les roles
    ];

    if (accesComplet) {
      items.add(_buildMenuItem(Icons.inventory_2, "Stock", 1));
      items.add(_buildMenuItem(Icons.house, "Logements", 2));
      items.add(_buildMenuItem(Icons.point_of_sale, "Caisse", 3));
    }

    // Facturation : accessible a tous les roles, y compris Serveur
    items.add(_buildMenuItem(Icons.receipt_long, "Facturation", 4));

    if (accesComplet) {
      items.add(_buildMenuItem(Icons.shopping_cart, "Commandes", 5));
      items.add(_buildMenuItem(Icons.people, "RH", 6));
      items.add(_buildMenuItem(Icons.build, "Équipements", 7));
      items.add(_buildMenuItem(Icons.local_shipping, "Fournisseurs", 8));
    }

    // Rapports : tous les roles (le Serveur n'y voit que la Fiche de Stock de sa section)
    items.add(_buildMenuItem(Icons.bar_chart, "Rapports", 9));

    // Parametres (dont gestion des utilisateurs et entreprise) : Gerant uniquement
    if (role == 'Gerant') {
      items.add(_buildMenuItem(Icons.settings, "Paramètres", 10));
    }

    return items;
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
              child: SizedBox(
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
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => TypeProduit(
                          identreprise: widget.identreprise,
                        ),
                      ));
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
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => Categoryproduit(
                          identreprise: widget.identreprise,
                        ),
                      ));
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
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => Identificationproduit(
                          identreprise: widget.identreprise,
                        ),
                      ));
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
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => TypeStock(
                          identreprise: widget.identreprise,
                        ),
                      ));
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
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => Entreestock(
                          identreprise: widget.identreprise,
                        ),
                      ));
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewPAGE(idEse: widget.identreprise),
                        )
                        );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewPage(idEse: widget.identreprise),
                        )
                        );
                    },
                  ),
                  _buildSmartCard(
                    context,
                    index: 7,
                    icon: Icons.bar_chart,
                    title: 'SECTIONS',
                    description: 'sections principales',
                    color: Color(0xFF5E35B1),
                    onTap: () {
                      // code
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              width: 650,
                              height: 520,
                              child: BridgeSection(
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
                    index: 8,
                    icon: Icons.output,
                    title: 'Autres Sorties',
                    description: 'Cassées / Abîmées',
                    color: Color(0xFFE64A19),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => AutreSortieProduits(
                          identreprise: widget.identreprise,
                        ),
                      ));
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
  List<Map<String, dynamic>> _sectionsPourFormulaire = [];

  @override
  void initState() {
    super.initState();
    _futureUtilisateurs = fetchUtilisateurs();
    _fetchSectionsPourFormulaire();
  }

  Future<List<Map<String, dynamic>>> fetchUtilisateurs() async {
    var url = Uri.parse("$apiBaseUrl/AfficherUtilisateurs.php");
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionUtilisateur.token,
      },
      body: json.encode({}),
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

  Future<void> _fetchSectionsPourFormulaire() async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/AfficherSectionsPrincipales.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'entreprise': widget.identreprise}),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() => _sectionsPourFormulaire = List<Map<String, dynamic>>.from(data));
    }
  }

  Future<void> supprimerUtilisateur(int idUtilisateur) async {
    var url = Uri.parse("$apiBaseUrl/DeleteUtilisateur.php");
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionUtilisateur.token,
      },
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

  static const List<String> _rolesDisponibles = ['Gerant', 'Comptable', 'Caissier', 'Serveur'];

  Future<void> _envoyerModification(Map<String, dynamic> body) async {
    var url = Uri.parse("$apiBaseUrl/ModifierUtilisateur.php");
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionUtilisateur.token,
      },
      body: json.encode(body),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur modifié avec succès")),
        );
        setState(() => _futureUtilisateurs = fetchUtilisateurs());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${data['message'] ?? data['error']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur serveur: ${response.statusCode}")),
      );
    }
  }

  void _reinitialiserMotDePasse(int idUtilisateur) {
    final TextEditingController nouveauPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Réinitialiser le mot de passe"),
          content: TextField(
            controller: nouveauPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nouveauPasswordController.text.isEmpty) return;
                Navigator.pop(dialogContext);
                await _envoyerModification({
                  "id": idUtilisateur,
                  "keypassword": nouveauPasswordController.text,
                });
              },
              child: const Text("Réinitialiser"),
            ),
          ],
        );
      },
    );
  }

  void modifierUtilisateur(Map<String, dynamic> user) {
    final TextEditingController nomController =
        TextEditingController(text: user['Nom_utilisateur']);
    final TextEditingController telController =
        TextEditingController(text: user['telephone']);
    String selectedRole = user['role'] ?? 'Serveur';
    int? selectedSection = user['idSection'];
    bool actif = (user['actif'] ?? 1) == 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: SizedBox(
                width: 420,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Modifier Utilisateur",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nomController,
                        decoration: const InputDecoration(labelText: "Nom"),
                      ),
                      TextField(
                        controller: telController,
                        decoration: const InputDecoration(labelText: "Téléphone"),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: "Rôle"),
                        items: _rolesDisponibles
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setDialogState(() {
                          selectedRole = v ?? 'Serveur';
                          if (selectedRole == 'Gerant') selectedSection = null;
                        }),
                      ),
                      if (selectedRole != 'Gerant')
                        DropdownButtonFormField<int>(
                          initialValue: selectedSection,
                          decoration: const InputDecoration(labelText: "Section affectée"),
                          items: _sectionsPourFormulaire
                              .map((s) => DropdownMenuItem<int>(
                                    value: s['idSection'],
                                    child: Text(s['descptionSection']),
                                  ))
                              .toList(),
                          onChanged: (v) => setDialogState(() => selectedSection = v),
                        ),
                      SwitchListTile(
                        title: const Text("Compte actif"),
                        value: actif,
                        onChanged: (v) => setDialogState(() => actif = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.lock_reset, size: 18),
                        label: const Text("Réinitialiser le mot de passe"),
                        onPressed: () => _reinitialiserMotDePasse(user['ID_utilisateur']),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedRole != 'Gerant' && selectedSection == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Veuillez sélectionner une section")),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _envoyerModification({
                            "id": user['ID_utilisateur'],
                            "name": nomController.text,
                            "phone": telController.text,
                            "role": selectedRole,
                            "idSection": selectedRole == 'Gerant' ? null : selectedSection,
                            "actif": actif ? 1 : 0,
                          });
                        },
                        child: const Text("Enregistrer"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionUtilisateur.isGerant) {
      return const Center(
        child: Text("Accès réservé au Gérant.", style: TextStyle(color: Colors.grey)),
      );
    }
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
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => Utilisateurs(identreprise: widget.identreprise),
                      ));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.house_sharp, size: 30, color: Colors.green),
                    tooltip: "Entreprise",
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => Entreprise(),
                      ));
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
                          // ignore: deprecated_member_use
                          headingRowColor: WidgetStateProperty.all(Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                          headingRowHeight: 56,
                          // ignore: deprecated_member_use
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
                            DataColumn(label: Text("Rôle", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Section", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Téléphone", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Statut", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          ],
                          rows: utilisateurs.asMap().entries.map((entry) {
                            int index = entry.key;
                            dynamic user = entry.value;
                            final bool estActif = (user['actif'] ?? 1) == 1;
                            return DataRow(
                              color: WidgetStateProperty.all(
                                index.isEven ? Colors.white : Color.fromARGB(255, 245, 248, 255),
                              ),
                              cells: [
                                  DataCell(Text(user['ID_utilisateur'].toString())),
                                  DataCell(Text(user['Nom_utilisateur'] ?? '')),
                                  DataCell(Text(user['role'] ?? '')),
                                  DataCell(Text(user['descptionSection'] ?? '—')),
                                  DataCell(Text(user['telephone'] ?? '')),
                                  DataCell(Text(
                                    estActif ? 'Actif' : 'Désactivé',
                                    style: TextStyle(
                                      color: estActif ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
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



// contenu menu commandes

class CommandesMenu extends StatefulWidget {
  final String titreMenuCommandes;
  final int identreprise;

  const CommandesMenu({
    super.key,
    required this.titreMenuCommandes,
    required this.identreprise,
  });

  @override
  State<CommandesMenu> createState() => _CommandesMenuState();
}

class _CommandesMenuState extends State<CommandesMenu> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _accentBlue = Color(0xFF1976D2);

  late Future<List<Map<String, dynamic>>> _futureCommandes;

  @override
  void initState() {
    super.initState();
    _futureCommandes = fetchCommandes();
  }

  Future<List<Map<String, dynamic>>> fetchCommandes() async {
    var url = Uri.parse(
        "https://riphin-salemanager.com/beni_newlook_API/afficherCommandes.php");
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
        throw Exception(data['error'] ?? "Erreur inconnue");
      }
    } else {
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }

  void _refresh() => setState(() => _futureCommandes = fetchCommandes());

  void _ouvrirCommande() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CommandePage(idEntreprise: widget.identreprise),
      ),
    ).then((_) => _refresh());
  }

  Color _statutColor(String? statut) {
    switch ((statut ?? '').toLowerCase()) {
      case 'livré':
      case 'livre':
        return const Color(0xFF388E3C);
      case 'en attente':
        return const Color(0xFFF57C00);
      case 'annulé':
      case 'annule':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF1976D2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête (même style que MenuCaisse) ──
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  // ignore: deprecated_member_use
                  color: _primary.withOpacity(0.2),
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
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: _primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titreMenuCommandes,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suivi et gestion des commandes clients',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                // Boutons d'action
                ElevatedButton.icon(
                  onPressed: _ouvrirCommande,
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                  label: const Text('Nouvelle commande'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'Actualiser',
                  icon: const Icon(Icons.refresh_rounded, color: _primary),
                  style: IconButton.styleFrom(
                    // ignore: deprecated_member_use
                    backgroundColor: _primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Tableau ──
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureCommandes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 56, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text('Erreur : ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Aucune commande trouvée',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _ouvrirCommande,
                          icon: const Icon(Icons.add),
                          label: const Text('Passer une commande'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                final commandes = snapshot.data!;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      // Bandeau compteur
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: _primary.withOpacity(0.06),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: Text(
                          '${commandes.length} commande(s)',
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // Table scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  // ignore: deprecated_member_use
                                  _primary.withOpacity(0.1)),
                              headingRowHeight: 52,
                              // ignore: deprecated_member_use
                              dataRowHeight: 50,
                              columnSpacing: 20,
                              border: TableBorder(
                                horizontalInside:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              columns: const [
                                DataColumn(
                                    label: Text('ID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Client',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Produit',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('PU',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Qté',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Total',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Statut',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                                DataColumn(
                                    label: Text('Section',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _primary))),
                              ],
                              rows: commandes.asMap().entries.map((entry) {
                                final i = entry.key;
                                final c = entry.value;
                                final statut = c['statut']?.toString() ?? '';
                                final statutColor = _statutColor(statut);
                                return DataRow(
                                  color: WidgetStateProperty.all(
                                    i.isEven
                                        ? Colors.white
                                        : const Color(0xFFF5F8FF),
                                  ),
                                  cells: [
                                    DataCell(Text(
                                      c['Idcommande']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _primary),
                                    )),
                                    DataCell(Text(
                                        c['datecommande']?.toString() ?? '')),
                                    DataCell(Text(
                                        c['client_name']?.toString() ?? '')),
                                    DataCell(Text(
                                      c['designationProduit']?.toString() ??
                                          '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    )),
                                    DataCell(Text(
                                        c['prixUnitiare']?.toString() ?? '')),
                                    DataCell(Text(
                                        c['Quantite']?.toString() ?? '')),
                                    DataCell(Text(
                                      c['totalPayer']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    )),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              statutColor.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          statut,
                                          style: TextStyle(
                                            color: statutColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                        c['descptionSection']?.toString() ??
                                            '')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}