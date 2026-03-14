import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:budget/screens/home/home_screen.dart';
import 'package:budget/screens/database/db_helper.dart';
import 'package:budget/screens/licence_page.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController controller = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool biometricAvailable = false;
  bool isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pinFocusNode.dispose();
    super.dispose();
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
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.green,
        title: const Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security_rounded, size: 22, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'FinanTrack',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            Text(
              'Espace Sécurisé',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_open_rounded, size: 50, color: Colors.green),
              ),
              const SizedBox(height: 32),
              const Text(
                "Déverrouillage",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Saisissez votre code PIN de 6 chiffres",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Pinput(
                  controller: controller,
                  length: 6,
                  onCompleted: _onCompleted,
                  obscureText: true,
                  autofocus: true,
                  focusNode: _pinFocusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  separatorBuilder: (index) => const SizedBox(width: 10),
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                ),
              ),
              const Spacer(),
              if (biometricAvailable && _users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: [
                          const Expanded(child: Divider(indent: 40, endIndent: 20)),
                          Text(
                            "OU",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                              letterSpacing: 2,
                            ),
                          ),
                          const Expanded(child: Divider(indent: 20, endIndent: 40)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      InkWell(
                        onTap: _biometricAuthentication,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: Colors.green.shade50, width: 2),
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.green,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Icon(Icons.fingerprint_rounded,
                                    size: 50, color: Colors.green.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Touch ID / Face ID",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
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
    if (enteredPin == _users[0]['user_pin'].toString() &&
        _users[0]['acept_licence'] == 1) {
      _redirectionHome();
    } else if (enteredPin == _users[0]['user_pin'].toString() &&
        _users[0]['acept_licence'] == 0) {
      _redirectionLicence(usersId: _users[0]['user_id']);
    } else {
      _showFlushbar("Votre code pin de 6 chiffres est incorrect !", Colors.red);
      controller.clear();
      // ⚡ Correction : refocus + clavier automatique
      Future.delayed(const Duration(milliseconds: 50), () {
        _focusPinField();
      });
    }
  }

  void _redirectionHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return const HomeScreen();
    }));
  }

  Future<void> _redirectionLicence({required int usersId}) async {
    if (!mounted) return;

    final licenceAccepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LicencePage(usersId: usersId),
      ),
    );

    if (mounted && licenceAccepted == true) {
      _redirectionHome();
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

        if (authenticated) {
          if (_users[0]['acept_licence'] == 1) {
            _redirectionHome();
          } else if (_users[0]['acept_licence'] == 0) {
            _redirectionLicence(usersId: _users[0]['user_id']);
          }
        } else {
          controller.clear();
          Future.delayed(const Duration(milliseconds: 50), () {
            _focusPinField();
          });
        }
      }
    } catch (e) {
      print("Erreur _biometricAuthentication: ${e.toString()}");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        controller.clear();
        Future.delayed(const Duration(milliseconds: 50), () {
          _focusPinField();
        });
      }
    }
  }

  /// Force le focus sur le champ PIN et ouvre le clavier
  Future<void> _focusPinField() async {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_pinFocusNode);
    await Future.delayed(const Duration(milliseconds: 50));
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  void _showFlushbar(String message, Color color) {
    if (!mounted) return;
    Flushbar(
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 500),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }
}