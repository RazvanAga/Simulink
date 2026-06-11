# TI_BQ76952 — Architecture & Block Reference

> **Status: DRAFT — generated documentation, pending engineer validation.**
> Source of truth: `3_spec/spec.md` (engineer-signed 11.06.2026). Every parameter cited
> below is traceable to a spec table cell; provenance tags (`DS`, `TRM`, `ASSUMED`,
> `DERIVED`) are inherited from the spec. Held-back SOV validation (spec §8) has **not**
> been performed — it is the engineer's pending step.

---

## 1. Model Purpose

The model (`TI_BQ76952.slx`) simulates the **voltage protection state machine of the
Texas Instruments BQ76952 battery monitor IC**, parameterized for a **14s NMC pack**
(typical 48 V e-bike/LEV architecture, spec §3). It is a pure logic/timing model —
discrete fixed-step at `T_s` = 1 ms — with no electrical, thermal, or ADC-error
modeling (per config).

At every time step the model answers:

- Is **any** cell above the overvoltage threshold (COV), and has it been so long
  enough to count as a real fault rather than a transient?
- Is **any** cell below the undervoltage threshold (CUV), under the same delay rule?
- Once a fault is latched, has the cell voltage recovered **far enough past the
  threshold** (hysteresis) to safely clear the flag?

## 2. Physical Basis

The BQ76952 hardware qualifies a voltage violation through a programmable delay timer
and clears it through a recovery hysteresis. Each mechanism maps to a model element:

| Mechanism | Physical cause | Time scale | Modeled by |
|---|---|---|---|
| Cell overvoltage | NMC chemistry upper limit (Li plating / electrolyte oxidation risk above ~4.25 V) | threshold crossing, instantaneous | `COV_Normal → COV_Delay_Count` guard |
| Cell undervoltage | NMC lower limit (copper dissolution risk below ~2.75 V) | threshold crossing, instantaneous | `CUV_Normal → CUV_Delay_Count` guard |
| Delay qualification | Hardware COV/CUV delay timer (3.3 ms steps, TRM) rejects measurement noise and load transients | 330 ms (spec §3) | `*_Delay_Count` states + tick counters |
| Recovery hysteresis | Prevents flag chatter when voltage hovers at the threshold | 100 mV band | `*_Faulted → *_Normal` guards |
| Worst-cell selection | Protection acts on ANY cell violating (spec §5) | per sample | `Max_Cell_Voltage` / `Min_Cell_Voltage` reduction |

Topology assumptions: 14 ideal cell-voltage signals, sampled jointly and noise-free —
ADC accuracy (< 10 mV typ., `DS`) and the 3 ms ADC sample rate of §3 are **not**
modeled; the chart sees exact voltages every 1 ms. The hardware's 3.3 ms timer
granularity is mapped to 1 ms chart ticks (same 330 ms physical delay — see §8).

## 3. System Architecture

### 3.1 Signal path (as built)

```
Stimulus (spec §6):
  Cell5_Step_Trigger ──┐
  Cell5_Step_Hyst_Band ┼→ Cell5_Stimulus_Sum → Cell5_Injection_Gain ─┐  (scalar → cell #5 slot)
  Cell5_Step_Recovery ─┘                                             ├→ Cell_Voltage_Combiner → V_cells[14]
  Cell_Base_Voltages (3.7 V × 14) ───────────────────────────────────┘

Reduction:
  V_cells[14] ─→ Max_Cell_Voltage ─ Max_Cell_V ─→ ┐
  V_cells[14] ─→ Min_Cell_Voltage ─ Min_Cell_V ─→ ┼→ Voltage_Protection_Chart (Stateflow, 1 ms)

Chart (two parallel machines):
  COV: Normal ─[V_max ≥ 4.25]→ Delay_Count ─[count ≥ 330]→ Faulted ─[V_max ≤ 4.15]→ Normal
              ←[V_max < 4.25, instant reset]┘                          (COV_Flag = in Faulted)
  CUV: symmetric on V_min with 2.75 V / 330 ticks / 2.85 V recovery

Outputs:
  COV_Flag → Outport 1 + Scope    CUV_Flag → Outport 2 + Scope    Timer_Count_COV → Outport 3 + Scope
```

### 3.2 Protection law with measured trajectory

```
COV_Flag(t) = 1  iff  max_i V_cell_i ≥ V_COV_Thresh held for t_COV_Delay,
              cleared when max_i V_cell_i ≤ V_COV_Thresh − V_COV_Hyst
```

In the §6 scenario (measured): `Max_Cell_V` walks 3.700 → 4.300 (t=1.0 s, above the
4.25 V threshold) → 4.200 (t=2.0 s, inside the 4.15–4.25 V hysteresis band) → 4.100
(t=3.0 s, below 4.15 V recovery). `Min_Cell_V` stays 3.700 V throughout — the CUV
machine never leaves `CUV_Normal`.

### 3.3 State memory and timing

The model's only storage is in the chart: the active state of each parallel machine
and two tick counters. `Timer_Count_COV` ramps 0 → 330 over exactly 330 ms
(1 count/ms), then **holds 330 while `COV_Faulted` is active** (measured: 330 at
t=2.5 s) and resets to 0 only on re-entry to `COV_Normal` (measured: 0 at t=3.5 s).
A drop below threshold during counting resets instantly via the `Delay_Count → Normal`
transition (spec §9.2 assumption, engineer-confirmed at sign-off).

## 4. Block-by-Block Reference

### Stimulus region (spec §6 test profile)

**`Cell_Base_Voltages` — Constant.** Value: `Cell_Base_V * ones(num_cells,1)` =
3.7 V × 14 (`Cell_Base_V` = 3.7, §6; `num_cells` = 14, §3 `ASSUMED`). The quiescent
pack. To run a different scenario, replace the stimulus region with From Workspace or
Signal Editor feeding 14 channels.

**`Cell5_Step_Trigger` — Step.** Time `t_Phase1` = 1.0 s, final value
`V_Cell5_Phase1 − Cell_Base_V` = +0.6 V (§6). Raises cell #5 to 4.3 V — the COV
trigger. Note: this release's Step block uses `InitialValue`/`FinalValue` parameter
names (a Stage-2 recovered error; no spec value was changed).

**`Cell5_Step_Hyst_Band` — Step.** Time `t_Phase2` = 2.0 s, final value
`V_Cell5_Phase2 − V_Cell5_Phase1` = −0.1 V (§6). Drops cell #5 to 4.2 V — inside the
hysteresis band, must NOT clear the flag (AC4).

**`Cell5_Step_Recovery` — Step.** Time `t_Phase3` = 3.0 s, final value
`V_Cell5_Phase3 − V_Cell5_Phase2` = −0.1 V (§6). Drops cell #5 to 4.1 V — below the
4.15 V recovery level, clears the flag (AC5).

**`Cell5_Stimulus_Sum` — Sum (+++).** Composes the three steps into the scalar cell #5
deviation profile (0 / +0.6 / +0.5 / +0.4 V).

**`Cell5_Injection_Gain` — Gain (element-wise).** Gain: `Cell5_Select` = 14×1 vector,
1 at index `Stim_Cell_Idx` = 5, else 0 (§6). Broadcasts the scalar deviation into a
14-vector that perturbs only cell #5. Kept as an explicit block so swapping the
stimulus cell is a one-variable change in `TI_BQ76952_params.m`.

**`Cell_Voltage_Combiner` — Sum (++).** `V_cells[14]` = base vector + injection.
Measured range over the run: 3.7 to 4.3 V.

### Reduction region (config fixed architecture)

**`Max_Cell_Voltage` — MinMax (max, 1 input).** Collapses `V_cells[14]` to the worst
cell for overvoltage. Implements §5's "if ANY cell ≥ threshold" exactly, because
max(V) ≥ thresh ⇔ ∃i: V_i ≥ thresh. Output signal `Max_Cell_V`.

**`Min_Cell_Voltage` — MinMax (min, 1 input).** Same reduction for undervoltage.
Output signal `Min_Cell_V` (constant 3.7 V in this scenario).

### Protection chart (spec §5; Stateflow authorized by config for this model family)

**`Voltage_Protection_Chart` — Stateflow Chart.** MATLAB action language, discrete
update at `SampleTime` = `T_s` = 1 ms (§6). Decomposition: **parallel (AND)** — two
independent machines; chart execution order is `CUV_Machine` (1) then `COV_Machine`
(2), immaterial since they share no data. The parallel architecture is what satisfies
the config's extensibility constraint: a third latching SOV machine (spec §8) can be
added alongside without restructuring.

Chart parameters (resolved from `TI_BQ76952_params.m` at the run):

| Chart parameter | Value | Spec cell |
|---|---|---|
| `V_COV_Thresh` | 4.25 V | §3 `ASSUMED` (NMC upper limit) |
| `V_COV_Hyst` | 0.100 V | §3 `ASSUMED` (noise margin) |
| `N_COV_Delay_Ticks` | 330 | `DERIVED` §3 t_COV_Delay / §6 T_s — **not** the §4 hardware count of 100 (see §8) |
| `V_CUV_Thresh` | 2.75 V | §3 `ASSUMED` (NMC lower limit) |
| `V_CUV_Hyst` | 0.100 V | **NOT a spec cell** — mirrored from `V_COV_Hyst` per §5 "identical logic" (see §8) |
| `N_CUV_Delay_Ticks` | 330 | `DERIVED` §3 t_CUV_Delay / §6 T_s |

COV machine (states exclusive within the parallel region):

| Element | Behavior | Spec basis |
|---|---|---|
| `COV_Normal` (default) | entry: `COV_Flag = 0; Timer_Count_COV = 0;` — flag clear, timer reset | §5 |
| `COV_Normal → COV_Delay_Count` | guard `[V_max >= V_COV_Thresh]` | §5 "If ANY cell ≥ threshold, start delay timer" |
| `COV_Delay_Count` | during: `Timer_Count_COV++` (1 count per 1 ms tick) | §5 delay timer |
| `COV_Delay_Count → COV_Faulted` (order 1) | guard `[Timer_Count_COV >= N_COV_Delay_Ticks]` | §3 t_COV_Delay |
| `COV_Delay_Count → COV_Normal` (order 2) | guard `[V_max < V_COV_Thresh]` — **instant** timer reset on drop | §9.2 assumption, signed off |
| `COV_Faulted` | entry: `COV_Flag = 1;` | §5 |
| `COV_Faulted → COV_Normal` | guard `[V_max <= V_COV_Thresh - V_COV_Hyst]` (≤ 4.15 V) | §4 derived recovery threshold |

CUV machine: identical shape on `V_min` with mirrored guards
(`[V_min <= V_CUV_Thresh]` to start, `[V_min >= V_CUV_Thresh + V_CUV_Hyst]`
i.e. ≥ 2.85 V to recover), local counter `Timer_Count_CUV` (not exported — §6 lists
only the COV timer as an output).

Two timing subtleties, both standard Stateflow semantics, both measured:

- Exit transitions are evaluated **before** the `during` action, so the flag asserts
  one tick after the counter reaches 330: condition true from t = 1.000 s, count = 330
  at t = 1.330 s, `COV_Flag` = 1 at **t = 1.331 s** — inside AC3's ±1 ms but at its
  edge.
- `Timer_Count_COV` is reset only on `COV_Normal` entry, so it **holds 330 during the
  faulted phase** (visible on the scope from 1.331 s to 3.0 s). A reader expecting a
  free-running or auto-zeroing timer will misread the trace.

### Instrumentation region

**`COV_Flag` — Outport 1.** Overvoltage fault flag (§6 output). Port order verified
in Stage 2 via `get_param(...,'Port')`.

**`CUV_Flag` — Outport 2.** Undervoltage fault flag (§6 output); constant 0 in this
scenario.

**`Timer_Count_COV` — Outport 3.** COV delay counter in **1 ms chart ticks, 0–330**
(§6 output; AC2). Note the unit deviation from the §4 hardware count — see §8.

**`Protection_Scope` — Scope (3 inputs).** Live traces of the three outputs, in the
same order as the outports.

## 5. Signal Summary

| Signal | Source | Destination(s) | Units | Measured value/range in scenario |
|---|---|---|---|---|
| step deviations | 3 × Step | `Cell5_Stimulus_Sum` | V | 0/+0.6, 0/−0.1, 0/−0.1 |
| cell #5 deviation | `Cell5_Stimulus_Sum` | `Cell5_Injection_Gain` | V | 0 → 0.6 → 0.5 → 0.4 |
| injection [14] | `Cell5_Injection_Gain` | `Cell_Voltage_Combiner` | V | row 5 active, others 0 |
| base [14] | `Cell_Base_Voltages` | `Cell_Voltage_Combiner` | V | 3.7 (constant) |
| `V_cells` [14] | `Cell_Voltage_Combiner` | `Max_Cell_Voltage`, `Min_Cell_Voltage` | V | 3.7 – 4.3 |
| `Max_Cell_V` | `Max_Cell_Voltage` | chart input `V_max` | V | 3.7 → 4.3 → 4.2 → 4.1 |
| `Min_Cell_V` | `Min_Cell_Voltage` | chart input `V_min` | V | 3.7 (constant) |
| `COV_Flag` | chart | Outport 1, Scope | — | 0 → 1 (1.331 s) → 0 (3.000 s) |
| `CUV_Flag` | chart | Outport 2, Scope | — | 0 throughout |
| `Timer_Count_COV` | chart | Outport 3, Scope | ticks (1 ms) | 0 → 330 (ramp 1.001–1.330 s, held to 3.0 s, then 0) |
| `Timer_Count_CUV` | chart-local | (not exported) | ticks (1 ms) | 0 throughout |

## 6. Simulation Results (scenario spec §6 — measured, all acceptance criteria PASS)

Fresh run of the on-disk model, fixed-step discrete, `T_s` = 1 ms, 0–4 s:

| # | Criterion | Required | Measured | |
|---|---|---|---|---|
| AC1 | Normal operation | both flags 0 on [0, 1.0 s] | max(COV) = 0, max(CUV) = 0 | ✅ |
| AC2 | Timer execution | counting begins at t = 1.0 s | 0 through 1.000 s, first increment at 1.001 s | ✅ |
| AC3 | Flag assertion | 0→1 at 1.33 s ± 1 ms | 1.331 s (tolerance edge — see §4 subtlety) | ✅ |
| AC4 | Hysteresis rejection | flag held 1 on [2.0, 3.0) at 4.2 V | min(COV_Flag) = 1 | ✅ |
| AC5 | Recovery | 1→0 at t = 3.0 s | 3.000 s | ✅ |

Sanity (not formal ACs): CUV_Flag 0 over the full run; `Timer_Count_COV` peak 330.

## 7. Known Limitations & Pending Validation

- **Chemistry assumption (spec §9.1):** all thresholds are NMC (`ASSUMED`). A LiFePO4
  target would require `V_COV_Thresh` ≈ 3.65 V. Signed off for NMC.
- **Timer reset behavior (spec §9.2):** TRM does not specify reset-vs-decrement on a
  momentary drop below threshold during the delay; the model resets instantly. Signed
  off as assumption.
- **CUV hysteresis is not a spec cell:** `V_CUV_Hyst` = 100 mV is mirrored from the
  COV value per §5 "identical logic" — flagged in `TI_BQ76952_params.m`; engineer
  should confirm against the TRM's CUV recovery definition.
- **Timer unit deviation from §4:** spec §4 derives 100 ticks at the hardware's 3.3 ms
  step; the model counts 330 ticks at the 1 ms simulation step — the same 330 ms, but
  `Timer_Count_COV` is **not numerically comparable** to the BQ76952 register value.
- **Not modeled (config / spec §5):** ADC accuracy and 3 ms conversion rate, SCD/OCD/
  OCC current protections, temperature, balancing, comms, coulomb counting.
- **Source gap noted at Stage 1:** `1_raw_data/` contains only the TRM; the datasheet
  (SLUSE13B) rows of the spec were signed off without the PDF present in the folder.
- **Independent validation pending (spec §8):** SOV permanent-fail re-parameterization
  (4.40 V / 50 ms, latching, no recovery) against the parallel-chart architecture —
  **the engineer's step, not performed here.** The model remains DRAFT until then.

---

*Documentation format: generic harness template v1. A team-specific documentation
template would be encoded as a skill and produce this report in the team's own format.*
