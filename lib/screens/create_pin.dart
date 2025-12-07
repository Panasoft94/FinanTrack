import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:budget/screens/login.dart';
import 'package:budget/screens/database/db_helper.dart';


class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final TextEditingController controller = TextEditingController();

  //creation du compte de l'utilisateur
  void _addUser() async{
    final user_pin = controller.text;
    final user_status = 1;
    final acept_licence = 0;
    final db = await DbHelper.getdb();
    await db!.insert(DbHelper.USERS_TABLE, {
      DbHelper.USER_PIN: user_pin,
      DbHelper.USER_STATUS: user_status,
      DbHelper.ACEPT_LICENCE: acept_licence
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 6,
        toolbarHeight: 65,
        backgroundColor: Colors.green,
        title: const Text(
          "Créer nouveau code pin",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SafeArea(
          child: Column(
            children: <Widget>[
              SizedBox(height: 24,),
              Text("Entrer pin",style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black
              ),),
              SizedBox(height: 10,),
              Text("Veuillez entrer votre code pin de 6 chiffres ! ",style: TextStyle(fontStyle: FontStyle.italic),),
              SizedBox(height: 10,),
              Pinput(
                length: 6,
                obscureText: true,
                autofocus: true,
                controller: controller,
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: (){
                  _addUser();
                  //on redirige l'utilisateur vers la page d'authentification
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(
                      builder: (context)=>LoginPage(),), (route) =>false,
                  );  //fin de la fonction de redirection

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Votre nouveau pin a été créé avec succès !",style: TextStyle(color: Colors.white),),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      showCloseIcon: true,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    )
                ),
                child: const Text("Enregistrer",style: TextStyle(fontSize: 15,color: Colors.white),),
              ),
            ],
          ),
      ),
    );
  }
}
