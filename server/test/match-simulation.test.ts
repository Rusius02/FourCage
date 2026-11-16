import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { homePosition, MatchSimulation, type MatchPlayer } from "../src/match/match-simulation.js";

function createPlayers(): MatchPlayer[] {
  return Array.from({ length: 4 }, (_, slot) => {
    const home = homePosition(slot);
    return {
      slot,
      sessionId: slot === 2 ? "human-session" : "",
      isBot: slot !== 2,
      x: home.x,
      y: home.y,
      lives: 3,
      direction: 0,
      boost: 0,
    };
  });
}

describe("authoritative match simulation", () => {
  it("moves each goalkeeper only along its own goal line", () => {
    const simulation = new MatchSimulation(createPlayers());

    simulation.setInput(2, 1, 0);
    simulation.update(0.05);

    assert.ok(simulation.players[2].x > 0.5);
    assert.equal(simulation.players[2].y, 0.945);
  });

  it("accelerates the ball after a goalkeeper collision", () => {
    const simulation = new MatchSimulation(createPlayers());
    simulation.ballX = 0.5;
    simulation.ballY = 0.89;
    const initialSpeed = simulation.ballSpeed;

    simulation.update(0.05);

    assert.ok(simulation.ballSpeed > initialSpeed);
  });

  it("removes a life when the ball enters a live goal", () => {
    const simulation = new MatchSimulation(createPlayers());
    simulation.ballX = 0.5;
    simulation.ballY = 0.03;

    simulation.update(0.016);

    assert.equal(simulation.players[0].lives, 2);
    assert.equal(simulation.ballX, 0.5);
    assert.equal(simulation.ballY, 0.5);
  });
});
