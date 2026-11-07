import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native/canaux.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: PageCanaux()),
);

class PageCanaux extends StatefulWidget {
  const PageCanaux({super.key});

  @override
  State<PageCanaux> createState() => _PageCanauxState();
}

class _PageCanauxState extends State<PageCanaux> {
  // Étape 1 : infos appareil
  String _infos = 'Appuyez sur le bouton';

  Future<void> _lireInfos() async {
    final i = await CanauxNatifs.lireInfos();

    setState(
      () => _infos =
          '${i['marque']} ${i['modele']}\nAndroid ${i['version']} (API ${i['sdk']})',
    );
  }

  // Message
  void _message(String texte) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texte)));

  //  vibration
  Future<void> _vibrer(String motif) async {
    try {
      await CanauxNatifs.vibrer(motif);
      _message('Vibration « $motif »');
    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  //  capteur de lumière
  double? _lux;
  StreamSubscription<double>? _abonnementLumiere;

  void _basculerLumiere() {
    if (_abonnementLumiere == null) {
      _abonnementLumiere = CanauxNatifs.lumiere().listen(
        (lux) {
          if (mounted) setState(() => _lux = lux);
        },
        onError: (e) {
          _message('Capteur : $e');
        },
      );
    } else {
      _abonnementLumiere!.cancel();
      _abonnementLumiere = null;
    }

    setState(() {});
  }

  // niveau sonore
  double? _db;
  StreamSubscription<double>? _abonnementAudio;

  Future<void> _basculerMicro() async {
    if (_abonnementAudio != null) {
      await _abonnementAudio!.cancel();
      setState(() => _abonnementAudio = null);
      return;
    }

    try {
      final accordee = await CanauxNatifs.demanderMicro();

      if (!accordee) {
        _message('Permission micro refusée');
        return;
      }

      setState(() {
        _abonnementAudio = CanauxNatifs.niveauSonore().listen(
          (db) {
            if (mounted) setState(() => _db = db);
          },
          onError: (e) {
            _message('Micro : $e');
          },
        );
      });
    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // capteur de proximité
  bool? _proche;
  StreamSubscription<bool>? _abonnementProximite;

  void _basculerProximite() {
    if (_abonnementProximite == null) {
      _abonnementProximite = CanauxNatifs.proximite().listen(
        (proche) {
          if (mounted) {
            setState(() => _proche = proche);
          }
        },
        onError: (e) {
          _message('Proximité : $e');
        },
      );
    } else {
      _abonnementProximite!.cancel();
      _abonnementProximite = null;
    }

    setState(() {});
  }

  //  lampe torche
  bool _torcheAllumee = false;

  Future<void> _basculerTorche(bool etat) async {
    try {
      await CanauxNatifs.allumerTorche(etat);

      if (mounted) {
        setState(() => _torcheAllumee = etat);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _torcheAllumee = false);
        _message('Erreur ${e.code} : ${e.message}');
      }
    }
  }

  // Libération des abonnements
  @override
  void dispose() {
    _abonnementLumiere?.cancel();
    _abonnementAudio?.cancel();
    _abonnementProximite?.cancel();
    super.dispose();
  }

  // Carte
  Widget _carte(String titre, List<Widget> contenu) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...contenu,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TP 3 – Platform Channels')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte 1 : infos appareil
          _carte('1. Infos appareil (MethodChannel)', [
            Text(_infos),
            const SizedBox(height: 8),
            FilledButton(onPressed: _lireInfos, child: const Text('Lire')),
          ]),

          // Carte 2 : vibration
          _carte('2. Vibration (arguments + erreurs)', [
            Wrap(
              spacing: 8,
              children: [
                for (final m in ['court', 'long', 'sos', 'disco'])
                  OutlinedButton(onPressed: () => _vibrer(m), child: Text(m)),
              ],
            ),
          ]),

          // Carte 3 : capteur de lumière
          _carte('3. Capteur de lumière (EventChannel)', [
            Text(
              _lux == null ? '—' : '${_lux!.toStringAsFixed(0)} lux',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerLumiere,
              child: Text(_abonnementLumiere == null ? 'Démarrer' : 'Arrêter'),
            ),
          ]),

          // Carte 4 : niveau sonore
          _carte('4. Niveau sonore (permission + coroutine)', [
            Text(
              _db == null ? '—' : '${_db!.toStringAsFixed(1)} dBFS',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (((_db ?? -90) + 90) / 90).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerMicro,
              child: Text(_abonnementAudio == null ? 'Écouter' : 'Arrêter'),
            ),
          ]),

          // Exercice 1 : proximité
          _carte('Exercice 1. Capteur de proximité', [
            Text(
              _proche == null
                  ? 'En attente...'
                  : (_proche! ? 'Proche' : 'Loin'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerProximite,
              child: Text(
                _abonnementProximite == null ? 'Démarrer' : 'Arrêter',
              ),
            ),
          ]),

          // lampe torche
          _carte('Exercice 2. Lampe torche', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Allumer / Éteindre'),
                Switch(value: _torcheAllumee, onChanged: _basculerTorche),
              ],
            ),
            Text(_torcheAllumee ? 'Torche allumée' : 'Torche éteinte'),
          ]),
        ],
      ),
    );
  }
}
