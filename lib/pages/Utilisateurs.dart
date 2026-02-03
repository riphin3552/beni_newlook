import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class Utilisateurs extends StatefulWidget {
  final int identreprise;
  const Utilisateurs({super.key, required this.identreprise});

  @override
  State<Utilisateurs> createState() => _UtilisateursState();
}

class _UtilisateursState extends State<Utilisateurs> {

  final _formKey=GlobalKey <FormState>();
  bool _obscurepassWord= true; // mot de pass masqué par defaut
  final _nomUtilisateurController=TextEditingController();
  final _motdepassController=TextEditingController();
  final _telephoneController=TextEditingController();


  Future <void> addUtilisateur(
     

  )async{
    try{
        var url=Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AjouterUtilisateur.php");
        var response=await http.post(
        url,
        headers:{'Content-Type':'application/json'},
        body: json.encode({
          "nom":_nomUtilisateurController.text,
          "keypassword":_motdepassController.text,
          "phone":_telephoneController.text,
          "entreprise": widget.identreprise,
        })

      );

      if(response.statusCode==200){
        var data=json.decode(response.body);
        if(data['success']){
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text("Utilisateur ajouté qvec succès",textAlign: TextAlign.center,)));
        }else{
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("erreur d'enregistrement: ${data['error']}")));
        }
      }
    } catch(e){
      if (!mounted) return;
      ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text("erruer de connexion: $e")));
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text("Utilisateurs")
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
                              Text("Nouvel utilisateur"),
                              SizedBox(height: 20,),
                              TextFormField(
                                controller: _nomUtilisateurController,
                                decoration: InputDecoration(
                                  labelText: 'Nom utilisateur',
                                  hintText: 'Nom utilisateur',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person)
                                ),
                                validator: (value) {
                                  if(value==null || value.isEmpty){
                                    return 'veuillez entrer votre nom utilisateur';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16,),

                              TextFormField(
                                controller: _telephoneController,
                                decoration: InputDecoration(
                                  labelText: 'Télephone',
                                  hintText: 'Nomero de télephone',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person)
                                ),
                                validator: (value) {
                                  if(value==null || value.isEmpty){
                                    return 'veuillez entrer votre numero de telephone';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16,),
                    
                              TextFormField(
                                controller: _motdepassController,
                                obscureText: _obscurepassWord,
                                decoration: InputDecoration(
                                  labelText: 'Mot de pass',
                                  hintText: 'Mot de pass',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton( 
                                    icon: Icon(
                                          _obscurepassWord? Icons.visibility:Icons.visibility_off,
                                  ),
                                  onPressed: (){
                                    setState(() {
                                      _obscurepassWord=!_obscurepassWord; // bascule l'etat
                                    });
                                  },)
                                ),
                                validator: (value) {
                                  if(value==null || value.isEmpty){
                                    return 'veuillez entrer votre mot de pass';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16,),
                    
                              ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Traiter la connexion
                                  addUtilisateur();
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