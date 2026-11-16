import { defineRoom, defineServer } from "@colyseus/core";

import { MatchRoom } from "./rooms/match-room.js";

const appConfig = defineServer({
  rooms: {
    match: defineRoom(MatchRoom),
  },
  express: (app) => {
    app.get("/health", (_request, response) => {
      response.status(200).json({
        status: "ok",
        service: "fourcage-server",
      });
    });
  },
});

export default appConfig;
