# Skill: Spec Extraction — Raw Datasheets → Validated Model Spec

> **Harness skill (generic — shared by all examples).**

---

## Role

You are extracting engineering data from raw supplier documents (datasheets, test
reports, module specs) to produce a **single structured input spec** for generating a
Simulink model. The spec — not the raw PDFs — is the only input the model-generation
step is allowed to see, **after a human engineer validates it**.

## Inputs

- All PDF files in the example's `1_raw_data/` folder
- The example's `2_config/pipeline_config.md` — target model family, topology,
  protection scope, output file names

## Output

- `3_spec/spec.md` in the example folder

## Hard rules

1. **Provenance for every number.** Each value carries its source: document + page/table.
   Values not present in any input document are marked `ASSUMED` or `LITERATURE`,
   with justification — **never silently invented.** Hallucinated parameters are the
   single biggest credibility risk; this rule is the guardrail.
2. **No derivation without showing work.** Derived values (scaling, gain constants,
   time constants) include the formula and the inputs used.
3. **Units everywhere.** SI units; state them explicitly in every table.
4. **Gaps are findings, not failures.** If the documents don't contain a needed
   parameter, list it under *Open items* with a proposed source — don't fill it in
   quietly.
5. **Acceptance criteria are mandatory.** Derive numeric pass/fail ranges from spec
   values. These become the test assertions — the model is later judged against the
   spec, not against itself.
6. **Separate identification data from validation data.** Data used to parameterize the
   model must be disjoint from the data later used to judge it. Held-back data is
   listed in its own spec section — the model must never be validated against the data
   that built it.
7. **English output**, engineering register, tables over prose.

## Output structure (`spec.md`)

1. **Sources** — provenance table: every document, version, what was taken from it
2. **Product parameters** — electrical/physical/thermal limits from the primary datasheet
3. **Model parameters** — per the config's model family, each with provenance
4. **Topology & derived parameters** — per config; scaling formulas and results shown
5. **Protection subset** — what is modeled, what is explicitly out of scope (per config)
6. **Simulation scenario** — load profile, initial conditions, stop conditions
7. **Acceptance criteria** — numeric ranges, each traceable to a spec value
8. **Validation data — held back** — reserved for independent post-model comparison
9. **Open items** — gaps, assumptions awaiting engineer validation

## Validation checkpoint

The output spec ends with a sign-off block:

```
VALIDATED BY: ____________  DATE: ________
Model generation MUST NOT proceed before sign-off.
```
