# Agent Guidelines

Use these rules when working on Gem Factory with Codex or another coding agent.

## Engineering Values

- Write clean, supportable code.
- Think through long-term maintenance before adding new systems.
- Prefer deterministic logic that can be tested.
- Keep reward, placement, economy, and offline math easy to inspect.
- Avoid hiding important behavior in client-only presentation code.

Before and after implementation, ask:

1. Will this be supportable long term?
2. Is this hard to test?
3. Is this the simplest clean approach that fits the current architecture?
4. Does this keep the server authoritative where it matters?
5. Does this update the docs that future work will rely on?

## Workflow

- Read [docs/current_state.md](docs/current_state.md) before making gameplay changes.
- Read [docs/gem_factory_design.md](docs/gem_factory_design.md) when changing product behavior or terminology.
- Update [docs/current_state.md](docs/current_state.md) after meaningful implementation changes.
- Update [README.md](README.md) or [docs/README.md](docs/README.md) only when project navigation, setup, or high-level context changes.
- Keep comments current when touching code so future agents can follow ownership, data flow, and tricky state transitions without re-deriving intent from scratch.
- Clean up dead code introduced by the change.
- Add focused tests when touching deterministic gameplay logic.

## Commenting Expectations

- Comment code for future agents, not just for the current task.
- Add a short file-level comment to non-trivial modules describing what the module owns and where it fits in the client, server, or shared architecture.
- Add brief inline comments around logic that is easy to misread later: profile mutation boundaries, replicated-world projection, placement math, lifecycle state transitions, and reward or offline calculations.
- Do not add noisy comments that only restate syntax or obvious assignments.
- When you touch an older module that lacks context, improve the surrounding comments as part of the change.

## Feature Implementation Process

Use this process for every meaningful feature, especially anything that changes gameplay, profile data, remotes, economy, placement, offline progress, or UI flow.

### 1. Plan The Feature

Start by writing or explaining a short implementation plan before changing code.

The plan should cover:

- What player-facing behavior the feature adds or changes.
- Which modules, services, controllers, configs, remotes, types, and tests the feature will touch.
- Which logic belongs in `src/shared`, `src/server`, and `src/client`.
- How to keep the feature modular so it can be tested and changed later.
- What data shape or profile migration concerns exist.
- What edge cases could break the feature.
- What documentation needs to change after implementation.

Prefer small modules and pure shared domain functions when the behavior can be expressed deterministically. Keep server-owned decisions on the server, and keep client code focused on input, presentation, and requests.

### 2. Write Tests First

Before implementing the feature, add a decent test set for the planned behavior. Aim for at least 5 meaningful tests for each feature.

The tests should cover:

- The normal successful path.
- At least one invalid or rejected path.
- Boundary cases such as full capacity, empty inventory, expired timers, or exact grid edges.
- State transitions before and after the feature action.
- Regression-prone interactions with existing systems.

When a feature cannot be fully covered by automated specs yet, still add deterministic tests for the pure logic and document any required Studio validation steps in `docs/current_state.md` or the implementation notes.

### 3. Implement The Feature

Implement only after the plan and initial tests are in place.

During implementation:

- Keep changes scoped to the planned files unless the code reveals a real dependency.
- Match the repo's existing service/controller/domain patterns.
- Make server validation authoritative.
- Keep client presentation resilient to missing or delayed state.
- Reuse existing config, type, utility, and remote-name patterns.
- Avoid mixing unrelated cleanup with feature work.
- Run the relevant build, tests, or manual verification path.
- Update [docs/current_state.md](docs/current_state.md) and any design docs affected by the new behavior.

## Testing Guidance

- Only write tests that verify useful behavior.
- Prefer reproducible tests over manual timing or luck.
- Seed randomness when testing reward rolls.
- Build small debug or playground harnesses for tricky simulations when useful.
- Do not rely only on the interactive Roblox Studio window to judge correctness.

## Collaboration Notes

- Break large implementations into smaller steps.
- Use subagents when the work naturally splits into independent pieces.
- Keep the problem feedback-loopable: make behavior observable, repeatable, and easy to validate.
- Preserve project docs as living context, not as afterthoughts.
