
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

        final prefs = await SharedPreferences.getInstance(); // sauvegarder le token
        await prefs.setString('token', data['user']['token']);
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context, 
          MaterialPageRoute(builder: (context) => const MainMenu()),
        );
      } else {
        // Échec de la connexion
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Échec de la connexion')),
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
    return Scaffold(
      
      body: SingleChildScrollView(
        child: Container(
            color: const Color.fromARGB(255, 211, 225, 247),
            //height: MediaQuery.of(context).size.height,
            //width: double.infinity,
          child: Center(
            
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Padding( padding: EdgeInsets.all(60.0),
                    child: Card(
                      child: Padding(padding: EdgeInsets.all(100.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            
                            radius: 60,
                            backgroundImage: AssetImage('lib/images/logoHB.jpeg'),                 
                          ),
                          
                          SizedBox(height: 20.0),
                          Text("Se connecter", style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),),
                          SizedBox(height: 16.0),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre nom d\'utilisateur';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock)
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // Traiter la connexion
                                _login(
                                  _usernameController.text, 
                                  _passwordController.text,
                                  context
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 121, 169, 240),
                              // Utilise double.infinity pour que le bouton prenne la largeur maximale disponible
                                minimumSize: Size(double.infinity, 50),
                              ),
                            child: Text('Se connecter', style: TextStyle(fontSize: 18.0,color: Colors.white),
                          ),
                      )],
                      ),),
                    ),
                  )
                ],
                
              ),
            ),
          ),
        ),
      ),
    );
  }
}