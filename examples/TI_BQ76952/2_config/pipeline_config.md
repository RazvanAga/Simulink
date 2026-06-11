# Pipeline Config — TI_BQ76952

> Product-specific parameterization for the generic skills in `/skills`.
> This file is the ONLY place where this example's product, topology, and file names
> are defined — the skills stay product-agnostic.

## Product

- **Unit:** Texas Instruments BQ76952 battery monitor & protector IC (3–16 s,
  up to 85 V tolerance) — voltage protection subsystem only
- **Application config modeled:** **14s NMC** pack (typical 48 V e-bike/LEV
  architecture; chemistry assumption is open item — see spec §9.1)

## Target model

- **Family:** discrete-time **protection state machine** — 14 cell voltages in →
  max/min reduction → COV (cell overvoltage) and CUV (cell undervoltage) state
  machines with programmable delay timers and recovery hysteresis → fault flags.
  Pure logic/timing model; **no** electrical, thermal, or ADC-error modeling.
- **Block set:** unlike the other examples, this model family is authorized to use
  **Stateflow** for the COV/CUV state machines (the spec's §5 protection logic is
  inherently stateful: delay counting, latching, hysteresis). Surrounding glue
  (vector reduction, sources, outports) stays basic-library.
- **Solver:** fixed-step discrete, `T_s` = 1 ms (spec §6).
- **Extensibility constraint:** the chart architecture must accommodate a secondary
  **latching SOV loop without structural redesign** — that re-parameterization is the
  held-back validation step (spec §8). Do not implement SOV in Stage 2.
- **Protection subset to model:** COV detect + delay + recovery hysteresis; CUV
  identical logic. **Out of scope (state explicitly):** SCD/OCD/OCC current
  protections, temperature sensing, cell balancing, I2C/SPI/HDQ communication,
  coulomb counting/current ADCs.

## Output file names

| Artifact | Name |
|---|---|
| Model | `4_model/TI_BQ76952.slx` |
| Parameters | `4_model/TI_BQ76952_params.m` |
| Docs | `5_docs/TI_BQ76952_architecture.md` |

## Fixed architecture (Stage 2 must not improvise)

```
Input:        V_cells[14] (test profile per spec §6, Cell #5 is the stimulus)
Reduction:    V_cells → Max_Cell_V (MinMax max) ┐
              V_cells → Min_Cell_V (MinMax min) ┼→ Protection_Chart (Stateflow, Ts = 1 ms)
Chart (COV):  Normal ─[V_max ≥ V_COV_Thresh]→ Delay_Count (Timer_Count_COV ticks,
              instant reset on drop — spec §9.2) ─[count ≥ t_COV_Delay]→ Faulted
              Faulted ─[V_max ≤ V_COV_Thresh − V_COV_Hyst]→ Normal   (COV_Flag = state)
Chart (CUV):  symmetric machine on V_min with CUV thresholds/delay
Outputs:      COV_Flag, CUV_Flag, Timer_Count_COV → Outports + Scopes
```

## Status of this run

Stage 1 (spec extraction) executed; `3_spec/spec.md` awaiting engineer sign-off
(open items §9: cell chemistry, timer-reset behavior). Stages 2–3 not started.
⚠ Source gap: the spec cites two sources (DS `bq76952.pdf` SLUSE13B + TRM
`sluuby2b.pdf`), but `1_raw_data/` currently contains **only the TRM** — the
datasheet PDF must be added (or the spec's DS-sourced rows re-verified) before
sign-off.
