import 'dart:async';

import 'package:colyseus/colyseus.dart';
import 'package:flutter/foundation.dart';

class OnlinePlayerSnapshot {
  const OnlinePlayerSnapshot({
    required this.slot,
    required this.sessionId,
    required this.isBot,
    required this.x,
    required this.y,
    required this.lives,
  });

  final int slot;
  final String sessionId;
  final bool isBot;
  final double x;
  final double y;
  final int lives;
}

class OnlineMatchSession extends ChangeNotifier {
  OnlineMatchSession._(this._client, this._room) {
    _stateSubscription = _room.onStateChange.listen(_readState);
    _errorSubscription = _room.onError.listen((error) {
      errorMessage = error.message;
      notifyListeners();
    });
    _dropSubscription = _room.onDrop.listen((_) {
      isReconnecting = true;
      notifyListeners();
    });
    _reconnectSubscription = _room.onReconnect.listen((_) {
      isReconnecting = false;
      _readState(_room.state);
    });
    _leaveSubscription = _room.onLeave.listen((code) {
      if (_closing) return;
      errorMessage = 'Connexion au match interrompue (code $code).';
      notifyListeners();
    });
    _readState(_room.state);
  }

  static const defaultServerUrl = String.fromEnvironment(
    'COLYSEUS_SERVER_URL',
    defaultValue: 'ws://10.0.2.2:2567',
  );
  static const _joinTimeout = Duration(seconds: 8);
  static const _initialStateTimeout = Duration(seconds: 5);
  static const _minimumInputInterval = Duration(milliseconds: 34);

  final ColyseusClient _client;
  final ColyseusRoom<SchemaInstance> _room;
  late final StreamSubscription<SchemaInstance> _stateSubscription;
  late final StreamSubscription<ColyseusError> _errorSubscription;
  late final StreamSubscription<ColyseusError> _dropSubscription;
  late final StreamSubscription<void> _reconnectSubscription;
  late final StreamSubscription<int> _leaveSubscription;
  final Stopwatch _inputClock = Stopwatch()..start();

  Timer? _inputTimer;
  Duration? _lastInputSentAt;
  double _pendingDirection = 0;
  double _pendingBoost = 0;
  double _lastDirectionSent = double.nan;
  double _lastBoostSent = double.nan;
  bool _closing = false;

  String phase = 'connecting';
  int secondsRemaining = 10;
  int? localSlot;
  int winnerSlot = -1;
  double ballX = 0.5;
  double ballY = 0.5;
  String announcement = '';
  String? errorMessage;
  bool isReconnecting = false;
  List<OnlinePlayerSnapshot> players = const [];

  int get humanCount => players.where((player) => !player.isBot).length;
  int get botCount => players.where((player) => player.isBot).length;
  bool get isConnected => _room.isConnected;

  static Future<OnlineMatchSession> connect({String? serverUrl}) async {
    final endpoint = serverUrl ?? defaultServerUrl;
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        (uri.scheme != 'ws' && uri.scheme != 'wss') ||
        uri.host.isEmpty) {
      throw const FormatException('Adresse du serveur Colyseus invalide.');
    }
    if (kReleaseMode && uri.scheme != 'wss') {
      throw StateError(
        'Une adresse wss:// est obligatoire pour le multijoueur en version '
        'de production.',
      );
    }

    final client = ColyseusClient(endpoint);
    ColyseusRoom<SchemaInstance>? room;
    try {
      room = await client
          .joinOrCreate<SchemaInstance>('match')
          .timeout(_joinTimeout);
      room.setReconnectionOptions(
        enabled: true,
        maxRetries: 5,
        minDelayMs: 250,
        maxDelayMs: 1000,
      );
      final session = OnlineMatchSession._(client, room);
      if (room.state == null) {
        await room.onStateChange.first.timeout(_initialStateTimeout);
        session._readState(room.state);
      }
      return session;
    } catch (_) {
      if (room != null) {
        if (room.isConnected) await room.leave();
        room.dispose();
      }
      client.dispose();
      rethrow;
    }
  }

  void sendInput(double direction, double boost) {
    if (_closing) return;
    _pendingDirection = direction.clamp(-1, 1).toDouble();
    _pendingBoost = boost.clamp(0, 1).toDouble();
    _scheduleInput();
  }

  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    _inputTimer?.cancel();
    await Future.wait([
      _stateSubscription.cancel(),
      _errorSubscription.cancel(),
      _dropSubscription.cancel(),
      _reconnectSubscription.cancel(),
      _leaveSubscription.cancel(),
    ]);
    try {
      if (_room.isConnected) await _room.leave();
    } finally {
      _room.dispose();
      _client.dispose();
      super.dispose();
    }
  }

  void _scheduleInput() {
    if (_inputTimer != null || phase != 'playing' || localSlot == null) return;
    final now = _inputClock.elapsed;
    final lastSent = _lastInputSentAt;
    final wait = lastSent == null
        ? Duration.zero
        : _minimumInputInterval - (now - lastSent);
    _inputTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      _inputTimer = null;
      if (_closing ||
          phase != 'playing' ||
          localSlot == null ||
          !_room.isConnected) {
        return;
      }
      if (_pendingDirection == _lastDirectionSent &&
          (_pendingBoost - _lastBoostSent).abs() < 0.02) {
        return;
      }
      _room.send('move', {
        'direction': _pendingDirection,
        'boost': _pendingBoost,
      });
      _lastDirectionSent = _pendingDirection;
      _lastBoostSent = _pendingBoost;
      _lastInputSentAt = _inputClock.elapsed;
    });
  }

  void _readState(SchemaInstance? state) {
    if (state == null || _closing) return;

    final currentPhase = state['phase'];
    if (currentPhase is String) phase = currentPhase;
    final seconds = state['secondsRemaining'];
    if (seconds is num) secondsRemaining = seconds.toInt();
    final currentWinner = state['winnerSlot'];
    if (currentWinner is num) winnerSlot = currentWinner.toInt();
    final currentBallX = state['ballX'];
    if (currentBallX is num) ballX = currentBallX.toDouble();
    final currentBallY = state['ballY'];
    if (currentBallY is num) ballY = currentBallY.toDouble();
    final currentAnnouncement = state['announcement'];
    if (currentAnnouncement is String) announcement = currentAnnouncement;

    final playerMap = state.getMap('players');
    final updatedPlayers = <OnlinePlayerSnapshot>[];
    int? updatedLocalSlot;
    if (playerMap != null) {
      for (final entry in playerMap.entries) {
        final value = entry.value;
        if (value is! SchemaInstance) continue;
        final slotValue = value['slot'];
        final sessionIdValue = value['sessionId'];
        final isBotValue = value['isBot'];
        final xValue = value['x'];
        final yValue = value['y'];
        final livesValue = value['lives'];
        if (slotValue is! num ||
            sessionIdValue is! String ||
            isBotValue is! bool ||
            xValue is! num ||
            yValue is! num ||
            livesValue is! num) {
          continue;
        }

        final slot = slotValue.toInt();
        updatedPlayers.add(
          OnlinePlayerSnapshot(
            slot: slot,
            sessionId: sessionIdValue,
            isBot: isBotValue,
            x: xValue.toDouble(),
            y: yValue.toDouble(),
            lives: livesValue.toInt(),
          ),
        );
        if (sessionIdValue == _room.sessionId) updatedLocalSlot = slot;
      }
    }

    updatedPlayers.sort((left, right) => left.slot.compareTo(right.slot));
    players = updatedPlayers;
    localSlot = updatedLocalSlot;
    notifyListeners();
    _scheduleInput();
  }
}
