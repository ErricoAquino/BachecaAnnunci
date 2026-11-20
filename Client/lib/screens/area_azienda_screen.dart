import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'candidature_annuncio_screen.dart';

class AreaAziendaScreen extends StatefulWidget {
  const AreaAziendaScreen({super.key});

  @override
  State<AreaAziendaScreen> createState() => _AreaAziendaScreenState();
}

class _AreaAziendaScreenState extends State<AreaAziendaScreen> {
  String nomeAzienda = '';
  String emailAzienda = '';
  List mieiAnnunci = [];
  bool staCaricando = true;

  @override
  void initState() {
    super.initState();
    _inizializza();
  }

  Future<void> _inizializza() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeAzienda = prefs.getString('nome_azienda') ?? 'Azienda';
      emailAzienda = prefs.getString('email_azienda') ?? '';
    });
    await _caricaMieiAnnunci();
  }

  Future<void> _caricaMieiAnnunci() async {
    setState(() => staCaricando = true);

    try {
      final tutti = await ApiService.getAnnunci();
      final filtrati = tutti.where((a) {
        final emailMatch = a['email_azienda'] != null &&
            a['email_azienda'].toString().toLowerCase() ==
                emailAzienda.toLowerCase();
        final nomeMatch = a['azienda'] != null &&
            a['azienda'].toString().toLowerCase() ==
                nomeAzienda.toLowerCase();
        return emailMatch || nomeMatch;
      }).toList();

      if (!mounted) return;
      setState(() {
        mieiAnnunci = filtrati;
        staCaricando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => staCaricando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nel caricamento degli annunci.')),
      );
    }
  }

  Future<void> _apriDialogNuovoAnnuncio() async {
    final formKey = GlobalKey<FormState>();
    final titoloCtrl = TextEditingController();
    final descrizioneCtrl = TextEditingController();

    final pubblicato = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool staSalvando = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nuovo Annuncio'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titoloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titolo posizione',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Inserisci il titolo'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descrizioneCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Inserisci la descrizione'
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: staSalvando ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: staSalvando
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => staSalvando = true);
                    try {
                      final ok = await ApiService.creaAnnuncio(
                        titolo: titoloCtrl.text.trim(),
                        descrizione: descrizioneCtrl.text.trim(),
                        azienda: nomeAzienda,
                        emailAzienda: emailAzienda,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, ok);
                    } catch (_) {
                      if (ctx.mounted) Navigator.pop(ctx, false);
                    }
                  },
                  child: staSalvando
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Pubblica'),
                ),
              ],
            );
          },
        );
      },
    );

    if (pubblicato == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annuncio pubblicato con successo!')),
      );
      _caricaMieiAnnunci();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nome_azienda');
    await prefs.remove('email_azienda');

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Riservata Azienda'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _apriDialogNuovoAnnuncio,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Annuncio'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeAzienda,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (emailAzienda.isNotEmpty)
                  Text(
                    emailAzienda,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          Expanded(
            child: staCaricando
                ? const Center(child: CircularProgressIndicator())
                : mieiAnnunci.isEmpty
                ? RefreshIndicator(
              onRefresh: _caricaMieiAnnunci,
              child: ListView(
                children: const [
                  SizedBox(height: 140),
                  Center(
                    child: Text(
                      'Non hai ancora pubblicato annunci.\nPremi "+ Nuovo Annuncio" in basso.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _caricaMieiAnnunci,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: mieiAnnunci.length,
                itemBuilder: (context, index) {
                  final annuncio = mieiAnnunci[index];
                  final titolo = annuncio['titolo'] ?? 'Senza titolo';
                  final descrizione = annuncio['descrizione'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        titolo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        descrizione,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Candidati'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CandidatureAnnuncioScreen(
                                  annuncio: annuncio,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}