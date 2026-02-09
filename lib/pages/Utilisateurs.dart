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
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
                title: Text('Succès'),
                content: Text("Utilisateur ajouté avec succès"),
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
        }else{
          // ignore: use_build_context_synchronously
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
                title: Text('Erreur'),
                content: Text("Erreur d'enregistrement: ${data['error']}"),
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
    } catch(e){
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
        },
      );
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter un Utilisateur"),
        backgroundColor: Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 48,
                            color: Color.fromARGB(255, 121, 169, 240),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Nouvel Utilisateur",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 121, 169, 240),
                            ),
                          ),
                          SizedBox(height: 24),
                              TextFormField(
                                controller: _nomUtilisateurController,
                                decoration: InputDecoration(
                                  labelText: 'Nom utilisateur',
                                  labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                  hintText: 'Nom utilisateur',
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
                                  if(value==null || value.isEmpty){
                                    return 'veuillez entrer votre nom utilisateur';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16,),

                              TextFormField(
                                controller: _telephoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Téléphone',
                                  labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                  hintText: 'Numéro de téléphone',
                                  prefixIcon: Icon(Icons.phone, color: Color.fromARGB(255, 121, 169, 240)),
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
                                  labelText: 'Mot de passe',
                                  labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                                  hintText: 'Mot de passe',
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
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    addUtilisateur();
                                  }
                                },
                                icon: Icon(Icons.check),
                                label: Text(
                                  'Ajouter l\'Utilisateur',
                                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
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
                      )],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}