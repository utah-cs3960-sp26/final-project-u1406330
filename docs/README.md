# Documentation Guide

This folder is split into current project docs and archived planning material.

## Current Docs

- [current_state.md](current_state.md) is the live implementation snapshot. Start here when you need to know what currently works, what is partial, and what should be built next.
- [gem_factory_design.md](gem_factory_design.md) is the current product and systems direction for Gem Factory. It describes the intended fantasy, loop, and design principles.
- [../agents.md](../agents.md) documents how agent-assisted work should be done in this repo: clean implementation, useful tests, documentation updates after changes, and comment expectations that keep the code legible for later agents.

## Archived Docs

- [archive/implementation_plan.md](archive/implementation_plan.md) is the earlier phase-based implementation plan. It is retained for context, but parts of it are now historical because the project has already moved into a playable MVP slice.
- [archive/project_proposal_week13.md](archive/project_proposal_week13.md) preserves the original proposal and Week 13 status narrative that used to live in the root README.

Archived docs are not the source of truth for current behavior. When archived notes disagree with `current_state.md`, the current-state doc wins.

## Documentation And Code Context

- The current source tree is expected to carry concise module-purpose comments so agents can identify ownership and data flow quickly before editing.
- Treat docs and code comments as the same maintenance surface: if a system changes, update both the implementation summary and the nearby code context that explains it.

## Suggested Reading Order

1. Read this file for the map.
2. Read [current_state.md](current_state.md) for the implementation snapshot.
3. Read [gem_factory_design.md](gem_factory_design.md) for design intent.
4. Read [../agents.md](../agents.md) before making or reviewing implementation changes.
5. Read [archive](archive) only when you need project history.
