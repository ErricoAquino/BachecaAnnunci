import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'area_azienda_screen.dart';
import 'dettaglio_annuncio_screen.dart';
import 'login_screen.dart';

class BachecaScreen extends StatefulWidget {
  const BachecaScreen({super.key});

  @override
  State<BachecaScreen> createState() => _BachecaScreenState();
}

class _BachecaScreenState extends State<BachecaScreen> {
  List annunci = [];
  bool staCaricando = true;
  String? errore;

  @override
  void initState() {
    super.initState();
    _caricaAnnunci();
  }

  Future<void> _caricaAnnunci() async {
    setState(() {
      staCaricando = true;
      errore = null;
    });

    try {
      final dati = await ApiService.getAnnunci();
      if (!mounted) return;
      setState(() {
        annunci = dati;
        staCaricando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errore =
        'Impossibile contattare il server.\nControlla che sia acceso e sullo stesso Wi-Fi.';
        staCaricando = false;
      });
    }
  }

  Future<void> _apriAreaAziende() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => (token != null && token.isNotEmpty)
            ? const AreaAziendaScreen()
            : const LoginScreen(),
      ),
    );

    _caricaAnnunci();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Lavoro'),
        actions: [
          TextButton.icon(
            onPressed: _apriAreaAziende,
            icon: const Icon(Icons.business),
            label: const Text('Aziende'),
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(errore!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _caricaAnnunci,
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    if (annunci.isEmpty) {
      return RefreshIndicator(
        onRefresh: _caricaAnnunci,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Nessun annuncio pubblicato al momento.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _caricaAnnunci,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: annunci.length,
        itemBuilder: (context, index) {
          final annuncio = annunci[index];
          final titolo = annuncio['titolo'] ?? 'Senza titolo';
          final azienda = annuncio['azienda'] ?? 'Azienda';
          final descrizione = annuncio['descrizione'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                titolo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    azienda,
                    style: TextStyle(color: Colors.indigo.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descrizione,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DettaglioAnnuncioScreen(annuncio: annuncio),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}