import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:budget/screens/home/home_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/licence_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController controller = TextEditingController();
  bool biometricAvailable = false;
  bool isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _user(); 
    await _checkBiometricAvailability(); 
  }

  Future<void> _user() async {
    final users = await DbHelper.getUser();
    if (mounted) {
      setState(() {
        _users = users;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      bool available = await auth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          biometricAvailable = available;
        });
        if (biometricAvailable && _users.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _biometricAuthentication();
            }
          });
        }
      }
    } catch (e) {
      print("Erreur _checkBiometricAvailability: ${e.toString()}");
      if (mounted) {
        setState(() {
          biometricAvailable = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        toolbarHeight: 65,
        backgroundColor: Colors.green,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 8),
            Text('FinanTrack verrouillé'),
          ],
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 24),
                  Text("Déverouillage par code pin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
                  SizedBox(height: 10),
                  Text("Veuillez entrer votre code pin de 6 chiffres !", style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              SizedBox(height: 10),
              Pinput(
                controller: controller,
                length: 6,
                onCompleted: _onCompleted,
                obscureText: true,
                autofocus: true,
              ),

              SizedBox(height: 12),
              Spacer(),
              if (biometricAvailable && _users.isNotEmpty) 
                Column(
                  children: <Widget>[
                    Text("OU", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 38),
                    InkWell(
                      onTap: _biometricAuthentication,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.green),
                        ),
                        child: isLoading 
                            ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Icon(Icons.fingerprint, size: 65, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Empreinte biométrique"),
                  ],
                ),
                 SizedBox(height: 30), 
            ],
          ),
        ),
      ),
    );
  }

  void _onCompleted(String enteredPin) {
    if (_users.isEmpty) {
       _showFlushbar("Veuillez d'abord créer un code PIN.", Colors.orangeAccent);
      return;
    }
    if (enteredPin == _users[0]['user_pin'].toString() && _users[0]['acept_licence'] == 1) {
      _redirectionHome();
      _showFlushbar("Nous vous souhaitons la bienvenue !", Colors.blue);
    } else if (enteredPin == _users[0]['user_pin'].toString() && _users[0]['acept_licence'] == 0) {
      _redirectionLicence(usersId: _users[0]['user_id']);
    } else {
      _showFlushbar("Votre code pin de 6 chiffres est incorrect !", Colors.red);
      controller.clear();
    }
  }

  void _redirectionHome() {
    print("LOGIN_PAGE: _redirectionHome called. Navigating to HomePage."); // DEBUG
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return const HomeScreen();
    }));
  }

  // Modifiée pour utiliser push et attendre un résultat
  Future<void> _redirectionLicence({required int usersId}) async {
    print("LOGIN_PAGE: _redirectionLicence called. Navigating to LicencePage for user $usersId."); //DEBUG
    if (!mounted) return;

    final licenceAccepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LicencePage(
          usersId: usersId, 
          // onAccepted n'est plus passé ici
        ),
      ),
    );

    print("LOGIN_PAGE: Returned from LicencePage. Licence accepted: $licenceAccepted"); // DEBUG

    if (mounted && licenceAccepted == true) {
      print("LOGIN_PAGE: Licence was accepted, calling _redirectionHome."); // DEBUG
      _redirectionHome();
    } else {
      print("LOGIN_PAGE: Licence was not accepted or user returned."); // DEBUG
      // Si la licence n'est pas acceptée, on pourrait vouloir vider le PIN entré ou prendre une autre action.
      // Pour l'instant, l'utilisateur reste sur la page de login.
      // Si l'utilisateur appuie sur retour depuis la page de Licence, il reviendra à LoginPage.
      // Si la LoginPage avait été remplacée, cela ne serait pas possible.
    }
  }

  Future<void> _biometricAuthentication() async {
    if (!biometricAvailable || _users.isEmpty) return;
    if (isLoading) return;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Déverrouillage par empreinte biométrique !',
        options: const AuthenticationOptions(
          biometricOnly: true, 
          useErrorDialogs: true, 
          stickyAuth: true, 
        ),
      );

      if (mounted) { 
        setState(() {
          isLoading = false;
        });

        if (authenticated && _users[0]['acept_licence'] == 1) {
          _redirectionHome();
          _showFlushbar("Bienvenue 👋", Colors.blue);
        } else if (authenticated && _users[0]['acept_licence'] == 0) {
          _redirectionLicence(usersId: _users[0]['user_id']);
        } 
      }
    } catch (e) {
      print("Erreur _biometricAuthentication: ${e.toString()}");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showFlushbar(String message, Color color) {
    if (!mounted) return; 
    Flushbar(
      message: message,
      backgroundColor: color,
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: Duration(milliseconds: 500),
      icon: Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }
}
