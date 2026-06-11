# Skill: Model Generation — Validated Spec → Simulink Model

> **Harness skill (generic — shared by all examples).** Pipeline position:
> `raw PDFs → [spec_extraction] → spec.md → [ENGINEER SIGN-OFF] → [THIS SKILL] → .slx`
> Versioned and **modified to encode team standards** (naming conventions, approved
> block sets, structure rules). Today it carries generic conventions; in a team pilot,
> it would carry the team's. Product-specific architecture and file names come from the
> example's `2_config/pipeline_config.md`.

---

## Role

Generate a Simulink model implementing **exactly** what the example's validated spec
defines. You are the draft-producing step; the engineer validates the result. Nothing
you produce is trusted until it passes the spec's acceptance criteria and human review.

## Input — single source of truth

- The example's `3_spec/spec.md`, **only if it carries engineer sign-off**. If the
  sign-off block is empty, STOP and report — do not generate.
- The example's `2_config/pipeline_config.md` — output file names and the fixed
  architecture sketch for this model family.
- **You MUST NOT read the raw PDFs.** If a needed value is missing from the spec, that
  is a spec defect: stop and report it; never fill the gap from memory or other sources.

## Output

- The `.slx` model and its `_params.m` parameter script in the example's `4_model/`
  folder, named per config.

## Architecture

Fixed per model family in `2_config/pipeline_config.md` — **do not improvise.**
Where the spec and the config sketch disagree, **the spec wins, and you report the
deviation** in the handover report.

## Hard rules

1. **Every numeric block parameter must be traceable to a spec table cell.** Define all
   values as named variables in the `_params.m` script, commented with their spec
   section; put the spec reference in each block's Description field. No magic numbers.
2. **Basic library blocks only** (Gain, Integrator, Lookup Table, Transfer Fcn, Sum,
   Compare, Constant, Scope, Outport) unless the config says otherwise — the audience
   must be able to read every block. (Team-standard block sets would be encoded here.)
3. **Naming convention** (placeholder for team standards): `PascalCase_With_Underscores`,
   role-revealing names (`SOC_Integrator`, not `Integrator1`).
4. **States need guards**: integrators get initial conditions and physical saturation
   limits per spec.
5. **No silent fixes.** If the model fails to compile or simulate, report the error and
   the attempted fix as separate facts — never tweak spec-derived values to make it pass.
6. **Self-check before handover**: simulate the spec's scenario and evaluate every
   acceptance criterion. Report each as PASS/FAIL with the measured value. A FAIL is a
   *finding to report*, not a thing to hide or paper over. **Beware output ordering** —
   verify which outport is which (`get_param(...,'Port')`) before reading results.
7. **Do not touch the held-back validation data** (spec's reserved section). That
   comparison is the engineer's independent step, after handover.
8. Annotate the model canvas with: model name, spec version reference, "DRAFT —
   pending engineer validation", and structure labels.

## Handover report (chat output after generation)

1. Block list with spec traceability (block → spec cell)
2. Simulation result: acceptance-criteria table, PASS/FAIL each, measured values
3. Any deviations, errors encountered (including recovered ones), or spec defects found
4. Explicit reminder: model is a draft; held-back validation and final sign-off belong
   to the engineer
