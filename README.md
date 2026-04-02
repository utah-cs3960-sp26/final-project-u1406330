# final-project-u1406330

## Proposal

My final project proposal is a simple Roblox idle game called Gem Factory that uses many of the same game design principles found in the popular Roblox game Grow A Garden. The basic gameplay is described in the MVP Loop and Theme Direction sections below. The idea for this project came from a video I watched analyzing the design of Grow A Garden. The video can be found here: https://www.youtube.com/watch?v=5WQHP7BnQ9M
.

Grow A Garden is intentionally extremely simple, and in some people's opinion it is not even a very good game mechanically. Despite this, it has managed to attract a massive player base. The reason for this is not the gameplay itself, but the psychological strategies the game uses to keep players engaged. The game constantly creates the feeling that something rewarding is about to happen, which makes players stay longer than they planned.

Some of these strategies include

• Idle progression where progress continues even when the player is offline
• Variable rewards such as rare drops and random shop rotations
• Timers and restocks that encourage players to stay just a little longer
• Big number progression where values grow rapidly over time
• Scarcity events such as limited items or weekly updates
• Social comparison where players see other players with larger bases
• A very simple gameplay loop that is easy to understand and repeat

Because of these systems the gameplay itself can be extremely basic while still retaining players effectively.

For the agentic loop in this project, I will build test suites for the backend logic and verify in game features using Roblox Studio, Roblox’s built in development environment. This allows the agent to iterate on the project through both repeatable code level testing and direct gameplay validation.

A natural question is how well an AI agent can actually model and generate parts of a game world. From my testing the results have been surprisingly good. The agent has been able to generate environments, models, and even basic animations and GUI components from prompts.

I think this project is a good fit for an AI agent because the underlying mechanics are extremely simple. Vibe coded games are still often rough around the edges, but this type of game has such a straightforward structure that an agent has a realistic chance of producing something functional.

If the game ends up working well, it would be an interesting demonstration of what AI assisted development is capable of. And if it somehow becomes successful, I might even make a little money from it.

## Current MVP Loop

1. Buy a starter geode from the HUD.
2. Place that geode onto your plot from inventory.
3. Wait for the geode timer to finish.
4. Click the finished geode in the world to crack it open.
5. Place the starter station on the player plot.
6. Let revealed resources auto-slot into the placed station.
7. Watch passive income begin ticking online.

## Theme Direction

- Players collect and break geodes instead of hatching anything zoo-based.
- Rewards are gems, rare minerals, crystals, and other valuable resources.
- Progress should feel like building a richer, busier gem-processing operation inside a magical cavern.
- The long-term fantasy is moving from a tiny starter setup to a high-value gem empire filled with rare finds and premium production upgrades.

## Current Structure

```text
tests/
src/
  client/
    Bootstrap/
    Controllers/
    UI/
  server/
    Bootstrap/
    Services/
    Systems/
  shared/
    Config/
    Domain/
    Net/
    Types/
    Util/
```

## How To Work With This Project

- `src/server/init.server.luau` starts the server bootstrap.
- `src/client/init.client.luau` starts the client bootstrap and creates the HUD.
- Shared config and deterministic math live under `src/shared`.
- Server-owned gameplay services live under `src/server`.
- Client presentation and input controllers live under `src/client`.
- `gem_factory_design.md` is the canonical design document.
- `build_a_zoo_design.md` is retained only as a deprecated migration note.

## Current Slice

- The client requests initial state on startup when the server exposes the remotes.
- The HUD shows currency, passive income, geode inventory status, daily reward status, hourly shop info, plot info, and announcements.
- Buttons are wired for starter geode purchase, manual geode placement, ready geode cracking, starter station placement, daily reward claiming, and offline reward claiming.
- Placing the starter station uses deterministic first-fit placement when the client does not provide coordinates.
- Bought geodes now become owned inventory entries that stay stored until the player places them on their plot, then crack in-world and can be opened once ready.
- Opening a finished geode removes it from the plot, grants the revealed resource, and auto-slots newly revealed resources into available placed stations so passive income can start immediately.
- Passive income accrues online and offline, and the world replica shows simple displayed resources on placed stations.
- The map now uses a shared central cavern floor with 8 larger player plots per server, low-profile plot markers, and deterministic rock-spike variations for display flavor.
- If the server endpoints are not yet wired, the client falls back to a local preview state so the UI still loads.

## Notes

- The project is intentionally minimal right now.
- The structure is built for a shared-map crystal cavern layout with grid placement, offline geode progression, and mock persistence first.
- The shared domain modules now contain deterministic economy, rotation, placement, station-assignment, and geode-resolution math.
- Player profile creation, reconciliation, mock loading/saving, plot assignment, and offline summary generation are wired into server startup.
- The current world direction is a single shared cavern map sized for 8 players, with larger plots and lighter environmental boundaries so builds can breathe.
- The client slice is intentionally minimal, but it is now functional enough to complete the first loop in Studio: buy a geode, place it on the plot, wait for it to finish, open it, place the starter station, and watch passive income begin.

## Verification

- `rojo build default.project.json -o build.rbxlx` succeeds locally.
- Deterministic specs live under `tests/`, including new placement-search and station-assignment coverage.
- A dedicated local automated test runner is not wired in this repo yet, so the specs are currently authored for Studio-side or future runner integration rather than executed from the terminal.