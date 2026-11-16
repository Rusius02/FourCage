import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { boot, type ColyseusTestServer } from "@colyseus/testing";

import appConfig from "../src/app.config.js";

describe("Colyseus server", () => {
  let colyseus: ColyseusTestServer<typeof appConfig>;

  before(async () => {
    colyseus = await boot(appConfig);
  });

  after(async () => {
    await colyseus.shutdown();
  });

  it("reports a healthy status over HTTP", async () => {
    const response = await fetch("http://127.0.0.1:2568/health");

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      status: "ok",
      service: "fourcage-server",
    });
  });
});
