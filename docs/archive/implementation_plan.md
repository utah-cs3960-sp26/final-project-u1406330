# Archived Gem Factory Implementation Plan

This is an earlier phase-based plan kept for historical context. It is not the source of truth for current behavior. For the live implementation snapshot, read [../current_state.md](../current_state.md).

Archive note: the current implementation has since pivoted to mine-based geode acquisition. Geodes are earned by mining while standing inside the mine, and the shop now sells permanent coin-priced pickaxes only. Older references below to direct geode buying or a geode shop are historical.

## Project Direction

This plan adapts the project into **Gem Factory**, a cave-themed idle progression game built around geodes, resources, stations, and passive growth.

### Chosen direction
- Use plain Rojo + Luau modules
- Keep a lightweight service/controller architecture
- Start with mock persistence
- Use shared-map cave plots
- Use grid-based placement for MVP
- Let geode timers continue while offline

### Why this fits
- The project is still early, so simple architecture keeps iteration fast
- The game needs deterministic economy and timer logic more than a heavy framework
- Grid placement and cave plots fit the fantasy without overcomplicating MVP scope

## Architecture Overview

### Principles
- Server owns reward-generating logic
- Shared modules contain config, types, and pure math
- Client handles presentation, previews, and input
- Static game data stays separate from player-owned instance data
- Workspace models are only a projection of authoritative state

### Recommended structure

```text
src/
  client/
    Controllers/
      AppController.luau
      HUDController.luau
      ShopController.luau
      GeodeController.luau
      PlotController.luau
      PlacementController.luau
      DailyRewardsController.luau
      NotificationsController.luau
  server/
    Services/
      PlayerDataService.luau
      MockPersistenceService.luau
      EconomyService.luau
      GeodeService.luau
      GeodeQueueService.luau
      StationService.luau
      PlacementService.luau
      PlotService.luau
      ShopService.luau
      DailyRewardsService.luau
      OfflineProgressService.luau
      WorldReplicaService.luau
  shared/
    Config/
      Resources.luau
      Geodes.luau
      Traits.luau
      Stations.luau
      Economy.luau
      Shops.luau
      DailyRewards.luau
      World.luau
    Domain/
      GeodeRoller.luau
      TraitRoller.luau
      EconomyMath.luau
      OfflineMath.luau
      ShopRotation.luau
      PlacementRules.luau
    Types/
      PlayerProfile.luau
      ResourceTypes.luau
      StationTypes.luau
```

## Data Model

### Static config should define
- Resource types and rarity
- Geode pools and odds
- Trait odds and multipliers
- Station definitions and upgrade curves
- Economy multipliers and caps
- Shop rotations
- Daily rewards
- Plot dimensions and placement rules

### Player profile should include
- `currencies`
- `resourcesById`
- `resourceOrder`
- `stationsById`
- `placedObjects`
- `geodeQueue`
- `unclaimedOfflineRewards`
- `dailyRewards`
- `progression`
- `plotState`
- `session`
- `meta`

### Data rules
- Give every resource and station a stable unique ID
- Save timers as absolute Unix timestamps
- Keep placed state separate from ownership state
- Version the schema immediately

## Main Modules

## Shared config
- Holds resources, geodes, traits, stations, shops, economy, and world values

## PlayerDataService
- Loads, reconciles, updates, and saves profiles

## MockPersistenceService
- Stores and seeds profile snapshots during development

## EconomyService
- Calculates passive income from placed resources and station bonuses

## GeodeService
- Validates purchases and rolls geode outcomes into resource instances

## GeodeQueueService
- Manages timed geode progression and finished reveals

## StationService
- Owns station creation, upgrades, capacity, and bonuses

## PlacementService
- Validates grid placement and occupancy

## PlotService
- Assigns and releases cave plots in the shared map

## WorldReplicaService
- Renders cave plots, stations, and displayed resources into Workspace

## ShopService
- Exposes permanent offers and hourly rotations

## OfflineProgressService
- Calculates offline coins and resolves finished geodes

## DailyRewardsService
- Owns streaks, claim windows, and reward grants

## Networking Plan

### Core remotes
- `RequestBuyGeode`
- `RequestClaimFinishedGeode`
- `RequestPlaceStation`
- `RequestMovePlacedObject`
- `RequestUpgradeStation`
- `RequestClaimDailyReward`
- `RequestCollectOfflineRewards`
- `GetInitialState`
- `StateUpdated`
- `ShopRotationUpdated`
- `RareBreakAnnounced`

### Rules
- Client never sends trusted reward values
- Server validates costs, placements, and queue state
- Start with coarse state updates, optimize later

## Testing Strategy

### Deterministic tests
- Geode roll distribution
- Trait roll distribution
- Hourly rotation math
- Offline earnings clamp logic
- Offline geode completion
- Station income calculations
- Placement occupancy validation

### Debug tools
- Grant coins/geodes command
- Bulk geode roll simulator
- Offline progression simulator
- Plot occupancy visualizer
- Seeded replay scenarios for bugs

## Implementation Phases

## Phase 0
- Project skeleton
- Bootstrap modules
- Shared folders
- Mock persistence
- README update

## Phase 1
- Resource, geode, trait, station, and world config
- Pure math modules
- Tests for deterministic logic

## Phase 2
- Player profiles
- Plot assignment
- Cave plot rendering
- Initial state sync

## Phase 3
- Starter currencies
- Geode purchases
- Geode queue
- Reveal completion
- Starter station
- Grid placement
- Passive income
- Minimal HUD and shop UI

## Phase 4
- Offline progression
- Finished offline geodes
- Offline summary UI

## Phase 5
- Daily rewards
- Hourly rotation
- Shop countdown UI

## Phase 6
- Better cave visuals
- Collection showcase
- Rare break announcements
- Stronger progression prompts

## Phase 7
- More cave biomes
- Refinement depth
- Zone unlocks
- Prestige hooks

## Phase 8
- Real persistence
- Data migration
- Analytics
- Admin/debug tooling
- Event pipeline

## MVP Scope

Include:
- Shared world with instanced cave plots
- 3 geode types
- 10 to 15 resources
- 1 trait layer
- 2 to 3 station types
- Grid placement
- Passive income
- Real-time geode queue
- Offline coins and offline geode completion
- Basic daily rewards
- Basic rotating geode shop

Exclude for now:
- Trading
- Gifting
- Advanced events
- Monetization depth
- Prestige
- Collection book
- Complex synergies
- Freeform placement

## Risks

### Save schema drift
- Mitigate with typed templates and schema versions

### Reward logic becoming hard to test
- Keep roll math and economy formulas in pure shared modules

### Offline inconsistencies
- Save absolute end timestamps and centralize offline calculation

### World and save state drifting apart
- Treat Workspace as a replica only

### UI getting too complex too early
- Start with simple controller-driven UI

## Next Recommended Build Order

1. Keep `gem_factory_design.md` as the canonical design doc and treat `build_a_zoo_design.md` as migration-only.
2. Define resources, geodes, traits, stations, and cave world config.
3. Keep player profile fields aligned with resources, stations, and geode queues.
4. Rework deterministic roll and economy modules around geodes and traits.
5. Rework server services around geode buying, queueing, and resource reveals.
6. Rework placement and world visuals toward cave plots and display stations.
7. Update HUD and shop UI terminology.
8. Add debug and balancing tools.

## Final Recommendation

Build Gem Factory as a small, testable set of deterministic shared modules plus thin server and client layers. The most important systems to get right first are profile integrity, geode timing, reward math, placement, and offline progression. Once those are stable, the cave theme and visual spectacle can scale cleanly.

