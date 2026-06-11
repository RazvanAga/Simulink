# Pipeline Config — molicel_48v_pack

> Product-specific parameterization for the generic skills in `/skills`.
> This file is the ONLY place where this example's product, topology, and file names
> are defined — the skills stay product-agnostic.

## Product

- **Cell:** Molicel INR-21700-P45B (4.5 Ah high-power 21700)
- **System:** 48 V-class battery pack, **13s4p** (13 series × 4 parallel)

## Target model

- **Family:** second-order Thevenin ECM (R0 + 2×RC + OCV(SOC) lookup), cell-level
  parameters scaled to pack level
- **Protection subset to model:** undervoltage cutoff, overcurrent limit, discharge
  temperature window. **Out of scope (state explicitly):** balancing, contactor/precharge
  logic, charger (CC-CV) behavior, cell-to-cell variation, thermal dynamics, aging.

## Output file names

| Artifact | Name |
|---|---|
| Model | `4_model/molicel_48v_pack.slx` |
| Parameters | `4_model/molicel_48v_pack_params.m` |
| Docs | `5_docs/molicel_48v_pack_architecture.md` |

## Fixed architecture (Stage 2 must not improvise)

```
Path A (state):    I_load → SOC_Rate_Gain → SOC_Integrator → OCV_Cell_Table → Pack_OCV_Gain ─┐
Path B (drops):    I_load → R0_Gain ──────────────────────────────────────────────────────────┤
                   I_load → RC1_Branch (TF) ──────────────────────────────────────────────────┼→ V_Pack_Sum → V_pack
                   I_load → RC2_Branch (TF) ──────────────────────────────────────────────────┘   (+ − − −)
Protection:        V_pack → UV_Compare (≤ pack cutoff) → UV_Stop + flag
                   I_load → I_Abs → OC_Compare (> max continuous) → flag
                   I_load → I_Cell_Gain (1/N_parallel) → per-cell current out
                   T_Ambient → Temp_In_Window (DS window) → Temp_Violation (NOT) → flag
Outputs:           V_pack, SOC, UV_Flag, I_Cell, OC_Flag, Temp_Flag → Outports + Scopes
```

## Status of this run

Pipeline completed through Stage 3 (spec signed 11.06.2026; model generated, all
acceptance criteria PASS; architecture doc generated). Pending: spec §8 independent
validation (45 A held-back curve), test suite.
