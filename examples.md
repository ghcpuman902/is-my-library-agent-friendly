# Six calibration examples

These six are from [vgpu](https://github.com/vercel-labs/vgpu). Read them
once to see how a team argued a choice, including the alternative they
rejected and the cost they accepted. Then close this file.

Do not copy its package names, CLI verbs (`doctor`, `check`, `docs`), or
API nouns (`init`, `effect`, `gpu`) into a scorecard for a different
library. Steal the *method*. Leave the brand behind.

## 1. Write the decision, the reason, and the tradeoff

[Issue #7](https://github.com/vercel-labs/vgpu/issues/7) is a long-lived
decision log. Each entry uses the same three headings: Decision, Reasoning,
Tradeoffs.

> **D1. Node WebGPU binding**
> Decision: use the `webgpu` Dawn bindings as the sole Node backend in
> phase 1. Do not ship parallel Node backends.
> Reasoning: one backend keeps the mental model and support matrix small.
> Multiple native backends would multiply CI, packaging, docs, and debugging
> complexity before the core API is stable.
> Tradeoffs: if `webgpu` has gaps or release friction, phase 1 absorbs that
> risk instead of routing around it.

That's criterion 15. The useful part is the third heading. They named the
risk they were eating, so a later reader can tell the omission of extra
backends was deliberate.

When you audit a target, look for this shape. A changelog that only lists
what changed is not a decision trail.

## 2. Keep the rejected path on the page

Same issue, D9, plus a "Superseded principles" section at the bottom.

> Decision: use an explicit top-level aggregate for runtime concerns. No
> ambient context, no hidden singleton, no `AsyncLocalStorage` dependency.
> Reasoning: explicit dependencies are easier for agents to read, generate,
> and debug. Ambient context introduces invisible coupling and worker
> complexity.

They also wrote down what they walked back after trying it: ambient
context, a custom docs CLI as the primary interface, and a
library-managed worker runtime. Plain colocated Markdown won on docs,
criterion 4. Users own their workers. Criterion 9 and criterion 11. A
later reader can tell the missing singleton was not forgotten.

If the target has no record of a rejected alternative, you cannot tell
design from accident.

## 3. Compose with the host language, or say why you will not

They rejected WESL, a community shader-module proposal, and wrote an
owned JS-style `import` / `export` resolver instead.

> JS-style imports are the most familiar shader-composition model for both
> humans and AI agents. Owning the resolver and diagnostics lets vgpu
> control error wording, spans, and fix suggestions end to end. Avoiding
> WESL removes upstream bus-factor risk while preserving the same
> architectural escape hatch through the vgpu-owned IR boundary.

Criterion 13. The method: prefer syntax the host tooling already knows.
If you invent a dialect, write down why. Owning diagnostics is a real
reason. "We felt like it" is not.

## 4. Measure the cost of a wide API, then cut it

[PR #211](https://github.com/vercel-labs/vgpu/pull/211) deleted a
monolithic `obj.feature()` facade and replaced it with free functions that
take the handle as the first argument. The changelog names the failure:

> the facade forced every entrypoint to import every feature, so a program
> that only drew a triangle still paid for compute, timers, occlusion
> queries, ping-pong and the scene primitives.

The measured result: one common-case bundle dropped 42%, from 43,234 bytes
gzipped to 25,109, against a CI ceiling. Criterion 10.

The same PR description has two sections worth stealing for any library,
not just this one:

- **Deviations from plan.** Where the implementation drifted from the
  issue that specified it, and why.
- **Adversarial QA findings.** Bugs the author found by attacking their
  own change, rated HIGH/MED/LOW, marked fixed before push.

## 5. A one-page ADR for a single behavioral commitment

[`docs/adr/0001-doctor-verdict-is-a-real-render.md`](https://github.com/vercel-labs/vgpu/blob/main/docs/adr/0001-doctor-verdict-is-a-real-render.md)
exists because two external agents misdiagnosed "no adapter" as a hard
sandbox limit. The real cause was a feature-level requirement a static
check could not see.

> [The health-check] verdict is produced by actually rendering (init to
> draw to readback to dispose), not by static checks. Static probes exist
> to explain failures, not to declare health.

Criterion 23. The format is the steal. Context says what went wrong.
Decision is one sentence. Consequences names the cost, here 1 to 3
seconds per run.

## 6. Say what a green eval does not prove

The dogfooding harness (`apps/agent-evals/README.md`) hands a coding agent
the freshly built package and watches. Its own docs are blunt about the
gates:

> [One task's] gates read a file the agent left behind... an agent that
> writes the gradient pixel by pixel in plain JavaScript, never touching
> vgpu, passes the gates.

And for the harder task:

> Two independent mechanisms defeated all four gates with zero graphics
> code in the workspace, found during review... An agent with root for
> its whole turn can also kill and replace a process, `LD_PRELOAD` a
> shared library, or firewall traffic... forcing every gate green without
> the app actually working.

Criterion 12. They fixed the accidental case, a leftover process on a
fixed port, with a random port and a per-run nonce. They say they have
not closed the adversarial case. A project that claims its evals prove
correctness without that caveat is one to read more skeptically.
