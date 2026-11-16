export interface MatchPlayer {
  slot: number;
  sessionId: string;
  isBot: boolean;
  x: number;
  y: number;
  lives: number;
  direction: number;
  boost: number;
}

export type MatchPhase = "playing" | "finished";

type Vector = { x: number; y: number };

const homes: readonly Vector[] = [
  { x: 0.5, y: 0.055 },
  { x: 0.945, y: 0.5 },
  { x: 0.5, y: 0.945 },
  { x: 0.055, y: 0.5 },
];
const playerRadius = 0.034;
const ballRadius = 0.018;
const goalHalfWidth = 0.19;
const goalLine = 0.043;
const goalkeeperMinimum = 0.5 - goalHalfWidth + playerRadius;
const goalkeeperMaximum = 0.5 + goalHalfWidth - playerRadius;
const humanSpeed = 0.42;
const botSpeed = 0.3;
const collisionAcceleration = 1.12;
const baseBallSpeed = 0.52;
const maximumTravelPerStep = 0.012;
const kickoffVelocity = { x: 0.34, y: 0.42 };

const add = (left: Vector, right: Vector): Vector => ({
  x: left.x + right.x,
  y: left.y + right.y,
});
const subtract = (left: Vector, right: Vector): Vector => ({
  x: left.x - right.x,
  y: left.y - right.y,
});
const scale = (value: Vector, amount: number): Vector => ({
  x: value.x * amount,
  y: value.y * amount,
});
const dot = (left: Vector, right: Vector): number =>
  left.x * right.x + left.y * right.y;
const length = (value: Vector): number => Math.hypot(value.x, value.y);
const normalized = (value: Vector): Vector => {
  const magnitude = length(value);
  return magnitude === 0
    ? { x: 0, y: 0 }
    : { x: value.x / magnitude, y: value.y / magnitude };
};
const clamp = (value: number, minimum: number, maximum: number): number =>
  Math.min(maximum, Math.max(minimum, value));

export class MatchSimulation {
  readonly players: MatchPlayer[];
  ballX = 0.5;
  ballY = 0.5;
  announcement = "";
  phase: MatchPhase = "playing";
  winnerSlot = -1;
  private ballVelocity: Vector = { ...kickoffVelocity };
  private resetSeconds = 0;
  private announcementSeconds = 0;

  get ballSpeed(): number {
    return length(this.ballVelocity);
  }

  constructor(players: MatchPlayer[]) {
    this.players = players;
  }

  update(deltaSeconds: number): void {
    if (this.phase !== "playing") return;
    const delta = clamp(deltaSeconds, 0, 0.05);
    this.announcementSeconds = Math.max(
      0,
      this.announcementSeconds - delta,
    );
    if (this.announcementSeconds === 0) this.announcement = "";

    if (this.resetSeconds > 0) {
      this.resetSeconds = Math.max(0, this.resetSeconds - delta);
      if (this.resetSeconds === 0) this.resetPositions();
      return;
    }

    const fastestSpeed = Math.max(
      length(this.ballVelocity),
      humanSpeed * (1 + 0.75 * Math.max(...this.players.map((p) => p.boost))),
    );
    const steps = Math.max(
      1,
      Math.ceil((fastestSpeed * delta) / maximumTravelPerStep),
    );
    const stepDuration = delta / steps;

    for (let step = 0; step < steps; step++) {
      this.movePlayers(stepDuration);
      this.moveBall(stepDuration);
      if (this.phase !== "playing" || this.resetSeconds > 0) break;
    }
  }

  setInput(slot: number, direction: number, boost: number): void {
    const player = this.players[slot];
    if (!player || player.isBot || player.lives <= 0) return;
    player.direction = direction;
    player.boost = boost;
  }

  replaceWithBot(slot: number): void {
    const player = this.players[slot];
    if (!player || player.lives <= 0) return;
    player.isBot = true;
    player.sessionId = "";
    player.direction = 0;
    player.boost = 0;
  }

  private movePlayers(delta: number): void {
    for (const player of this.players) {
      if (player.lives <= 0) continue;
      const input = player.isBot
        ? this.botInput(player)
        : this.worldInput(player);
      const speed = player.isBot
        ? botSpeed
        : humanSpeed * (1 + 0.75 * player.boost);

      if (player.slot === 0 || player.slot === 2) {
        player.x = clamp(
          player.x + input.x * speed * delta,
          goalkeeperMinimum,
          goalkeeperMaximum,
        );
        player.y = homes[player.slot].y;
      } else {
        player.y = clamp(
          player.y + input.y * speed * delta,
          goalkeeperMinimum,
          goalkeeperMaximum,
        );
        player.x = homes[player.slot].x;
      }
    }
  }

  private worldInput(player: MatchPlayer): Vector {
    switch (player.slot) {
      case 0:
        return { x: -player.direction, y: 0 };
      case 1:
        return { x: 0, y: player.direction };
      case 2:
        return { x: player.direction, y: 0 };
      default:
        return { x: 0, y: -player.direction };
    }
  }

  private botInput(player: MatchPlayer): Vector {
    if (player.slot === 0 || player.slot === 2) {
      const difference = this.ballX - player.x;
      return {
        x: Math.abs(difference) < 0.01 ? 0 : Math.sign(difference),
        y: 0,
      };
    }
    const difference = this.ballY - player.y;
    return {
      x: 0,
      y: Math.abs(difference) < 0.01 ? 0 : Math.sign(difference),
    };
  }

  private moveBall(delta: number): void {
    this.ballX += this.ballVelocity.x * delta;
    this.ballY += this.ballVelocity.y * delta;

    for (const player of this.players) {
      if (player.lives <= 0) continue;
      const offset = subtract(
        { x: this.ballX, y: this.ballY },
        { x: player.x, y: player.y },
      );
      const distance = length(offset);
      const minimumDistance = playerRadius + ballRadius;
      if (distance >= minimumDistance) continue;

      const normal =
        distance > 0 ? scale(offset, 1 / distance) : this.facing(player.slot);
      const resolved = add(
        { x: player.x, y: player.y },
        scale(normal, minimumDistance),
      );
      this.ballX = resolved.x;
      this.ballY = resolved.y;
      this.onPlayerCollision(player, normal);
    }

    if (this.ballY < goalLine && this.isGoalOpening(this.ballX)) {
      this.score(0);
      return;
    }
    if (this.ballX > 1 - goalLine && this.isGoalOpening(this.ballY)) {
      this.score(1);
      return;
    }
    if (this.ballY > 1 - goalLine && this.isGoalOpening(this.ballX)) {
      this.score(2);
      return;
    }
    if (this.ballX < goalLine && this.isGoalOpening(this.ballY)) {
      this.score(3);
      return;
    }

    this.bounceOffWalls();
  }

  private onPlayerCollision(player: MatchPlayer, normal: Vector): void {
    const incomingSpeed = length(this.ballVelocity);
    const approachSpeed = dot(this.ballVelocity, normal);
    let outgoing =
      approachSpeed < 0
        ? subtract(this.ballVelocity, scale(normal, 2 * approachSpeed))
        : this.ballVelocity;
    const input = player.isBot ? this.botInput(player) : this.worldInput(player);
    outgoing = add(outgoing, scale(input, 0.16));
    if (length(outgoing) ** 2 < 0.0001) outgoing = normal;

    const acceleratedSpeed =
      Math.max(incomingSpeed, baseBallSpeed) * collisionAcceleration;
    this.ballVelocity = scale(normalized(outgoing), acceleratedSpeed);
  }

  private bounceOffWalls(): void {
    if (this.ballX < goalLine || this.ballX > 1 - goalLine) {
      this.ballVelocity = { x: -this.ballVelocity.x, y: this.ballVelocity.y };
      this.ballX = clamp(this.ballX, goalLine, 1 - goalLine);
    }
    if (this.ballY < goalLine || this.ballY > 1 - goalLine) {
      this.ballVelocity = { x: this.ballVelocity.x, y: -this.ballVelocity.y };
      this.ballY = clamp(this.ballY, goalLine, 1 - goalLine);
    }
  }

  private isGoalOpening(position: number): boolean {
    return Math.abs(position - 0.5) < goalHalfWidth;
  }

  private score(targetSlot: number): void {
    const target = this.players[targetSlot];
    if (target.lives <= 0) {
      switch (targetSlot) {
        case 0:
          this.ballVelocity = {
            x: this.ballVelocity.x,
            y: Math.abs(this.ballVelocity.y),
          };
          this.ballY = clamp(this.ballY, goalLine, 1 - goalLine);
          break;
        case 1:
          this.ballVelocity = {
            x: -Math.abs(this.ballVelocity.x),
            y: this.ballVelocity.y,
          };
          this.ballX = clamp(this.ballX, goalLine, 1 - goalLine);
          break;
        case 2:
          this.ballVelocity = {
            x: this.ballVelocity.x,
            y: -Math.abs(this.ballVelocity.y),
          };
          this.ballY = clamp(this.ballY, goalLine, 1 - goalLine);
          break;
        default:
          this.ballVelocity = {
            x: Math.abs(this.ballVelocity.x),
            y: this.ballVelocity.y,
          };
          this.ballX = clamp(this.ballX, goalLine, 1 - goalLine);
      }
      return;
    }

    target.lives--;
    this.announcement =
      target.lives === 0 ? `${target.isBot ? "BOT" : "JOUEUR"} ÉLIMINÉ` : "BUT !";
    this.announcementSeconds = 1.5;
    this.ballVelocity = { x: 0, y: 0 };
    this.ballX = 0.5;
    this.ballY = 0.5;
    this.resetSeconds = 1.1;

    const survivors = this.players.filter((player) => player.lives > 0);
    if (survivors.length <= 1) {
      this.phase = "finished";
      this.winnerSlot = survivors[0]?.slot ?? -1;
      this.resetSeconds = 0;
    }
  }

  private resetPositions(): void {
    for (const player of this.players) {
      if (player.lives <= 0) continue;
      player.x = homes[player.slot].x;
      player.y = homes[player.slot].y;
    }
    this.ballX = 0.5;
    this.ballY = 0.5;
    this.ballVelocity = { ...kickoffVelocity };
  }

  private facing(slot: number): Vector {
    switch (slot) {
      case 0:
        return { x: 0, y: 1 };
      case 1:
        return { x: -1, y: 0 };
      case 2:
        return { x: 0, y: -1 };
      default:
        return { x: 1, y: 0 };
    }
  }
}

export function homePosition(slot: number): Vector {
  return { ...homes[slot] };
}
