import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'candidatura_screen.dart';

class DettaglioAnnuncioScreen extends StatefulWidget {
  final Map annuncio;

  const DettaglioAnnuncioScreen({super.key, required this.annuncio});

  @override
  State<DettaglioAnnuncioScreen> createState() =>
      _DettaglioAnnuncioScreenState();
}

class _DettaglioAnnuncioScreenState extends State<DettaglioAnnuncioScreen> {
  bool _isAziendaLoggata = false;
  bool _controlloInCorso = true;

  @override
  void initState() {
    super.initState();
    _verificaStatoLogin();
  }

  Future<void> _verificaStatoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;
    setState(() {
      _isAziendaLoggata = token != null && token.isNotEmpty;
      _controlloInCorso = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.annuncio['titolo'] ?? 'Senza titolo';
    final azienda = widget.annuncio['azienda'] ?? 'Azienda';
    final descrizione =
        widget.annuncio['descrizione'] ?? 'Nessuna descrizione.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Annuncio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 18, color: Colors.indigo.shade700),
                const SizedBox(width: 6),
                Text(
                  azienda,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Descrizione della posizione',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  descrizione,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_controlloInCorso)
              _isAziendaLoggata
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sei connesso come azienda. Effettua il logout dall\'Area Riservata per candidarti agli annunci.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CandidaturaScreen(
                          annuncio: widget.annuncio,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Candidati a questo annuncio'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}