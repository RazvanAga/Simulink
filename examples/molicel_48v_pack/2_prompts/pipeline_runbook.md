# Pipeline Runbook — Raw Supplier Data → Spec → Model → Docs

> **Audience: an agent with ZERO prior context.** Everything you need is in this
> document and the files it points to. Do not rely on conversation history, memory of
> other sessions, or external knowledge about the product — the pipeline is designed so
> you never have to.
>
> **Harness artifact #0 (the orchestrator).** Versioned and team-customizable like the
> stage prompts it invokes. To run this pipeline for a NEW product, replicate the folder
> structure below in a new `examples/<product>/` folder and adapt the stage prompts'
> "Target model" section.

---

## What this pipeline is

You will turn raw supplier documents (PDFs) into a validated, simulating Simulink model
with generated documentation, in three gated stages:

```
STAGE 1                      GATE             STAGE 2                    STAGE 3
1_raw_data/*.pdf             ENGINEER         3_spec/spec.md             4_model/*.slx
  → [extraction prompt] →    SIGN-OFF    →    → [generation prompt] →    → [docs spec below] →
3_spec/spec.md               (human!)         4_model/ (.slx + .m)       5_docs/architecture.md
```

The pipeline's entire purpose is **trustworthiness through separation**:
data (spec) is separated from procedure (prompts); identification data is separated
from validation data; and a human gate sits between extraction and generation.

## Folder layout (fixed contract)

| Folder | Contents | You may… |
|---|---|---|
| `1_raw_data/` | Raw supplier PDFs | READ during Stage 1 ONLY |
| `2_prompts/` | This runbook + stage prompts | READ; modify only if asked |
| `3_spec/` | `spec.md` (output of Stage 1) | WRITE in Stage 1; READ-ONLY afterwards |
| `4_model/` | `.slx` + `<model>_params.m` (output of Stage 2) | WRITE in Stage 2 |
| `5_docs/` | `<model>_architecture.md` (output of Stage 3) | WRITE in Stage 3 |

## Global hard rules (apply to every stage)

1. **Provenance or it doesn't exist.** Every number carries its source (document + page,
   or formula, or an explicit `ASSUMED` tag with justification). Never silently invent.
2. **No silent fixes.** Errors are findings to report, not things to paper over. Never
   tweak a spec-derived value to make something pass.
3. **Human gates are mechanical, not advisory.** If a required sign-off is missing, STOP
   and tell the user. Do not proceed "provisionally".
4. **Held-back validation data stays held back.** The spec designates data reserved for
   independent post-model validation — no pipeline stage may consume it.
5. **English output**, engineering register. Every generated artifact states its own
   status (e.g. "DRAFT — pending engineer validation").

---

## STAGE 1 — Extraction: raw PDFs → spec

1. Read `2_prompts/spec_extraction_prompt.md` and follow it exactly. Summary: read all
   PDFs in `1_raw_data/`, produce `3_spec/spec.md` with the 8-section structure defined
   there (sources w/ provenance, cell/product parameters, model parameters, derived
   topology, protection subset, simulation scenario, acceptance criteria, held-back
   validation data, open items).
2. Surface anything noteworthy to the user in chat: document contradictions, gaps,
   assumptions you had to make, design caveats. These are *selling points of the
   process*, not embarrassments.
3. **STOP. Tell the user the spec awaits their review and sign-off** (the
   `VALIDATED BY:` block at the end of spec.md, filled in by the human, by hand).
   Point them specifically at the `ASSUMED` entries and the Open items section.

**Done when:** `3_spec/spec.md` exists, and you have explicitly asked for sign-off.

## STAGE 2 — Generation: signed spec → Simulink model

**Precondition (check it first):** the sign-off block in `3_spec/spec.md` is filled in.
Empty → STOP and report.

1. Read `2_prompts/model_generation_prompt.md` and follow it exactly. Summary:
   - Build `4_model/<model>_params.m` first: every spec value as a named variable,
     commented with its spec section. No magic numbers anywhere in the model.
   - Run the params script in MATLAB, create the model, build it with the `model_edit`
     MCP tool (read the `building-simulink-models` skill if available). Architecture is
     fixed in the generation prompt — do not improvise; where spec and prompt sketch
     disagree, **spec wins, and you report the deviation**.
   - Put the spec reference of every numeric parameter in the block's Description field.
   - Annotate the canvas: model name, spec reference, "DRAFT — pending engineer validation".
2. Self-check: run `model_check` (structure), then simulate the spec's scenario and
   evaluate **every acceptance criterion** from the spec. Beware output ordering —
   verify which outport is which before reading results (`get_param(...,'Port')`).
3. Save the model. Re-run the simulation once more to confirm repeatability.
4. Post the **handover report** in chat: block list w/ traceability, AC table with
   measured values and PASS/FAIL, all deviations and errors encountered (including ones
   you recovered from — report them anyway), and the reminder that the model is a draft
   pending the engineer's independent validation against the held-back data.

**Done when:** model simulates, all ACs evaluated and reported, handover report posted.

## STAGE 3 — Documentation: model → architecture doc

Generate `5_docs/<model>_architecture.md` from the **actual built model and actual
simulation results** (never from intentions — if Stage 2 deviated, the doc reflects
what was built). Required structure:

1. **Header**: status banner (DRAFT, pending validation), pointer to spec as source of truth
2. **Model purpose** — what it simulates, what questions it answers
3. **Physical basis** — mechanism → time scale → which block models it
4. **System architecture** — signal-path diagram (ASCII), governing equation with
   numeric contributions from the actual sim, dynamics of each storage element
5. **Block-by-block reference** — for EVERY block: type, exact parameter values with
   spec provenance tags, role in the system, and any non-obvious subtleties (e.g. why
   a separate gain instead of scaling a table; output port ordering pitfalls)
6. **Signal summary table** — source, destinations, units, actual range in the scenario
7. **Simulation results** — metric table mapped to acceptance criteria
8. **Known limitations & pending validation** — inherited from spec open items, plus
   anything Stage 2 added; explicit, not buried
9. **Footer**: `Documentation format: generic harness template v1...` (team-template note)

**Done when:** the doc exists and a reader could defend every block in the model
without opening MATLAB.

---

## Failure handling

- A stage that cannot complete reports *what it has*, *what blocked it*, and *what it
  needs* — then stops. Partial silent output is worse than no output.
- MATLAB/MCP errors: diagnose root cause; never bypass `model_edit` with raw
  `add_block`/`set_param` to force progress.
- If you discover a defect in an upstream artifact (e.g. spec value impossible to
  implement), do not patch it downstream: report it, propose the upstream fix, wait.

## Reference implementation

This folder is itself a completed run of the pipeline (Molicel P45B → 13s4p 48 V pack):
use its artifacts as ground truth for format and tone whenever this runbook
underspecifies something.
