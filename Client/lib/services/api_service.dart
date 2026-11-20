import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Su Simulatore iOS puoi usare 'http://localhost:8080'
  // Su iPhone fisico metti l'IP Wi-Fi del Mac
  static const String baseUrl = 'http://172.19.206.134:8080';

  // R5: Legge tutti gli annunci dalla bacheca
  static Future<List<dynamic>> getAnnunci() async {
    final response = await http.get(Uri.parse('$baseUrl/annunci'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Errore nel caricamento degli annunci');
  }

  // R1: Registra una nuova azienda
  static Future<bool> registrazione(
      String nome,
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrazione'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'password': password,
      }),
    );
    return response.statusCode == 200;
  }

  // R2: Esegue il login e restituisce la risposta con il token (o null se errato)
  static Future login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // R4: Pubblica un nuovo annuncio
  static Future<bool> creaAnnuncio({
    required String titolo,
    required String descrizione,
    required String azienda,
    required String emailAzienda,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/annunci'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titolo': titolo,
        'descrizione': descrizione,
        'azienda': azienda,
        'email_azienda': emailAzienda,
      }),
    );
    return response.statusCode == 200;
  }

  // R6: Invia una candidatura con il PDF convertito in Base64
  static Future<bool> inviaCandidatura({
    required String idAnnuncio,
    required String nome,
    required String cognome,
    required String email,
    required String curriculumBase64,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/candidature'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_annuncio': idAnnuncio,
        'nome': nome,
        'cognome': cognome,
        'email': email,
        'curriculum_base64': curriculumBase64,
      }),
    );
    return response.statusCode == 200;
  }

  // R7: Legge le candidature ricevute per uno specifico annuncio
  static Future<List<dynamic>> getCandidature(String idAnnuncio) async {
    final response = await http.get(
      Uri.parse('$baseUrl/candidature/$idAnnuncio'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Errore nel caricamento delle candidature');
  }

  // R7: Costruisce il link diretto per aprire il PDF sul server
  static String getCvUrl(String nomeFile) {
    return '$baseUrl/cv/$nomeFile';
  }
}