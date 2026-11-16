import assert from "node:assert/strict";
import { after, before, beforeEach, describe, it } from "node:test";
import { boot, type ColyseusTestServer } from "@colyseus/testing";

process.env.FOURCAGE_LOBBY_TIMEOUT_MS = "250";

const appConfig = (await import("../src/app.config.js")).default;

describe("Colyseus match server", () => {
  let colyseus: ColyseusTestServer<typeof appConfig>;

  before(async () => {
    colyseus = await boot(appConfig);
  });

  after(async () => {
    await colyseus.shutdown();
  });

  beforeEach(async () => {
    await colyseus.cleanup();
  });

  it("reports a healthy status over HTTP", async () => {
    const response = await fetch("http://127.0.0.1:2568/health");

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      status: "ok",
      service: "fourcage-server",
    });
  });

  it("fills open seats with bots after the lobby timeout", async () => {
    const room = await colyseus.createRoom("match");
    await colyseus.connectTo(room);

    await new Promise((resolve) => setTimeout(resolve, 450));

    assert.equal(room.state.phase, "playing");
    assert.equal(room.state.players.size, 4);
    assert.equal(
      [...room.state.players.values()].filter((player) => player.isBot).length,
      3,
    );
  });

  it("starts early when four human players fill the room", async () => {
    const room = await colyseus.createRoom("match");

    for (let player = 0; player < 4; player++) {
      await colyseus.connectTo(room);
    }

    assert.equal(room.state.phase, "playing");
    assert.equal(room.state.players.size, 4);
    assert.equal(
      [...room.state.players.values()].filter((player) => player.isBot).length,
      0,
    );
  });

  it("replaces a player who leaves an active match with a bot", async () => {
    const room = await colyseus.createRoom("match");
    const client = await colyseus.connectTo(room);
    await new Promise((resolve) => setTimeout(resolve, 450));

    await client.leave();

    const player = room.state.players.get("slot_0");
    assert.ok(player);
    assert.equal(player.isBot, true);
    assert.equal(player.sessionId, "");
  });

  it("uses only validated movement from the assigned player's session", async () => {
    const room = await colyseus.createRoom("match");
    const client = await colyseus.connectTo(room);

    await new Promise((resolve) => setTimeout(resolve, 450));
    const player = room.state.players.get("slot_0");
    assert.ok(player);

    const startingX = player.x;
    client.send("move", {
      direction: 1,
      boost: 0,
      slot: 2,
      x: 1,
      y: 1,
      lives: 99,
    });
    await new Promise((resolve) => setTimeout(resolve, 150));

    assert.ok(player.x < startingX);
    assert.equal(player.lives, 3);

    client.send("move", { direction: 0, boost: 0 });
    await new Promise((resolve) => setTimeout(resolve, 100));
    const updatedX = player.x;
    client.send("move", { direction: 99, boost: 0 });
    await new Promise((resolve) => setTimeout(resolve, 100));
    assert.equal(player.x, updatedX);
  });
});
