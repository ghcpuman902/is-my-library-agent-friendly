# Is my library agent-friendly?

A pack that scores whether a library, SDK, CLI, UI component, or MCP server is designed so a coding agent can use it without a human in the loop.

The bar comes from [vgpu](https://github.com/vercel-labs/vgpu), the Vercel Labs WebGPU library. That project was designed so an agent could install it, call it, and recover from bad input without a human walking it through the API. I turned those decisions into a scorecard and have been running it on [tfl-ts](https://github.com/ghcpuman902/tfl-ts) and [tfl-components](https://github.com/ghcpuman902/tfl-components).

## Install

```bash
npx skills add ghcpuman902/is-my-library-agent-friendly --skill imlaf-audit
```

Listed on [skills.sh](https://skills.sh/ghcpuman902/is-my-library-agent-friendly). The installed folder is `imlaf-audit`, not a generic `audit`.

## Skills

**imlaf-audit.** Score the target. Start from inside the library under audit, load this skill, follow `skills/imlaf-audit/SKILL.md`. Do not clone the target as a first step. Look around first.

**imlaf-improve.** Coming soon. It will take a fail or a scorecard and make the smallest change that would move that row. Not in this pack yet.

## What imlaf-audit gives you

A scorecard with pass, warn, fail, n/a, or blocked, plus the three fixes that would move the score most.

## Files in imlaf-audit

- `SKILL.md` workflow
- `RUBRIC.md` criteria
- `examples.md` calibration. Read it once. Do not copy its names into reports.
- `scripts/detect-surfaces.sh` heuristic only
