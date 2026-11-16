import { Room, type Client } from "@colyseus/core";

import {
  homePosition,
  MatchSimulation,
  type MatchPlayer,
} from "../match/match-simulation.js";
import { MatchPlayerState, MatchState } from "./match-state.js";

const playerCapacity = 4;
const maximumLobbyWaitMs = 10_000;
const simulationIntervalMs = 1000 / 30;
const minimumInputIntervalMs = 1000 / 30;
const slotKey = (slot: number) => `slot_${slot}`;

function getLobbyTimeoutMs(): number {
  const configured = Number(process.env.FOURCAGE_LOBBY_TIMEOUT_MS);
  if (!Number.isFinite(configured) || configured < 100) {
    return maximumLobbyWaitMs;
  }
  return Math.min(maximumLobbyWaitMs, configured);
}

function isMovePayload(
  payload: unknown,
): payload is { direction: number; boost: number } {
  if (typeof payload !== "object" || payload === null) return false;
  const { direction, boost } = payload as Record<string, unknown>;
  return (
    typeof direction === "number" &&
    Number.isFinite(direction) &&
    direction >= -1 &&
    direction <= 1 &&
    typeof boost === "number" &&
    Number.isFinite(boost) &&
    boost >= 0 &&
    boost <= 1
  );
}

export class MatchRoom extends Room<{ state: MatchState }> {
  maxClients = playerCapacity;
  patchRate = simulationIntervalMs;
  state = new MatchState();

  private readonly lobbyTimeoutMs = getLobbyTimeoutMs();
  private lobbyElapsedMs = 0;
  private readonly sessionSlots = new Map<string, number>();
  private readonly lastInputAt = new Map<string, number>();
  private simulation: MatchSimulation | null = null;

  onCreate(): void {
    this.onMessage("move", (client, payload: unknown) =>
      this.handleMove(client, payload),
    );
    this.setSimulationInterval(
      (deltaTime) => this.update(deltaTime),
      simulationIntervalMs,
    );
  }

  onJoin(client: Client): void {
    if (this.sessionSlots.has(client.sessionId)) return;
    if (this.state.phase !== "waiting") {
      throw new Error("The match has already started.");
    }

    const slot = this.findOpenSlot();
    if (slot < 0) throw new Error("The match is full.");

    this.sessionSlots.set(client.sessionId, slot);
    const player = new MatchPlayerState();
    player.slot = slot;
    player.sessionId = client.sessionId;
    player.x = homePosition(slot).x;
    player.y = homePosition(slot).y;
    this.state.players.set(slotKey(slot), player);

    if (this.sessionSlots.size === playerCapacity) this.startMatch();
  }

  async onDrop(client: Client): Promise<void> {
    const slot = this.sessionSlots.get(client.sessionId);
    if (slot === undefined) return;
    const player = this.state.players.get(slotKey(slot));
    if (!player) return;

    if (this.state.phase === "playing") {
      this.simulation?.setInput(slot, 0, 0);
    }

    try {
      await this.allowReconnection(client, 5);
    } catch {
      this.removeDisconnectedPlayer(client, slot, player);
    }
  }

  onLeave(client: Client): void {
    const slot = this.sessionSlots.get(client.sessionId);
    if (slot === undefined) return;
    const player = this.state.players.get(slotKey(slot));
    if (player) this.removeDisconnectedPlayer(client, slot, player);
  }

  private removeDisconnectedPlayer(
    client: Client,
    slot: number,
    player: MatchPlayerState,
  ): void {
    this.sessionSlots.delete(client.sessionId);
    this.lastInputAt.delete(client.sessionId);
    if (this.state.phase === "waiting") {
      this.state.players.delete(slotKey(slot));
    } else if (this.state.phase === "playing") {
      player.sessionId = "";
      player.isBot = true;
      this.simulation?.replaceWithBot(slot);
    }
  }

  private findOpenSlot(): number {
    for (let slot = 0; slot < playerCapacity; slot++) {
      if (!this.state.players.has(slotKey(slot))) return slot;
    }
    return -1;
  }

  private update(deltaTimeMs: number): void {
    if (this.state.phase === "waiting") {
      this.lobbyElapsedMs += Math.max(0, deltaTimeMs);
      const remainingMs = Math.max(0, this.lobbyTimeoutMs - this.lobbyElapsedMs);
      this.state.secondsRemaining = Math.ceil(remainingMs / 1000);
      if (remainingMs === 0) this.startMatch();
      return;
    }

    if (this.state.phase !== "playing" || !this.simulation) return;
    this.simulation.update(deltaTimeMs / 1000);
    this.copySimulationState();
  }

  private startMatch(): void {
    if (this.state.phase !== "waiting" || this.sessionSlots.size === 0) return;
    this.lock();
    const players: MatchPlayer[] = [];

    for (let slot = 0; slot < playerCapacity; slot++) {
      let state = this.state.players.get(slotKey(slot));
      if (!state) {
        state = new MatchPlayerState();
        const home = homePosition(slot);
        state.slot = slot;
        state.isBot = true;
        state.x = home.x;
        state.y = home.y;
        this.state.players.set(slotKey(slot), state);
      }

      players.push({
        slot,
        sessionId: state.sessionId,
        isBot: state.isBot,
        x: state.x,
        y: state.y,
        lives: state.lives,
        direction: 0,
        boost: 0,
      });
    }

    this.simulation = new MatchSimulation(players);
    this.state.phase = "playing";
    this.state.secondsRemaining = 0;
    this.copySimulationState();
  }

  private handleMove(client: Client, payload: unknown): void {
    if (this.state.phase !== "playing" || !isMovePayload(payload)) return;
    const slot = this.sessionSlots.get(client.sessionId);
    if (slot === undefined) return;

    const now = Date.now();
    const lastInput = this.lastInputAt.get(client.sessionId) ?? 0;
    if (now - lastInput < minimumInputIntervalMs) return;

    this.lastInputAt.set(client.sessionId, now);
    this.simulation?.setInput(slot, payload.direction, payload.boost);
  }

  private copySimulationState(): void {
    if (!this.simulation) return;

    for (const player of this.simulation.players) {
      const state = this.state.players.get(slotKey(player.slot));
      if (!state) continue;
      state.isBot = player.isBot;
      state.x = player.x;
      state.y = player.y;
      state.lives = player.lives;
    }

    this.state.ballX = this.simulation.ballX;
    this.state.ballY = this.simulation.ballY;
    this.state.announcement = this.simulation.announcement;
    this.state.phase = this.simulation.phase;
    this.state.winnerSlot = this.simulation.winnerSlot;
  }
}
