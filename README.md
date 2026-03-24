# final-project-u1406330

A Roblox game experiment inspired by the design philosophy behind the viral Roblox game "Grow A Garden".

The goal of this project is to explore how extremely simple gameplay can still retain players for long periods of time when it is built around strong psychological engagement loops.

Rather than focusing on deep mechanics or complex gameplay, the design intentionally focuses on progression systems and reward structures that encourage players to repeatedly return to the game.

This project is essentially a design experiment that asks the question:

Can a game with very simple mechanics still be highly engaging if the reward systems are designed correctly?

The concept for this project came from a video analyzing the design principles behind "Grow A Garden".  
Video: https://www.youtube.com/watch?v=5WQHP7BnQ9M


## Game Concept

The working concept for this project is **Grow A Zoo**.

Instead of planting crops like in Grow A Garden, players hatch animals that live in their personal zoo.

Animals generate coins automatically over time. Players reinvest these coins into more eggs, better habitats, and upgrades that increase the rate at which their zoo produces value.

Animals can also mutate into rare variants which significantly increase their value and create a collectible aspect to the game.

The player starts with a small empty zoo and gradually builds a large animal collection that generates large amounts of passive income.

The core gameplay loop is intentionally very simple.

1. Obtain eggs
2. Hatch animals
3. Place animals into habitats
4. Collect passive income
5. Buy better eggs and upgrades
6. Repeat


## Core Design Principles

This game intentionally uses several psychological design tactics that are commonly used in highly engaging progression based games.

These systems are not new and appear in many successful idle or simulator games.

The goal of this project is to explore how these mechanics work together to drive player retention.


### Idle Progression

Animals continue to generate coins even when the player is offline.

When the player returns to the game they receive a large chunk of offline earnings.

This creates a positive feedback loop where logging in always feels rewarding.

Example

A player logs out with a zoo generating 120 coins per second.  
They return later and receive thousands of coins that accumulated while they were gone.


### Variable Rewards

Egg hatching uses randomized outcomes.

Each egg has a rarity table that determines which animal the player receives.

Animals can also mutate into rare variants such as

Golden  
Albino  
Giant  
Neon  
Rainbow  

Because outcomes are unpredictable, even common eggs still feel exciting to open.


### Timers and Rotating Shops

Many systems operate on timers.

Examples include

Egg hatch timers  
Habitat upgrade timers  
Hourly shop rotations  
Daily rewards  
Limited events  

Players often stay slightly longer than planned because a timer is about to finish.


### Big Number Progression

Income scales rapidly as the zoo grows.

Early animals generate small amounts of coins. Later animals and upgrades multiply production dramatically.

Watching numbers grow quickly creates a satisfying sense of progress.


### Scarcity and Limited Events

Certain eggs or animals only appear during specific time windows.

Examples

Hourly rotating egg shop  
Weekly event animals  
Limited mutation boosts  

This encourages players to check the game frequently so they do not miss opportunities.


### Social Comparison

Players can see other zoos in the server.

Seeing larger zoos or rare animals motivates players to continue progressing.


### Simple Gameplay Loop

The actual gameplay mechanics are intentionally minimal.

The main actions are

buy eggs  
place animals  
collect coins  
upgrade habitats  

The complexity is not in the mechanics but in the progression systems.


## Why This Works

Games built around these systems do not require complex gameplay to retain players.

Instead they rely on a layered reward structure.

Players are always

close to a new upgrade  
close to a hatch finishing  
close to a new shop rotation  
close to unlocking a rare animal  

Even when the player intends to leave, there is usually a short term reward that keeps them engaged a little longer.

This pattern is extremely common in simulator style games on Roblox.


## Technical Goals

This project also serves as a learning exercise for building larger Roblox systems.

Systems I plan to implement include

Animal data storage  
Passive income systems  
Offline earnings calculations  
Randomized rarity tables  
Mutation systems  
Timed shop rotations  
Save data management  
Basic UI systems for progression


## Project Goal

The main goal is not to build a perfectly polished game.

Instead the goal is to experiment with the design principles that allow extremely simple games to achieve high player retention.

If the game succeeds at keeping players engaged despite simple gameplay mechanics, then the design experiment worked.


## Disclaimer

This project is meant as a study of game design patterns and player retention mechanics.

The intention is to understand how these systems work rather than to create a manipulative experience.

If you want, I can also help you add a few really strong README sections that make the repo look much more impressive for a class project, like:

• Game architecture section (Roblox server vs client design)
• Data model for animals and habitats
• Mutation probability tables
• Offline earnings formula
• Planned milestones / roadmap

Those would make the repo look much more like a real production design document, which professors tend to like.

This project is for a vibe coding class, work in how apart from the original idea, everything is AI Generated, the game design, etc. Also add more detail in the first part about "Grow A Garden" specifically how it makes people addicted (like i had originally)

Here is a revised and expanded README that:

• explains Grow A Garden’s addictive design more clearly
• emphasizes that the project is AI generated / vibe coded
• keeps your tone but makes it more structured and readable
• still reads like a real GitHub README for a class project

I also avoided using dashes since you prefer that.

# final-project-u1406330

A vibe coded Roblox game inspired by the design philosophy behind the viral Roblox game **Grow A Garden**.

This project is part of a **vibe coding class**, where the goal is to build software primarily through collaboration with AI tools rather than traditional step by step manual development.

Aside from the initial idea of the game itself, nearly everything involved in this project is generated with the help of AI. This includes:

Game design decisions  
System design and progression mechanics  
Implementation ideas and architecture  
Documentation and planning  

The project is therefore both a **game design experiment** and an **experiment in AI assisted development**.


## Inspiration

The idea for this project came from a video analyzing the design principles behind the Roblox game **Grow A Garden**.

Video:  
https://www.youtube.com/watch?v=5WQHP7BnQ9M

Grow A Garden is an extremely simple simulator style Roblox game where players plant crops, wait for them to grow, harvest them, and then reinvest the profits into better seeds.

Mechanically the game is extremely repetitive.

Players

Plant seeds  
Wait for growth timers  
Harvest crops  
Sell crops  
Buy better seeds  
Repeat

Despite this simplicity the game has been massively successful and retains players for long periods of time.

The reason is not the gameplay itself.

Instead the game is built around several psychological design patterns that encourage players to keep playing even when the actions themselves are simple.

Grow A Garden constantly creates the feeling that something valuable is **about to happen**.

A crop is about to grow  
A shop is about to restock  
A rare plant might appear  
A new upgrade is almost affordable  

Because of this players frequently stay longer than they intended.

Many players, including myself, notice that they often think:

“I'll just wait until this finishes.”

Then another timer starts and the cycle repeats.


## Project Concept

The concept for this project is **Grow A Zoo**.

Instead of planting crops, players hatch animals that populate their own personal zoo.

Animals generate coins automatically over time and players reinvest those coins into:

More eggs  
Better habitats  
Zoo upgrades  
Rare mutation chances  

Animals can also hatch with rare mutations which significantly increase their value.

Example mutations might include:

Golden animals  
Albino animals  
Giant animals  
Neon animals  
Rainbow animals  

The player begins with a small empty zoo and gradually builds a large collection of animals that produce increasing amounts of passive income.


## Core Gameplay Loop

The gameplay loop is intentionally extremely simple.

Obtain eggs  
Wait for eggs to hatch  
Place animals into habitats  
Collect passive coins  
Buy more eggs and upgrades  

Repeat.

The complexity of the game does not come from the actions themselves but from the **progression systems layered on top of them**.


## Psychological Design Principles

The design of this project intentionally mirrors the engagement strategies used in Grow A Garden.

These mechanics are common in many simulator and idle games and are known to drive strong player retention.


### Idle Progression

Animals continue generating coins while the player is offline.

When the player returns they receive a large burst of accumulated coins.

Logging in therefore always feels rewarding even if the player has not actively played.


### Variable Rewards

Eggs hatch into animals based on probability tables.

Most animals are common but occasionally a rare or mutated animal appears.

Because outcomes are unpredictable even simple actions like opening an egg can feel exciting.


### Timers and Restocks

Many game systems operate on timers.

Examples include

Egg hatch timers  
Habitat upgrades  
Hourly egg shop rotations  
Daily rewards  

Players frequently stay slightly longer because a timer is about to finish.


### Big Number Progression

As the zoo grows, income increases rapidly.

Watching numbers grow quickly creates a satisfying sense of progression.

Players are constantly reinvesting their earnings into systems that increase production even faster.


### Scarcity and Limited Events

Certain eggs and animals only appear during limited time windows.

Examples might include

Hourly rotating eggs  
Weekly event animals  
Seasonal mutation boosts  

This creates a fear of missing out and encourages players to check the game frequently.


### Social Comparison

Players can see other zoos within the server.

Seeing larger zoos or rare animals motivates players to continue upgrading their own zoo.


### Simple Gameplay Loop

The core actions remain extremely simple throughout the entire game.

Buy eggs  
Place animals  
Collect coins  
Upgrade habitats

The complexity of the experience comes from layered reward systems rather than mechanical difficulty.


## Why These Systems Work

Games like Grow A Garden succeed because they constantly provide **near future rewards**.

Players are always close to something happening.

A hatch finishing  
A shop restocking  
A rare drop appearing  
An upgrade becoming affordable  

Because of this players frequently extend their play sessions without realizing it.

The gameplay itself can be extremely simple and still remain engaging because the reward systems are designed to keep the player curious about what happens next.


## Vibe Coding Approach

This project is intentionally built using a **vibe coding workflow**.

Rather than manually designing every system from scratch, AI tools are used to generate:

Game design ideas  
Progression systems  
Economy balancing concepts  
Technical architecture suggestions  
Documentation  

The developer acts more as a **director or editor**, guiding the AI toward a desired outcome and refining the results.

This approach allows complex ideas and systems to be explored much faster than traditional development methods.


## Technical Goals

This project also serves as an experiment in building core systems commonly used in Roblox simulator style games.

Planned systems include

Animal data storage  
Passive income generation  
Offline earnings calculations  
Randomized rarity tables  
Mutation systems  
Timed shop rotations  
Save data management  
Progression based UI systems  


## Project Goal

The goal of this project is not to build a perfectly polished Roblox game.

Instead the goal is to explore two questions.

First

How do games like Grow A Garden keep players engaged even when the gameplay is extremely simple?

Second

How effectively can a game be designed and structured using AI assisted development?

If the game successfully demonstrates strong progression loops and player retention despite minimal gameplay complexity, then the experiment is successful.


## Disclaimer

This project is intended as a study of game design patterns and AI assisted development.

The purpose is to understand how engagement systems work rather than to create manipulative player experiences.
