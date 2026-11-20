import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'area_azienda_screen.dart';
import 'registrazione_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _staCaricando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _accedi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _staCaricando = true);

    try {
      final emailInserita = _emailController.text.trim();
      final risposta = await ApiService.login(
        emailInserita,
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _staCaricando = false);

      if (risposta != null) {
        final token = (risposta['token'] ?? 'auth-token-123').toString();

        // Legge nome ed email sia se il server li manda diretti sia dentro 'azienda'
        String nomeAzienda = 'Azienda';
        String emailAzienda = emailInserita;

        if (risposta['azienda'] is Map) {
          final az = risposta['azienda'] as Map;
          nomeAzienda = (az['nome'] ?? 'Azienda').toString();
          emailAzienda = (az['email'] ?? emailInserita).toString();
        } else {
          nomeAzienda = (risposta['nome'] ??
              risposta['nome_azienda'] ??
              risposta['azienda'] ??
              'Azienda')
              .toString();
          emailAzienda = (risposta['email'] ?? emailInserita).toString();
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('nome_azienda', nomeAzienda);
        await prefs.setString('email_azienda', emailAzienda);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AreaAziendaScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email o password errati.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _staCaricando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accesso Aziende'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.business, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'Accedi alla tua Area Riservata',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Aziendale',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Inserisci l\'email';
                  if (!v.contains('@')) return 'Inserisci un\'email valida';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Inserisci la password'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _staCaricando ? null : _accedi,
                  child: _staCaricando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Accedi'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrazioneScreen(),
                    ),
                  );
                },
                child: const Text('Non hai ancora un account? Registrati'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}