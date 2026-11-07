import 'package:flutter/services.dart';

class CanauxNatifs {
  //  infos appareil
  static const _infos = MethodChannel('appareil/infos');

  static Future<Map<String, dynamic>> lireInfos() async {
    final infos = await _infos.invokeMapMethod<String, dynamic>('lire');
    return infos ?? {};
  }

  //  vibration
  static const _vibreur = MethodChannel('appareil/vibrer');

  static Future<void> vibrer(String motif) =>
      _vibreur.invokeMethod('vibrer', {'motif': motif});

  //  lumière
  static const _lumiere = EventChannel('capteur/lumiere');

  static Stream<double> lumiere() =>
      _lumiere.receiveBroadcastStream().map((v) => (v as num).toDouble());

  //permission micro et niveau sonore
  static const _permission = MethodChannel('audio/permission');
  static const _audio = EventChannel('audio/niveau');

  static Future<bool> demanderMicro() async =>
      await _permission.invokeMethod<bool>('demander') ?? false;

  static Stream<double> niveauSonore() =>
      _audio.receiveBroadcastStream().map((v) => (v as num).toDouble());

  //  proximité
  static const _proximite = EventChannel('capteur/proximite');

  static Stream<bool> proximite() =>
      _proximite.receiveBroadcastStream().map((v) => v as bool);

  //  lampe torche
  static const _torche = MethodChannel('appareil/torche');

  static Future<void> allumerTorche(bool etat) =>
      _torche.invokeMethod('allumer', {'etat': etat});
}
