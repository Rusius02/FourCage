import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/game_palette.dart';
import '../infrastructure/online_match_session.dart';
import 'match_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key, this.serverUrl});

  final String? serverUrl;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  OnlineMatchSession? _session;
  String? _error;
  bool _connecting = true;
  bool _transferred = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    final session = _session;
    if (session != null) {
      session.removeListener(_onSessionChanged);
      if (!_transferred) unawaited(session.close());
    }
    super.dispose();
  }

  Future<void> _connect() async {
    final attempt = ++_attempt;
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      final session = await OnlineMatchSession.connect(
        serverUrl: widget.serverUrl,
      );
      if (!mounted || attempt != _attempt) {
        await session.close();
        return;
      }
      _session = session;
      session.addListener(_onSessionChanged);
      setState(() => _connecting = false);
      _onSessionChanged();
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _connecting = false;
        _error = _friendlyError(error);
      });
    }
  }

  void _onSessionChanged() {
    final session = _session;
    if (!mounted || session == null) return;
    if (session.errorMessage != null) {
      final failedSession = session;
      _session = null;
      failedSession.removeListener(_onSessionChanged);
      setState(() => _error = failedSession.errorMessage);
      unawaited(failedSession.close());
      return;
    }
    if (session.phase == 'playing' &&
        session.localSlot != null &&
        !_transferred) {
      _transferred = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MatchScreen(onlineSession: session),
        ),
      );
      return;
    }
    setState(() {});
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'Le serveur n’a pas répondu à temps. Vérifie ta connexion.';
    }
    if (error is FormatException || error is StateError) {
      return error.toString().replaceFirst('Bad state: ', '');
    }
    return 'Impossible de rejoindre une partie. Vérifie que le serveur '
        'Colyseus est démarré et accessible.';
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final isSearching = !_connecting && _error == null && session != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_rounded, color: gameMint, size: 44),
                  const SizedBox(height: 16),
                  Text(
                    _error == null
                        ? 'RECHERCHE D’UNE PARTIE'
                        : 'CONNEXION IMPOSSIBLE',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_connecting) ...[
                    const CircularProgressIndicator(color: gameMint),
                    const SizedBox(height: 12),
                    const Text(
                      'Connexion au serveur Colyseus…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: gameMuted),
                    ),
                  ] else if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: gameMuted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _connect,
                      child: const Text('RÉESSAYER'),
                    ),
                  ] else if (isSearching) ...[
                    Text(
                      session.isReconnecting
                          ? 'Reconnexion en cours…'
                          : 'Joueurs : ${session.humanCount}/4',
                      style: const TextStyle(
                        color: gameMint,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Démarrage dans ${session.secondsRemaining} s au maximum. '
                      'Les places libres seront confiées aux bots.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: gameMuted),
                    ),
                  ],
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ANNULER'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
