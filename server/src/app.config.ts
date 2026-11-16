import { defineServer } from "@colyseus/core";

const appConfig = defineServer({
  rooms: {},
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
