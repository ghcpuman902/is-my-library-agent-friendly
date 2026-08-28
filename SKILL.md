---
name: is-my-library-agent-friendly
description: >-
  Audits whether a library, SDK, CLI tool, UI component, or MCP server is
  designed for coding agents to discover, install, use, verify, and fix
  without a human in the loop. Starts from inside the target's own repo,
  does a cheap recon pass before requesting any isolated environment,
  classifies surfaces (core / api / cli / ui / mcp), tests hands-on, and
  scores a rubric with cited file, command, or error evidence. Use when
  asked whether a library is agent-friendly, to evaluate agent readiness
  or coding-agent developer experience of a package, SDK, CLI, component
  library, or MCP server, or when the user asks "is my library
  agent-friendly".
disable-model-invocation: true
---

# Is my library agent-friendly

An agent-friendly library is one a coding agent can learn, use correctly, and
debug from its own filesystem and terminal, without a human explaining it and
without guessing. This skill scores a target against that bar and produces a
short evidence-backed report.

Score the rubric, don't just read about the target. A README that sounds
agent-friendly and a package that actually installs, builds, and fails
clearly when you feed it garbage are different things. The gap is the finding.

`RUBRIC.md` is the checklist. `examples.md` has six calibration cases from
one real library, each tied to a criterion and the argument behind the
choice. Read it once if you want to see what a pass looks like, then close
it. Do not reach for its package names, CLI verbs, or API nouns as
decoration for your own scorecard; use the target's own names for
everything you found yourself. That said, if the target's own repo happens
to cite that same library as a reference or case study (its own design
doc, its own comparison table), quote the target's file normally — you're
citing the target's evidence at that point, not borrowing the calibration
set.

## Where you're starting from

You are almost always already inside the target's own repo when this audit
runs, not approaching it as an outside consumer. That changes the first
move. Don't clone anything yet. Look around first, cheaply, and only ask
for an isolated environment once that look-around says it's worth the cost.

Being inside the source also means you have to watch for a specific trap:
this repo's own dev setup (workspace links, devDependencies, local build
scripts) is not what an external user or agent gets. Anything you want to
score as "does this work for a stranger" has to actually run somewhere a
stranger would run it, not in this checkout.

## Workflow

```
Task progress:
- [ ] Step 1: Cheap recon in place, no new environment yet
- [ ] Step 2: Classify surfaces and headless-testability
- [ ] Step 3: Decide if and how far to escalate isolation
- [ ] Step 4: Run the hands-on checks
- [ ] Step 5: Score the rubric per applicable surface, with evidence
- [ ] Step 6: Write the report
```

### Step 1: Cheap recon in place

Before asking for anything (a folder, a container, a sandbox), spend two
minutes finding out if there's anything here worth that cost. Stay in the
current checkout for this step. You're just reading.

- Is there a package manifest that makes this installable at all
  (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, a published
  registry entry)? If there's no manifest and no registry listing, there's
  nothing for an external agent to install, and most of the rubric is `n/a`
  by construction.
- Is there a CLI entry point (`bin` field, `console_scripts`, a compiled
  binary target)?
- Is there any plain-text, greppable documentation, or does everything live
  behind a website?
- Does the README have a quick start you could actually copy?

If none of that turns up anything, stop here. Score what little you found,
mark the rest `n/a` with "no externally consumable surface found", and skip
straight to the report. There's no point requesting a sandbox for a script
nobody outside this repo will ever run.

If something did turn up, continue. You now know enough to ask for the
right environment instead of the safest-sounding one.

### Step 2: Classify surfaces and headless-testability

Not every library has every surface. Tag which ones exist before scoring, so
you don't fail a CLI-only tool for lacking a UI component.

The names below are fake. `acme` is a stand-in. Swap it for whatever the
target actually calls itself.

| Surface | What it is | Signal to look for |
| --- | --- | --- |
| `core` | Internal domain logic, language/parser/schema layer shared by everything else | Usually not imported directly by end users. Ask whether it has its own tests and validation independent of the higher layers. In a split package, this often looks like `@acme/core` or `acme-parser`. |
| `api` | The library surface a program imports and calls | An entry point in `package.json` main/exports, a Python module, a public crate, an SDK client class. Often just `acme`. |
| `cli` | A command users run in a terminal or an agent shells out to | A `bin` field, a `console_scripts` entry point, a compiled binary. Prefer `acme` shipping inside the same install, not a second package. |
| `ui` | A visual or interactive output a human (or a screenshot-capable agent) must eventually judge | A component library, a canvas/DOM renderer, a terminal UI, anything whose correctness includes "does it look right". Some libraries have no shipped widget and still have a `ui` surface: the pixels or DOM they produce. |
| `mcp` | A Model Context Protocol server exposing the library's capabilities as tools an agent calls directly | A `server.ts`/`server.py` built on an MCP SDK, a `mcp` field in a config file, a bin subcommand that starts a stdio/HTTP MCP server. Distinct from `cli` (different transport and consumer) and `api` (not imported by user programs). Increasingly common enough to score on its own rather than splitting across the other four. |

A library can have any subset of these, including none. Map the target's
real packages and entry points onto the five rows. If a row has nothing,
mark those rubric items `n/a`.

Also record, as a fact rather than a score: **can this be exercised
headlessly?** Can its core value be produced and checked without a browser,
a display, or a human eyeball, for example a deterministic PNG, a JSON
payload, a file on disk? This is not a measure of agent-friendliness. A
library can be headless and still badly designed, or browser-only and still
excellent. It only tells you how much of this audit you can run versus
merely read. Report it up front: "fully headless-testable", "partially"
(say what needs a display), or "no" (say why, and what you had to take on
faith).

### Step 3: Decide if and how far to escalate isolation

Only some rubric rows need you to leave the current checkout: the ones that
ask "does this work for a stranger who just installed it." Reading source
and inspecting its own docs are always fine right where you are. Running
the project's own existing test suite is fine in place only if its
dependencies are already installed here (a `node_modules`, a `venv`, a
vendored `target/`) — that's the common case when you're auditing from
inside an active dev checkout. If this is a bare clone with nothing
installed, installing anything is itself a write, and it belongs in tier 1
below, not in this step: copy the checkout out, install there, run the
suite there. Don't treat "the project's own tests" as a free action just
because it sounds like reading.

Ask the host user before creating anything. Don't spin up a directory, a
container, or a sandbox silently: it needs permission, may cost time or
money, and needs cleanup.

Pick the cheapest tier that actually answers the check you need, and only
escalate past it when you have a concrete reason:

1. **A scratch directory outside this repo, same host.** Cheapest, fastest,
   default choice. Ask the user where to put it, or use a system temp
   directory. Good enough for "does the package install from the registry
   (or from a build you produced) and run the quick-start snippet." The
   risk: it still shares this host's global package-manager caches, global
   config files, environment variables, and network access with the repo
   you're auditing from, so a "fresh install" here isn't fully fresh, and
   something the target reads from global state can leak in and produce a
   false pass.
2. **A local container**, Docker, OrbStack, Podman, whatever the host
   already has running. Check first (`docker info` or equivalent) instead
   of assuming it's there. Gives you real filesystem and process isolation
   for roughly the cost of tier 1. Use this when tier 1's shared global
   state would specifically undermine the check, for example verifying a
   CLI's global install behavior, or verifying a library doesn't quietly
   read from the parent monorepo it happened to be built inside. It also
   matters when your own host doesn't look like a typical agent sandbox:
   a health-check or install test run on your host's own OS, GPU, or
   display can pass or fail for reasons that have nothing to do with the
   library, and say nothing about the plain headless Linux container most
   agents actually run in.
3. **An ephemeral sandbox VM your host can provision on demand** (for
   example Vercel Sandbox via `@vercel/sandbox`, or whatever equivalent
   your coding-agent host offers). Needs its own setup and credentials, so
   only reach for this when neither tier above is available, or when you
   specifically need a clean, disposable network boundary, for example
   testing a claim about what the CLI does or doesn't fetch or execute.

Don't reach for tier 2 or 3 by default. Most of this rubric is answerable
from tier 1, and escalating past what a check needs just spends the user's
time and trust for no extra evidence.

### Step 4: Run the hands-on checks

In whatever environment Step 3 landed you in:

1. Build from source instead of installing the published package when
   possible: `pnpm install && pnpm build`, `pip install -e .`,
   `cargo build`, `go build ./...`, whatever the project uses. This
   surfaces build-time agent-friendliness (clear engine/toolchain
   requirements, a working `CONTRIBUTING.md`, no undocumented native
   dependencies) that a plain package-manager install would hide. If
   you're testing the published artifact instead, install it the way a
   stranger would, from the registry, not via a workspace link.
2. Run the test suite, or at least the fast/unit subset, if you haven't
   already read its results from this repo's own CI. Note whether it needs
   a GPU, a browser, a display server, or a network call to pass, and
   whether a headless/mock path exists.
3. If it ships a CLI, run it with no arguments and read what it prints.
4. If it's a pure library, write the smallest program the README's quick
   start suggests and run it.
5. Feed it something it can't handle (malformed input, a missing
   dependency, a bad config) and read the failure.

If the target cannot be built or installed at all, stop and score that as
the finding. Everything else is secondary to "does it work when I try it."

### Step 5: Score the rubric

Open `RUBRIC.md`. For every row tagged with a surface the target has:

- Score `pass`, `warn`, `fail`, `n/a`, or `blocked`.
- Cite the evidence: a file path and line, an export name, the exact command
  you ran, or the exact error text you got back. "It looks fine" is not
  evidence; a copy-pasted terminal line is.
- Prefer running the check over reading about it.

`n/a` and `blocked` answer different questions and get mixed up if you
don't watch for it. `n/a` means the surface itself doesn't exist here (a
CLI-only tool has no `ui` rows to score). `blocked` means the surface
exists, but you couldn't verify it hands-on this run because the isolated
environment the check needed wasn't available or wasn't granted, so you're
reasoning from source instead of an execution. Never guess a `pass` or
`fail` from source when the row's own "how to test" column calls for
running something — mark it `blocked` and say exactly what you would run
and what result would resolve it in either direction. That command-plus-
pass-condition pair is itself a deliverable: whoever picks this up next
(you with permission, or someone else) can execute your list without
re-deriving it.

### Step 6: Write the report

One line verdict first. Then a table: criterion, surface, score, evidence.
End with the three fixes that would move the score most. A maintainer
reading this should know what to change first, and why, in the time it
takes to read three bullets.

Use only the target's own names in the report. If a calibration example
comes to mind, translate the *method* (one handle, fail early, JSON by
default) into the target's nouns, and don't name the calibration library as
your source for it — unless the target's own repo already names and cites
it as their own reference, in which case cite the target's file as
evidence like you would any other.

```markdown
## Verdict
<one sentence: is this library ready for a coding agent to use unsupervised>

## Scorecard
| Criterion | Surface | Score | Evidence |
| --- | --- | --- | --- |
| ... | ... | pass/warn/fail/n-a/blocked | file:line, command, or error text |

## Headless-testability
<fully / partially / no, one line on what that means for confidence in this report>

## Isolation used
<none / scratch directory / container / sandbox VM, and why that tier was enough>

## Blocked checks
<omit this section if nothing is scored `blocked`>
<one line per blocked row: the command you'd run, the pass condition, which
row(s) it settles>

## Top 3 fixes
1. ...
2. ...
3. ...
```

## Why these criteria

Each row in `RUBRIC.md` exists because a specific failure showed up when an
agent tried a library that lacked it. Two names for the same job, and the
agent invents a third. No static check, and it burns a turn booting an app
to find out the input was illegal. A stack trace with no fix. A 40 KB
import for a feature the program never called. `examples.md` traces six of
those failures back to a real decision, the alternative that was rejected,
and the argument for why. Use that to recognize the same reasoning, or its
absence, in whatever you are scoring.
