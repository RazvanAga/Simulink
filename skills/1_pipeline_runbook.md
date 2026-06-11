# Pipeline Runbook — Raw Supplier Data → Spec → Model → Docs

> **Audience: an agent with ZERO prior context.** Everything you need is in this
> document and the files it points to. Do not rely on conversation history, memory of
> other sessions, or external knowledge about the product — the pipeline is designed so
> you never have to.
>
> **Harness skill #0 (the orchestrator) — generic, shared by all examples.** The skills
> in `/skills` are product-agnostic; everything product-specific lives in the example's
> `2_config/pipeline_config.md`. To run this pipeline for a NEW product: create
> `examples/<product>/` with the folder contract below, drop the supplier PDFs in
> `1_raw_data/`, write a `pipeline_config.md`, then follow the stages.

---

## What this pipeline is

You will turn raw supplier documents (PDFs) into a validated, simulating Simulink model
with generated documentation, in three gated stages:

```
STAGE 1                      GATE             STAGE 2                    STAGE 3
1_raw_data/*.pdf             ENGINEER         3_spec/spec.md             4_model/*.slx
  → [extraction skill] →     SIGN-OFF    →    → [generation skill] →     → [docs skill] →
3_spec/spec.md               (human!)         4_model/ (.slx + .m)       5_docs/architecture.md
```

The pipeline's entire purpose is **trustworthiness through separation**:
data (spec) is separated from procedure (skills); product config is separated from
generic skills; identification data is separated from validation data; and a human gate
sits between extraction and generation.

## Repository layout (fixed contract)

| Location | Contents | You may… |
|---|---|---|
| `/skills/` | This runbook + the generic stage skills | READ; modify only if asked |
| `examples/<product>/1_raw_data/` | Raw supplier PDFs | READ during Stage 1 ONLY |
| `examples/<product>/2_config/` | `pipeline_config.md` — product-specific parameterization | READ |
| `examples/<product>/3_spec/` | `spec.md` (output of Stage 1) | WRITE in Stage 1; READ-ONLY afterwards |
| `examples/<product>/4_model/` | `.slx` + `<model>_params.m` (output of Stage 2) | WRITE in Stage 2 |
| `examples/<product>/5_docs/` | `<model>_architecture.md` (output of Stage 3) | WRITE in Stage 3 |

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

1. Read `/skills/2_spec_extraction_prompt.md` and the example's
   `2_config/pipeline_config.md`; follow them exactly. Summary: read all PDFs in
   `1_raw_data/`, produce `3_spec/spec.md` with the 9-section structure defined in the
   skill (sources w/ provenance, product parameters, model parameters, derived topology,
   protection subset, simulation scenario, acceptance criteria, held-back validation
   data, open items).
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

1. Read `/skills/3_model_generation_prompt.md` and the example's config; follow them
   exactly. Summary:
   - Build `4_model/<model>_params.m` first: every spec value as a named variable,
     commented with its spec section. No magic numbers anywhere in the model.
   - Run the params script in MATLAB, create the model, build it with the `model_edit`
     MCP tool (read the `building-simulink-models` skill if available). Architecture
     comes from the config — do not improvise; where spec and config sketch disagree,
     **spec wins, and you report the deviation**.
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

Read `/skills/4_architecture_from_model.md` and the example's config; follow them
exactly. Summary: generate `5_docs/<model>_architecture.md` (9-section structure
defined in the skill) from the **actual built model and actual simulation results** —
never from intentions; if Stage 2 deviated, the doc reflects what was built. Every
block gets an entry with its exact parameter, spec provenance tag, and role in the
system. Use `examples/molicel_48v_pack/5_docs/molicel_48v_pack_architecture.md` as
the format reference.

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

`examples/molicel_48v_pack/` is a completed run of this pipeline (Molicel P45B →
13s4p 48 V pack): use its artifacts as ground truth for format and tone whenever this
runbook underspecifies something.
