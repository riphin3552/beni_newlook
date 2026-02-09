
import 'dart:convert';

import 'package:beni_newlook/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget{
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final _formKey = GlobalKey<FormState>();
  bool _obscurpassWord=true;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  Future<void> _login(
    String username, 
    String password,
    BuildContext context
  ) async {
    // Logique de connexion ici
    var url = Uri.parse('https://riphin-salemanager.com/beni_newlook_API/connexion.php');
    var response = await http.post(url, 
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'nomUtilisateur': username,
      'motDePasse': password,
    })
    ).timeout(Duration(seconds: 10));

    if (!mounted) return;

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success']) {
        // Connexion réussie
           final int identreprise=data['user']['entreprise'];     

        final prefs = await SharedPreferences.getInstance(); // sauvegarder le token
        await prefs.setString('token', data['user']['token']);
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context, 
          MaterialPageRoute(builder: (context) =>  MainMenu(identreprise:identreprise)),
        );
      } else {
        // Échec de la connexion
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
              title: Text('Erreur'),
              content: Text(data['message'] ?? 'Échec de la connexion'),
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
    } else {
      // Erreur serveur
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(Icons.warning_amber, color: Colors.orange, size: 48),
            title: Text('Erreur'),
            content: Text('Erreur serveur: ${response.statusCode}'),
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
      backgroundColor: Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 245, 248, 255),
                Color.fromARGB(255, 225, 235, 255),
              ],
            ),
          ),
          child: Center(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Color.fromARGB(255, 121, 169, 240).withOpacity(0.1),
                              backgroundImage: AssetImage('lib/images/logoHB.jpeg'),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Bienvenue',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 121, 169, 240),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Se connecter à votre compte',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 32),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Nom d\'utilisateur',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 121, 169, 240)),
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
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom d\'utilisateur';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurpassWord,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                prefixIcon: Icon(Icons.lock, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurpassWord ? Icons.visibility_off : Icons.visibility,
                                    color: Color.fromARGB(255, 121, 169, 240),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurpassWord = !_obscurpassWord;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _login(
                                    _usernameController.text,
                                    _passwordController.text,
                                    context,
                                  );
                                }
                              },
                              icon: Icon(Icons.login),
                              label: Text(
                                'Se Connecter',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 121, 169, 240),
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
          ),
        ),
      ),
    );
  }
}