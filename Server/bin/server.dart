import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';

// Configure routes.
final router = Router()
  ..get('/annunci', _annunciHandler)
  ..post('/registrazione', _registrazioneHandler)//rotta per la registrazione
  ..post('/login', _loginHandler) //rotta per il login
  ..post('/annunci', _creaAnnuncioHandler) //rotta per gli annunci
  ..post('/candidature', _candidaturaHandler)//rotta per le candidature
  ..get('/candidature/<idAnnuncio>', _getCandidatureHandler) //<idAnnuncio> significa che questa parte dell'indirizzo è variabile
  ..get('/cv/<nomeFile>', _getCvHandler);//rotta per scaricare i pdf

Response _annunciHandler(Request req) {
  final file = File('data/annunci.json');

  // Se il file non esiste ancora, restituisce errore 404
  if (!file.existsSync()) {
    return Response.notFound('File degli annunci non trovato.');
  }

  // Legge il file JSON e lo spedisce al Client
  final datiJson = file.readAsStringSync();
  return Response.ok(datiJson, headers: {'Content-Type': 'application/json'});
}

// NUOVA FUNZIONE: Gestisce i dati in arrivo e li salva
Future<Response> _registrazioneHandler(Request req) async {
try {
// 1. Legge i dati inviati dall'app (es. email e password)
final payload = await req.readAsString();
final nuovaAzienda = jsonDecode(payload);

// 2. Apre il file delle aziende
final file = File('data/aziende.json');
List aziende = [];

// 3. Se il file ha già dei dati, li carica nella lista
if (file.existsSync()) {
final contenuto = file.readAsStringSync();
if (contenuto.isNotEmpty) {
aziende = jsonDecode(contenuto);
}
}

//Aggiunge la nuova azienda e risalva il file
aziende.add(nuovaAzienda);
file.writeAsStringSync(jsonEncode(aziende));

//Risponde al Client (App) che tutto è andato bene
return Response.ok('{"messaggio": "Azienda registrata con successo!"}',
headers: {'Content-Type': 'application/json'});

} catch (e) {
return Response.internalServerError(body: 'Errore interno: $e');
}
}

Future<Response> _loginHandler(Request req) async {
  try {
    //Legge le credenziali inviate dall'app
    final payload = await req.readAsString();
    final credenziali = jsonDecode(payload);

    //Apre il database delle aziende
    final file = File('data/aziende.json');
    if (!file.existsSync()) {
      return Response.forbidden('{"errore": "Nessuna azienda registrata nel sistema."}', headers: {'Content-Type': 'application/json'});
    }

    //Decodifica la lista delle aziende
    final contenuto = file.readAsStringSync();
    List aziende = jsonDecode(contenuto);

    //Cerca se esiste un'azienda con quella esatta email e password
    final match = aziende.where((a) => a['email'] == credenziali['email'] && a['password'] == credenziali['password']);

    //Risponde in base al risultato
    if (match.isNotEmpty) {
      final aziendaTrovata = match.first;
      return Response.ok(
        jsonEncode({
          'messaggio': 'Login effettuato con successo!',
          'token': 'auth-token-123',
          'nome': aziendaTrovata['nome'],
          'email': aziendaTrovata['email'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      // Fallimento: Credenziali errate
      return Response.forbidden('{"errore": "Email o password errati."}', headers: {'Content-Type': 'application/json'});
    }
  } catch (e) {
    return Response.internalServerError(body: 'Errore interno: $e');
  }
}

Future<Response> _creaAnnuncioHandler(Request req) async {
  try {
    //Legge i dati dell'annuncio in arrivo
    final payload = await req.readAsString();
    final nuovoAnnuncio = jsonDecode(payload);

    //Crea un ID univoco usando il timestamp attuale
    nuovoAnnuncio['id'] = DateTime.now().millisecondsSinceEpoch.toString();

    //Apre il file degli annunci
    final file = File('data/annunci.json');
    List annunci = [];

    //Carica gli annunci già esistenti (se ce ne sono)
    if (file.existsSync()) {
      final contenuto = file.readAsStringSync();
      if (contenuto.isNotEmpty) {
        annunci = jsonDecode(contenuto);
      }
    }

    //Aggiunge il nuovo annuncio e salva il file
    annunci.add(nuovoAnnuncio);
    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(annunci));

    //Risponde con successo
    return Response.ok('{"messaggio": "Annuncio pubblicato con successo!"}',
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: 'Errore interno: $e');
  }
}

Future<Response> _candidaturaHandler(Request req) async {
  try {
    //Legge il JSON inviato dal candidato
    final payload = await req.readAsString();
    final dati = jsonDecode(payload);

    final idAnnuncio = dati['id_annuncio'];
    final nome = dati['nome'];
    final cognome = dati['cognome'];
    final email = dati['email'];
    final fileBase64 = dati['curriculum_base64'];

    //Crea il nome univoco del PDF e salva il file fisico in data/cv/
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nomePulito = '${nome}_$cognome'.replaceAll(' ', '_');
    final nomeFilePdf = '${timestamp}_$nomePulito.pdf';

    final bytesPdf = base64Decode(fileBase64);
    File('data/cv/$nomeFilePdf').writeAsBytesSync(bytesPdf);

    //Prepara l'oggetto candidatura da salvare nel registro JSON
    final nuovaCandidatura = {
      'id': timestamp.toString(),
      'id_annuncio': idAnnuncio,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'file_cv': nomeFilePdf,
    };

    //Carica le candidature esistenti e aggiunge quella nuova
    final fileJson = File('data/candidature.json');
    List candidature = [];
    if (fileJson.existsSync()) {
      final contenuto = fileJson.readAsStringSync();
      if (contenuto.isNotEmpty) {
        candidature = jsonDecode(contenuto);
      }
    }

    candidature.add(nuovaCandidatura);
    fileJson.writeAsStringSync(JsonEncoder.withIndent('  ').convert(candidature));

    return Response.ok(
      '{"messaggio": "Candidatura inviata e salvata con successo!"}',
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Errore interno: $e');
  }
}

Response _getCandidatureHandler(Request req, String idAnnuncio) {
  final file = File('data/candidature.json');
  if (!file.existsSync()) {
    return Response.ok('[]', headers: {'Content-Type': 'application/json'});
  }

  final contenuto = file.readAsStringSync();
  if (contenuto.isEmpty) {
    return Response.ok('[]', headers: {'Content-Type': 'application/json'});
  }

  // Filtra solo le candidature che appartengono all'annuncio richiesto
  final List tutte = jsonDecode(contenuto);
  final filtrate = tutte.where((c) => c['id_annuncio'] == idAnnuncio).toList();

  return Response.ok(
    JsonEncoder.withIndent('  ').convert(filtrate),
    headers: {'Content-Type': 'application/json'},
  );
}

Response _getCvHandler(Request req, String nomeFile) {
  final file = File('data/cv/$nomeFile');

  if (!file.existsSync()) {
    return Response.notFound('Curriculum non trovato.');
  }

  final bytes = file.readAsBytesSync();
  return Response.ok(
    bytes,
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'inline; filename="$nomeFile"',
    },
  );
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
