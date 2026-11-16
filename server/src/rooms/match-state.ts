import { MapSchema, Schema, type } from "@colyseus/schema";

export class MatchPlayerState extends Schema {
  @type("number") slot = 0;
  @type("string") sessionId = "";
  @type("boolean") isBot = false;
  @type("number") x = 0;
  @type("number") y = 0;
  @type("uint8") lives = 3;
}

export class MatchState extends Schema {
  @type("string") phase = "waiting";
  @type("uint8") secondsRemaining = 10;
  @type({ map: MatchPlayerState }) players =
    new MapSchema<MatchPlayerState>();
  @type("number") ballX = 0.5;
  @type("number") ballY = 0.5;
  @type("string") announcement = "";
  @type("int8") winnerSlot = -1;
}
