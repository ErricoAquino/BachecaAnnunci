import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class CandidatureAnnuncioScreen extends StatefulWidget {
  final Map annuncio;

  const CandidatureAnnuncioScreen({super.key, required this.annuncio});

  @override
  State<CandidatureAnnuncioScreen> createState() =>
      _CandidatureAnnuncioScreenState();
}

class _CandidatureAnnuncioScreenState extends State<CandidatureAnnuncioScreen> {
  List candidature = [];
  bool staCaricando = true;
  String? errore;

  @override
  void initState() {
    super.initState();
    _caricaCandidature();
  }

  Future<void> _caricaCandidature() async {
    setState(() {
      staCaricando = true;
      errore = null;
    });

    try {
      final idAnnuncio = (widget.annuncio['id'] ?? '').toString();
      final dati = await ApiService.getCandidature(idAnnuncio);
      if (!mounted) return;
      setState(() {
        candidature = dati;
        staCaricando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errore = 'Errore nel caricamento delle candidature.';
        staCaricando = false;
      });
    }
  }

  Future<void> _apriPdf(String nomeFile) async {
    if (nomeFile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun file PDF associato a questa candidatura.')),
      );
      return;
    }

    final url = Uri.parse(ApiService.getCvUrl(nomeFile));
    final aperto = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!aperto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire il PDF del curriculum.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.annuncio['titolo'] ?? 'Annuncio';

    return Scaffold(
      appBar: AppBar(
        title: Text('Candidature: $titolo'),
      ),
      body: _costruisciCorpo(),
    );
  }

  Widget _costruisciCorpo() {
    if (staCaricando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errore != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errore!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _caricaCandidature,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (candidature.isEmpty) {
      return RefreshIndicator(
        onRefresh: _caricaCandidature,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Nessuna candidatura ricevuta per questo annuncio.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _caricaCandidature,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: candidature.length,
        itemBuilder: (context, index) {
          final c = candidature[index];
          final nome = c['nome'] ?? '';
          final cognome = c['cognome'] ?? '';
          final email = c['email'] ?? '';
          final fileCv = (c['curriculum'] ??
              c['file_cv'] ??
              c['nome_file'] ??
              c['cv'] ??
              c['curriculum_file'] ??
              '')
              .toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nome $cognome',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(email),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _apriPdf(fileCv),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Apri CV'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}