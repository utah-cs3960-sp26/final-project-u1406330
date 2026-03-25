# Gem Factory Design Document

## Overview

**Gem Factory** is a Roblox idle progression game themed around geodes, gems, crystals, metals, and minerals. Players buy geodes, wait for them to crack, reveal valuable resources, display or process them in a cave-like factory plot, and reinvest into rarer finds and better equipment.

The game should always make the player feel like something valuable is about to happen:
1. A geode is about to open
2. A station is about to finish upgrading or processing
3. A rare gem trait might appear
4. A limited geode offer is about to rotate out
5. Offline rewards are waiting

## Core Fantasy

The player starts with a rough cave lot and slowly transforms it into a glowing gem empire filled with crystal displays, rare metals, polished minerals, and efficient processing stations.

The emotional hooks are:
1. Owning a personal cave-factory
2. Surprise from rare geode outcomes
3. Pride from showing off rare finds
4. FOMO from timed geodes and events
5. Satisfaction from big-number growth and automation

## Core Gameplay Loop

### Minute to minute
1. Buy geodes
2. Wait for them to crack
3. Reveal resources
4. Place them into stations or displays
5. Collect passive value
6. Upgrade stations
7. Reinvest into better geodes and machinery

### Session loop
1. Log in
2. Collect offline income
3. Open finished geodes
4. Check the hourly geode rotation
5. Spend on upgrades
6. Chase rare traits
7. Leave with timers still running

### Long-term loop
1. Unlock deeper cave zones
2. Access rarer geode pools
3. Build specialized chambers
4. Improve trait odds
5. Prestige for permanent bonuses
6. Join weekly events

## Design Principles

### Idle progression
- Players should earn progress while offline.
- Offline rewards should include passive coins and finished geode timers.

### Variable rewards
- Geodes use weighted loot tables.
- After the resource roll, a trait roll adds extra excitement.

### Timed scarcity
- Hourly rotating geodes and weekly event geodes give players reasons to return often.

### Visible growth
- The cave should physically improve with more glowing resources, better machinery, and richer decoration.

### Social comparison
- Nearby cave plots, leaderboards, and rare-break announcements should make progress visible to others.

## Main Systems

## Geode System

Geodes are the main acquisition mechanic.

### Geode categories
1. Starter geodes
2. Biome geodes
3. Premium geodes
4. Hourly rotating geodes
5. Event geodes
6. Achievement geodes

### Example geode pool
Crystal Cavern Geode:
1. Quartz: 50%
2. Amethyst: 28%
3. Emerald Cluster: 15%
4. Gold Vein Chunk: 5%
5. Diamond Core: 1.8%
6. Mythic Star Shard: 0.2%

## Trait System

Traits replace the old mutation-style rarity layer.

### Example traits
1. Flawless
2. Prismatic
3. Ancient
4. Radiant
5. Radioactive
6. Void-Touched
7. Celestial

Traits should increase value and make ordinary geodes exciting.

## Resource Economy

Resources generate value based on rarity, trait, and station bonuses.

### Example base rates
1. Quartz: 1 coin per second
2. Iron Cluster: 4 coins per second
3. Amethyst: 12 coins per second
4. Diamond Core: 40 coins per second
5. Event Meteor Crystal: 300 coins per second

### Multipliers
1. Trait multiplier
2. Station multiplier
3. Set or chamber synergy
4. Refinement bonus
5. Prestige bonus
6. Temporary boost

## Station System

Stations are where the player displays, refines, or boosts resources.

### Station roles
1. Hold resources
2. Increase value generation
3. Show progression visually
4. Gate expansion
5. Add synergy mechanics

### Example stations
1. Basic display shelf
2. Crystal polishing table
3. Smelter station
4. Resonance chamber
5. Deep-core extractor
6. Mythic forge

## Refinement System

Duplicates can be combined into better versions.

Example:
1. 3 Quartz -> 1 Refined Quartz
2. 3 Refined Quartz -> 1 Perfect Quartz
3. Better versions produce more value and may add passive bonuses

## Hourly Rotation

Every hour, one global geode rotates into the limited shop.

Example rotation categories:
1. Discounted standard geode
2. Rare biome geode
3. Trait-boost geode
4. Night-only geode
5. Developer spotlight geode
6. Flash event geode

## Daily Rewards

Example streak:
1. Coins
2. Basic geode
3. Boost item
4. Rare reveal
5. Trait token
6. Premium currency
7. Exclusive crystal or event geode

## Events

Example events:
1. Meteor Shower Week
2. Ancient Mine Breakthrough
3. Volcanic Forge Event
4. Frozen Cavern Discovery
5. Deep Earth Expedition
6. Celestial Crystal Festival

## Progression and Economy

### Currencies
1. Coins
2. Gems
3. Event tokens

### Upgrade sinks
1. Geode purchases
2. Station upgrades
3. Cave zone unlocks
4. Trait boosting machines
5. Refinement costs
6. Cosmetics

### Prestige
Prestige should reset most progress in exchange for permanent coin gain, trait chance, and prestige-only content.

## Cave Plot Direction

Plots should feel like stylized cave environments rather than clean factory floors.

Visual direction:
1. Dark stone bases with glowing crystal accents
2. Display pedestals, shelves, and ore piles
3. Machinery embedded into cave walls or platforms
4. Brighter and more magical visuals as the player progresses
5. Space to show off rare gems, crystals, metals, and minerals

## Technical Notes

### Server responsibilities
1. Roll geode outcomes
2. Validate purchases
3. Calculate offline rewards
4. Save data
5. Handle global rotations
6. Prevent duplication exploits

### Client responsibilities
1. Play crack/reveal animations
2. Display timers and UI
3. Render cave visuals
4. Handle local previews
5. Request server actions through remotes

## MVP Scope

### Phase 1 MVP
1. Basic cave plot
2. 3 geode types
3. 10 to 15 resources
4. Passive income
5. Station placement
6. Simple trait system
7. Offline earnings
8. Basic save data
9. Simple shop
10. Daily reward streak

### Later phases
1. More geodes and cave biomes
2. Refinement depth
3. Leaderboards
4. Prestige
5. Event framework

## Early Game Flow

1. Player receives a free starter geode
2. Breaks it open and gets quartz
3. Places it in a starter station
4. Starts earning coins
5. Buys another geode
6. Gets a better mineral or duplicate
7. Upgrades the starter station
8. Notices the hourly geode timer
9. Claims a reward
10. Leaves with timers still running

## Final Positioning

**Gem Factory** should succeed by combining:
1. Passive progress
2. Rare surprise outcomes
3. Frequent timed check-ins
4. Visible cave growth
5. Social comparison
6. Constant reinvestment

The game does not need deep mechanics immediately. What matters first is that breaking geodes feels exciting, the cave visibly improves, and the player always feels one reveal away from something special.


