# Spec Extraction Prompt — Raw Datasheets → Validated Model Spec

> **This prompt is a harness artifact, not a one-off.**
> It plays the same role as a parameterized script: we version it, and we **modify it
> based on what actually matters to us in reality** — which parameters the team needs,
> which model family is the target, which acceptance criteria the test bench checks.
> Encoding team-specific needs into this prompt is exactly the kind of "skill"
> the harness accumulates over time.

---

## Role

You are extracting engineering data from raw supplier documents (datasheets, test
reports, module specs) to produce a **single structured input spec** (`spec.md`) for
generating a Simulink model. The spec — not the raw PDFs — is the only input the
model-generation step is allowed to see, **after a human engineer validates it**.

## Inputs

All PDF files in `../1_raw_data/`. Output goes to `../3_spec/spec.md`.

## Target model (parameterize per project)

- Model family: **second-order Thevenin ECM** (R0 + 2×RC + OCV(SOC) lookup), cell level,
  scaled to a pack.
- Pack topology: **13s4p** (48 V class, VDA320-compatible nominal voltage).
- Protection subset to specify: undervoltage cutoff, overcurrent limit, temperature
  window. Balancing, contactor logic, charger behavior: **out of scope — say so explicitly.**

## Hard rules

1. **Provenance for every number.** Each value carries its source: document + page/table.
   Values not present in any input document are marked `ASSUMED` or `LITERATURE`,
   with justification — **never silently invented.** Hallucinated parameters are the
   single biggest credibility risk; this rule is the guardrail.
2. **No derivation without showing work.** Derived values (pack-level scaling, gain
   constants, time constants) include the formula and the inputs used.
3. **Units everywhere.** SI units; state them explicitly in every table.
4. **Gaps are findings, not failures.** If the documents don't contain a needed
   parameter (e.g., RC branch values, OCV curve), list it under *Open items* with a
   proposed source — don't fill it in quietly.
5. **Acceptance criteria are mandatory.** Derive numeric pass/fail ranges from the
   spec values (initial voltage range, cutoff voltage and expected time window, SOC
   monotonicity, current/temperature limits). These become the test assertions —
   the model is later judged against the spec, not against itself.
6. **Separate identification data from validation data.** Data used to parameterize the
   model (datasheet values, low-rate discharge curve for OCV) must be disjoint from the
   data later used to judge it (high-rate curves, temperature curves). Held-back data is
   listed in its own spec section — the model must never be validated against the data
   that built it.
7. **English output**, engineering register, tables over prose.

## Output structure (`spec.md`)

1. **Sources** — provenance table: every document, version, what was taken from it
2. **Cell parameters** — electrical + thermal limits from the datasheet
3. **ECM parameters** — R0, R1/C1, R2/C2, OCV(SOC) table, each with provenance
4. **Pack topology & derived parameters** — series/parallel counts, scaling formulas, results
5. **Protection subset** — what is modeled, what is explicitly out of scope
6. **Simulation scenario** — load profile, initial conditions, stop conditions
7. **Acceptance criteria** — numeric ranges, each traceable to a spec value
8. **Open items** — gaps, assumptions awaiting engineer validation

## Validation checkpoint

The output spec ends with a sign-off block:

```
VALIDATED BY: ____________  DATE: ________
Model generation MUST NOT proceed before sign-off.
```
