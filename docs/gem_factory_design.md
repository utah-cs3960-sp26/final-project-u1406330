# Gem Factory Design Document

## Overview

Gem Factory is a Roblox idle progression game about turning a rough cave plot into a glowing gem operation. Players buy geodes, wait for them to crack, reveal resources, place stations, and reinvest passive income into rarer finds and better production.

The current implementation is a narrow MVP slice of this design. Anything listed as future direction should be treated as product intent, not current behavior. For current behavior, read [current_state.md](current_state.md).

## Core Fantasy

The player starts with a small cave lot and slowly turns it into a richer gem factory filled with crystal displays, rare minerals, glowing machinery, and valuable finds.

The main emotional hooks are:

1. Owning and improving a personal cave-factory.
2. Anticipating a geode reveal.
3. Chasing rare resources and traits.
4. Seeing passive income grow from placed stations.
5. Returning to timers, restocks, and offline rewards.

## Current MVP Loop

1. Buy a starter geode.
2. Place the owned geode on the player plot.
3. Wait for its timer to finish.
4. Crack the ready geode in the world.
5. Place a station.
6. Auto-slot revealed resources into available station capacity.
7. Earn passive income online and collect offline progress later.

## Current MVP Systems

### Geodes

Geodes are bought through the shop/HUD, stored as owned items, placed on the plot, and opened after their timer completes.

Implemented geodes:

1. Starter Geode.
2. Crystal Cavern Geode.
3. Moonlit Geode.

### Resources

Resources are revealed from geodes and generate value when assigned to stations.

Implemented resources:

1. Quartz.
2. Amethyst.
3. Emerald Cluster.
4. Diamond Core.
5. Star Shard.

### Stations

Stations hold revealed resources and multiply or enable passive income.

Implemented stations:

1. Crystal Display.
2. Resonance Pedestal.

### Passive And Offline Progress

Passive income should continue to matter even when the player is away. The current slice supports online passive income and offline reward summaries. Finished offline geodes remain ready to open instead of being auto-opened.

### Shop And Daily Hooks

The current project includes shop rotation and daily reward systems. These are meant to create recurring reasons to check in without requiring deep mechanics yet.

## Design Principles

### Idle Progression

Players should feel progress continuing while they are not actively playing. Offline rewards should be understandable and should avoid surprising state changes, especially around geode reveals.

### Variable Rewards

Geode rewards should use weighted pools. Trait rolls should make ordinary resources occasionally feel special.

### Timed Scarcity

Hourly rotations, daily rewards, and future event geodes should give players reasons to return.

### Visible Growth

The cave should physically improve as the player gains better resources, stations, and production capacity.

### Server Authority

The server owns purchases, reward rolls, placement validation, profile mutation, and offline calculation. The client presents state and requests actions.

## Future Direction

The following systems are design targets, not all current implementation:

- More geode categories such as biome, premium, event, and achievement geodes.
- More resources, traits, and rarity tiers.
- Station upgrades and specialized station roles.
- Refinement or duplicate-combining systems.
- Cave zone unlocks.
- Prestige with permanent bonuses.
- Weekly events and limited geode pools.
- Stronger social comparison through nearby plots, leaderboards, and rare reveal announcements.
- Real persistence, migration tooling, analytics, and admin/debug tools.

## Technical Direction

### Server Responsibilities

1. Validate purchases and placement.
2. Roll geode outcomes.
3. Mutate player profiles.
4. Calculate online and offline rewards.
5. Maintain plot assignment.
6. Replicate authoritative world state.
7. Prevent duplication exploits.

### Client Responsibilities

1. Build and update HUD.
2. Handle placement input and local previews.
3. Request actions through remotes.
4. Render local presentation effects.
5. Display timers, rewards, announcements, and shop state.

### Shared Responsibilities

1. Static config.
2. Deterministic math.
3. Type definitions.
4. Remote names.
5. Small reusable utilities.

## MVP Priorities

The most important near-term work is:

1. Make the first geode-to-income loop stable and easy to understand.
2. Improve placement clarity.
3. Make geode reveals feel rewarding.
4. Add repeatable automated verification for deterministic specs.
5. Keep profile, economy, placement, and offline logic testable.
