# Model Generation Prompt — Validated Spec → Simulink Model

> **Harness artifact #2.** Pipeline position:
> `raw PDFs → [spec_extraction_prompt] → spec.md → [ENGINEER SIGN-OFF] → [THIS PROMPT] → .slx`
> Like the extraction prompt, this is versioned and **modified to encode team standards**
> (naming conventions, approved block sets, structure rules). Today it carries my generic
> conventions; in the pilot, it would carry the team's.

---

## Role

Generate a Simulink model implementing **exactly** what `spec.md` defines. You are the
draft-producing step; the engineer validates the result. Nothing you produce is trusted
until it passes the spec's acceptance criteria and human review.

## Input — single source of truth

- `../3_spec/spec.md`, **only if it carries engineer sign-off**. If the sign-off
  block is empty, STOP and report — do not generate.
- **You MUST NOT read the raw PDFs.** If a needed value is missing from the spec, that
  is a spec defect: stop and report it; never fill the gap from memory or other sources.

## Output

- `../4_model/molicel_48v_pack.slx` (+ its parameter script) — a 13s4p pack-level
  2nd-order Thevenin ECM per spec §3–§4, with the protection subset of §5, simulating
  the scenario of §6.

## Architecture (fixed — do not improvise)

Two coupled paths, mirroring the standard Thevenin ECM layout:

```
Path A (state):    I_load → SOC_Rate_Gain → SOC_Integrator → OCV_Table ─┐
Path B (drops):    I_load → R0_Gain ────────────────────────────────────┤
                   I_load → RC1_Branch (TF) ────────────────────────────┼→ V_Pack_Sum → V_pack
                   I_load → RC2_Branch (TF) ────────────────────────────┘   (+ − − −)
Protection:        V_pack → UV_Cutoff_Compare (< pack cutoff) → Stop/flag
                   I_load → OC_Compare (> max continuous)     → flag
Outputs:           V_pack, SOC, flags → Outports + Scopes
```

## Hard rules

1. **Every numeric block parameter must be traceable to a spec table cell.** Put the
   spec reference in the block's Description field (e.g. `spec §4: Pack R0 = 22.75 mΩ`).
   No magic numbers.
2. **Basic library blocks only** (Gain, Integrator, Lookup Table, Transfer Fcn, Sum,
   Compare, Constant, Scope, Outport). No Simscape, no Simscape Battery — the audience
   must be able to read every block. (Team-standard block sets would be encoded here.)
3. **Naming convention** (placeholder for team standards): `PascalCase_With_Underscores`,
   role-revealing names (`SOC_Integrator`, not `Integrator1`).
4. **SOC integrator**: initial condition and [0,1] saturation per spec §6/§4.
5. **No silent fixes.** If the model fails to compile or simulate, report the error and
   the attempted fix as separate facts — never tweak spec-derived values to make it pass.
6. **Self-check before handover**: simulate the §6 scenario and evaluate acceptance
   criteria AC1–AC6 (spec §7). Report each as PASS/FAIL with the measured value.
   A FAIL is a *finding to report*, not a thing to hide or paper over.
7. **Do not touch the held-back validation data** (spec §8). High-rate comparison is the
   engineer's independent step, after handover.
8. Annotate the model canvas with: model name, spec version reference, "DRAFT —
   pending engineer validation", and the two-path structure labels.

## Handover report (chat output after generation)

1. Block list with spec traceability (block → spec cell)
2. Simulation result: AC1–AC6 table, PASS/FAIL each, measured values
3. Any deviations, errors encountered, or spec defects found
4. Explicit reminder: model is a draft; §8 validation and final sign-off belong to the engineer
```
