# AI-Enhanced Model-Based Design (MBD) Harness

> **An AI agent harness for Model-Based Design:** Automates Simulink model generation and documentation from raw supplier PDFs with strict human-in-the-loop validation.

This repository is a Proof-of-Concept (PoC) demonstrating how Large Language Models (LLMs) can be transformed into an engineering force-multiplier for system simulation teams. By wrapping a generic AI in a strict domain-specific **harness** (prompts, rules, and validation gates), this pipeline securely bridges the gap between raw supplier datasheets and fully functional, traceable Simulink models.

---

## The Vision: AI as a Multiplier, Not a Replacement

The bottleneck in system modeling isn't model intelligence; it's domain grounding. This workflow explicitly addresses safety and compliance (e.g., ISO 26262) by enforcing that **the human engineer remains the author and validator**. The AI handles the boilerplate, parameter extraction, and initial canvas layout. 

**Key Guardrails:**
- **Zero Hallucinations:** Every numeric block parameter must be traceable to a specific cell in the specification document. No "magic numbers."
- **Strict Human Gates:** AI model generation cannot proceed without explicit engineer sign-off on the extracted data.
- **Separation of Data:** Identification data (used to build the model) is strictly separated from validation data (held back for testing).

---

## Pipeline Architecture

The workflow operates in three gated stages, separated by rigid folder structures to prevent context contamination:

    STAGE 1                      GATE             STAGE 2                    STAGE 3
    1_raw_data/*.pdf             ENGINEER         3_spec/spec.md             4_model/*.slx
      → [extraction prompt] →    SIGN-OFF    →    → [generation prompt] →    → [docs generation] →
    3_spec/spec.md               (human!)         4_model/ (.slx + .m)       5_docs/architecture.md

### Folder Layout
| Folder | Contents | Rules |
|---|---|---|
| `1_raw_data/` | Raw supplier PDFs (datasheets, test reports). | Read-only during Stage 1. |
| `2_prompts/` | Pipeline runbook & prompt artifacts (the "Harness"). | Version-controlled, encodes team standards. |
| `3_spec/` | `spec.md` (Stage 1 Output). | **Single Source of Truth.** Needs human sign-off. |
| `4_model/` | `.slx` and `_params.m` files (Stage 2 Output). | Draft Simulink model. Parameters map 1:1 to `spec.md`. |
| `5_docs/` | `_architecture.md` (Stage 3 Output). | Auto-generated from the *actual built model*, not intentions. |

---

## Demo Application: 48V Molicel P45B Battery Pack

This repository contains a fully verified run of the pipeline, creating a **pack-level 2nd-order Thevenin Equivalent Circuit Model (ECM)** for a 13s4p 48V battery pack, using real-world data from the Molicel INR-21700-P45B cell.

* **Input:** Official P45B datasheets & test reports.
* **Output:** A clean, routing-optimized Simulink `.slx` model simulating a 1C (18A) discharge with active undervoltage, overcurrent, and temperature protection limits.
* **Validation:** Passes criteria derived directly from the datasheet (e.g., stops exactly at the 32.5V undervoltage cutoff).

---

## How to Run the Demo

If you have MATLAB and Simulink installed, you can inspect and run the generated artifacts directly:

    cd 4_model
    molicel_48v_pack_params           % Load the spec-traceable parameters into the workspace
    open_system('molicel_48v_pack')   % Open the AI-generated model draft
    sim('molicel_48v_pack');          % Run 18 A (1C) discharge scenario

*(The simulation will automatically hit the 32.5V undervoltage cutoff at ~3585s, as specified in the generated requirements).*

---

## Requirements & Tech Stack

* **MATLAB / Simulink** (Tested on R2023b+)
* **Agentic IDE or CLI:** VS Code with an AI agent (e.g., Claude Code, GitHub Copilot) configured with the **MATLAB Model Context Protocol (MCP)** server to allow the AI to execute MATLAB commands and build models interactively.

---
*Disclaimer: The artifacts in this repository are for demonstration purposes. The generated models are drafts pending human engineering validation.*