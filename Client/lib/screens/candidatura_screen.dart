import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/cupertino.dart';

class CandidaturaScreen extends StatefulWidget {
  final Map annuncio;

  const CandidaturaScreen({super.key, required this.annuncio});

  @override
  State<CandidaturaScreen> createState() => _CandidaturaScreenState();
}

class _CandidaturaScreenState extends State<CandidaturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _emailController = TextEditingController();

  String? _nomeFilePdf;
  String? _pdfBase64;
  bool _staInviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _scegliPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        setState(() {
          _nomeFilePdf = file.name;
          _pdfBase64 = base64Encode(bytes);
        });
      }
    }
  }

  Future<void> _inviaCandidatura() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pdfBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allega il tuo curriculum in formato PDF.')),
      );
      return;
    }

    setState(() => _staInviando = true);

    try {
      final successo = await ApiService.inviaCandidatura(
        idAnnuncio: (widget.annuncio['id'] ?? '').toString(),
        nome: _nomeController.text.trim(),
        cognome: _cognomeController.text.trim(),
        email: _emailController.text.trim(),
        curriculumBase64: _pdfBase64!,
      );

      if (!mounted) return;
      setState(() => _staInviando = false);

      if (successo) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Candidatura inviata!'),
            content: const Text(
              'I tuoi dati e il tuo curriculum sono stati registrati con successo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante l\'invio della candidatura.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _staInviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di rete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.annuncio['titolo'] ?? 'Annuncio';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invia Candidatura'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posizione: $titolo',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Inserisci il nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cognomeController,
                decoration: const InputDecoration(
                  labelText: 'Cognome',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Inserisci il cognome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Inserisci l\'email';
                  if (!v.contains('@')) return 'Inserisci un\'email valida';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _scegliPdf,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _nomeFilePdf == null
                      ? 'Allega Curriculum (PDF)'
                      : 'PDF allegato: $_nomeFilePdf',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _staInviando ? null : _inviaCandidatura,
                  child: _staInviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Conferma e Invia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}