# Skill: Architecture Doc — Built Model → Block-by-Block Reference

> **Harness skill (generic — shared by all examples).** Pipeline position:
> `spec.md → [model_generation] → .slx → [THIS SKILL] → 5_docs/<model>_architecture.md`
> Versioned and **modified to encode team standards** (documentation template, register,
> review checklist). Today it carries the generic harness template v1; in a team pilot,
> it would produce the team's own report format. Product-specific file names come from
> the example's `2_config/pipeline_config.md`.
>
> **Format reference:** `examples/molicel_48v_pack/5_docs/molicel_48v_pack_architecture.md`
> is a completed output of this skill — match its structure, depth, and tone.

---

## Role

Generate the architecture & block reference document for a model produced by Stage 2.
The reader is an engineer who must be able to **defend every block in the model without
opening MATLAB** — what it is, what parameter it carries, where that number comes from,
and why the block exists in the system.

## Inputs — document what IS, not what was intended

- The example's `4_model/<model>.slx` — **the actual built model is the primary
  source.** Read its structure with `model_read`, parameters with `model_query_params`
  / the `_params.m` script. Never describe the model from the config sketch or from
  memory of Stage 2; if Stage 2 deviated, the doc reflects what was built.
- The example's `3_spec/spec.md` (signed) — provenance tags (`DS`/`TRM`/`ASSUMED`/
  `DERIVED`), acceptance criteria, open items. Numbers in the doc inherit the spec's
  provenance, never re-derive or re-source them.
- Actual simulation results of the spec's §6 scenario — re-run the simulation if
  results are not at hand; **every number presented as a result must be measured,
  not predicted.**
- The example's `2_config/pipeline_config.md` — output file name.
- Stage 2's handover report (deviations, recovered errors), if available in chat.

## Output

- `5_docs/<model>_architecture.md` in the example folder, named per config.

## Required structure (the 9 sections)

1. **Header** — status banner (`DRAFT — generated documentation, pending engineer
   validation`), pointer to the signed spec as source of truth, provenance-tag legend.
2. **Model purpose** — what it simulates, the questions it answers at every time step.
3. **Physical basis** — table: mechanism → physical cause → time scale → which block
   models it. Plus the scaling/topology assumptions with their stated limitations.
4. **System architecture** — ASCII signal-path diagram of the real model; the governing
   equation with **numeric contributions from the actual simulation**; dynamics of each
   storage element (state, time constant, settle behavior).
5. **Block-by-block reference** — an entry for **EVERY block**, grouped by signal
   region: block name, library type, exact parameter (named variable = numeric value,
   spec section + provenance tag), role in the system, and any non-obvious subtlety
   (why a separate gain instead of folding into a table; guard values that are NOT
   spec values; outport ordering pitfalls; what to swap to change the scenario).
6. **Signal summary table** — every named signal: source block, destination(s), units,
   actual range/value in the simulated scenario.
7. **Simulation results** — metric table mapped one-to-one to the spec's acceptance
   criteria, measured value next to required range, PASS/FAIL marks.
8. **Known limitations & pending validation** — inherited from the spec's open items,
   plus anything Stage 2 added; the held-back validation step is named explicitly as
   the engineer's pending action. Explicit, not buried.
9. **Footer** — `*Documentation format: generic harness template v1. A team-specific
   documentation template would be encoded as a skill and produce this report in the
   team's own format.*`

## Hard rules

1. **Built model wins over every other source.** Structure and parameters come from the
   `.slx`/`_params.m` as they exist on disk. Where the model deviates from the config
   sketch, document the model and note the deviation.
2. **Measured, not asserted.** Any number presented as a simulation result comes from an
   actual run of the spec scenario. No extrapolated or remembered values.
3. **Provenance travels.** Every parameter cited keeps its spec tag; implementation
   guards (epsilons, integrator saturation margins) are explicitly labeled as NOT spec
   values.
4. **No block left out.** Sources, scopes, outports, and guard logic get entries too —
   completeness is the point of the document.
5. **Status is self-declared.** The doc opens with its DRAFT banner; it never presents
   the model as validated while the held-back comparison is pending.
6. **English output**, engineering register, tables over prose.

**Done when:** the doc exists at the config's path and a reader could defend every
block in the model without opening MATLAB.
