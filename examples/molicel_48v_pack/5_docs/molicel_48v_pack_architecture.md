# molicel_48v_pack — Architecture & Block Reference

> **Status: DRAFT — generated documentation, pending engineer validation.**
> Source of truth: `spec.md` (engineer-signed 11.06.2026). Every parameter cited below
> is traceable to a spec table cell; provenance tags (`DS`, `TR`, `ASSUMED`, `DERIVED`)
> are inherited from the spec.

---

## 1. Model Purpose

The model (`molicel_48v_pack.slx`) simulates the electrical behaviour of a **48 V-class
battery pack built from 52 Molicel INR-21700-P45B cells in a 13s4p arrangement**
(13 in series × 4 in parallel), discharged at a constant 1C pack rate (18 A). It
implements a **second-order Thevenin Equivalent Circuit Model (ECM)** scaled from cell
to pack level — the standard industry approach for battery state estimation in BMS and
HIL applications.

The model answers three questions at every point in time:

- What is the **pack terminal voltage** delivered to the load?
- What is the **state of charge** remaining?
- Are any **protection limits** (undervoltage, overcurrent, temperature window) violated?

## 2. Physical Basis

A battery is not an ideal voltage source. Under load, four mechanisms shape the
terminal voltage simultaneously:

| Mechanism | Physical cause | Time scale | Modeled by |
|---|---|---|---|
| Ohmic drop | Electrolyte, collector and contact resistance | instantaneous | `R0_Gain` |
| Fast polarisation | Charge-transfer / double-layer dynamics | τ1 = 3 s | `RC1_Branch` |
| Slow polarisation | Solid-state diffusion in electrodes | τ2 = 50 s | `RC2_Branch` |
| OCV shift | Electrochemical potential vs. lithium inventory | minutes–hours | `OCV_Cell_Table` |

Pack scaling (spec §4): series cells add voltage and resistance (×13); parallel strings
add capacity and divide resistance and current (÷4). Identical cells and perfect current
sharing are assumed — a stated first-order limitation.

## 3. System Architecture

### 3.1 Three signal regions

```
Path A — state (slow):
  I_Load ─→ SOC_Rate_Gain ─→ SOC_Integrator ─→ OCV_Cell_Table ─→ Pack_OCV_Gain ─→ V_Pack_Sum (+)

Path B — voltage drops (fast):
  I_Load ─→ R0_Gain      ─→ V_Pack_Sum (−)   [instantaneous]
  I_Load ─→ RC1_Branch   ─→ V_Pack_Sum (−)   [τ ≈ 3 s]
  I_Load ─→ RC2_Branch   ─→ V_Pack_Sum (−)   [τ ≈ 50 s]

Protection (monitors):
  V_Pack_Sum ─→ UV_Compare ─→ UV_Stop + UV_Flag_Out
  I_Load ─→ I_Abs ─→ OC_Compare ─→ OC_Flag_Out
  I_Load ─→ I_Cell_Gain ─→ I_Cell_Out
  T_Ambient ─→ Temp_In_Window ─→ Temp_Violation ─→ Temp_Flag_Out
```

### 3.2 Terminal voltage equation

```
V_pack(t) = 13·OCV(SOC(t)) − R0_pack·I − V_RC1(t) − V_RC2(t)
```

At steady 18 A discharge the three drop terms contribute:
R0: 0.410 V · RC1: 0.322 V · RC2: 0.234 V — ≈ 0.97 V total below pack OCV.

### 3.3 RC branch dynamics

Each polarisation branch is a first-order transfer function:

```
V_RC(s)      R_pack
──────── = ──────────        (τ = R_cell·C_cell, invariant under pack scaling)
  I(s)       τs + 1
```

Time domain: `dV_RC/dt = (R_pack·I − V_RC)/τ` — exponential build-up toward `R_pack·I`,
exponential relaxation when the load changes.

## 4. Block-by-Block Reference

### Path A — state

**`I_Load` — Constant.** Output: `I_load_pack` = 18 A (spec §6, 1C pack rate; 4.5 A per
cell, 10× below the 45 A DS limit). The single source of load current; fans out to six
blocks. To change the load profile, replace with Signal Editor or From Workspace.

**`SOC_Rate_Gain` — Gain.** Gain: `SOC_rate_gain` = −1/(18 Ah · 3600 s) =
−1.5432×10⁻⁵ (spec §4). Converts pack current [A] into SOC rate [1/s]; the negative
sign encodes that discharge removes charge. At 18 A the output is −2.778×10⁻⁴/s, i.e.
100% → 0% in exactly 3600 s of ideal Coulomb counting.

**`SOC_Integrator` — Integrator.** IC = `SOC_initial` = 1.0 (spec §6); output saturated
to [0, 1] as a guard against nonphysical SOC under numerical drift. The pack's only
state memory besides the two RC branches. Fans out to `OCV_Cell_Table`, `SOC_Scope`,
`SOC_Out`.

**`OCV_Cell_Table` — 1-D Lookup Table.** 14 breakpoints, SOC ∈ [0,1] → cell OCV
[2.50 … 4.19 V] (spec §3; identified from the test-report 0.2C curve, graphical read
±30 mV — the high-rate curves were deliberately *not* used, they are held back for
independent validation, spec §8). The dominant nonlinearity: plateau shape, discharge
knee and end-of-discharge collapse all come from this table. Linear interpolation
between breakpoints.

**`Pack_OCV_Gain` — Gain.** Gain: `N_series` = 13 (spec §4). Scales cell OCV to pack
OCV. Kept as an explicit block (rather than baking ×13 into the table) so the cell-level
table remains exactly what was identified from cell-level data.

### Path B — voltage drops

**`R0_Gain` — Gain.** Gain: `R0_pack` = 22.75 mΩ = 7 mΩ × 13/4 (spec §4; cell R0 from
the DS AC impedance — `DS` provenance). Memoryless ohmic drop: 0.410 V at 18 A,
visible as the instantaneous voltage step at t = 0.

**`RC1_Branch` — Transfer Fcn.** H₁(s) = 0.017875/(3s + 1). R1_pack = 17.875 mΩ,
τ1 = 3 s (spec §3 — **ASSUMED** split, anchored so that R0 + developed R1 + developed
R2 reproduces the DS 15 mΩ @10 s DCR). Fast polarisation: settles to 0.322 V within
~15 s of a load step.

**`RC2_Branch` — Transfer Fcn.** H₂(s) = 0.013/(50s + 1). R2_pack = 13.0 mΩ,
τ2 = 50 s (spec §3 — **ASSUMED**). Slow diffusion polarisation: settles to 0.234 V
after ~4 minutes.

**`V_Pack_Sum` — Sum (+−−−).** Assembles the terminal voltage: pack OCV minus the
three drops (spec §3 equation). Output fans out to `V_Pack_Scope`, `V_Pack_Out` and
`UV_Compare`.

### Protection subset (spec §5)

**`UV_Compare` — Compare To Constant (≤ `V_pack_cutoff` = 32.5 V).** Pack undervoltage
detection, 13 × 2.5 V DS cell cutoff. Drives both the flag output and:

**`UV_Stop` — Stop Simulation.** Terminates the run at cutoff — the model-level
equivalent of a BMS opening the discharge path. This is why the simulation ends at
3584.7 s rather than the 4000 s safety stop.

**`I_Abs` — Abs / `OC_Compare` — Compare To Constant (> `I_pack_max` = 180 A).**
Overcurrent flag, 4 × 45 A DS continuous limit. Constant-current scenario keeps it 0;
it becomes meaningful with dynamic load profiles.

**`I_Cell_Gain` — Gain (1/`N_parallel` = 0.25).** Per-cell current under the perfect
sharing assumption — exported so the 45 A cell limit (acceptance criterion AC5) is
directly observable.

**`T_Ambient` — Constant (23 °C) / `Temp_In_Window` — Interval Test [−40, +60] °C /
`Temp_Violation` — NOT.** Discharge temperature window check from the DS. With a
constant 23 °C scenario the flag stays 0; the chain exists so the protection subset is
structurally complete (and becomes live when a thermal model — candidate D — replaces
the constant).

### Instrumentation

**`V_Pack_Scope`, `SOC_Scope` — Scopes.** Live traces of the two headline signals.

**Outports 1–6.** `V_Pack_Out`, `SOC_Out`, `UV_Flag_Out`, `I_Cell_Out`, `OC_Flag_Out`,
`Temp_Flag_Out` → `out.yout{1..6}` for post-processing and automated test assertions.
Note the order: UV flag is port 3, per-cell current port 4.

## 5. Signal Summary

| Signal | Source | Destination(s) | Units | Value/Range in scenario |
|---|---|---|---|---|
| I_pack | `I_Load` | SOC path, R0, RC1, RC2, I_Abs, I_Cell_Gain | A | 18 (constant) |
| dSOC/dt | `SOC_Rate_Gain` | `SOC_Integrator` | 1/s | −2.778×10⁻⁴ |
| SOC | `SOC_Integrator` | `OCV_Cell_Table`, scope, out | — | 1.0 → 0.004 |
| OCV_cell | `OCV_Cell_Table` | `Pack_OCV_Gain` | V | 4.19 → ~2.51 |
| OCV_pack | `Pack_OCV_Gain` | `V_Pack_Sum` (+) | V | 54.5 → ~32.7 |
| V_R0 | `R0_Gain` | `V_Pack_Sum` (−) | V | 0.410 |
| V_RC1 | `RC1_Branch` | `V_Pack_Sum` (−) | V | 0 → 0.322 |
| V_RC2 | `RC2_Branch` | `V_Pack_Sum` (−) | V | 0 → 0.234 |
| V_pack | `V_Pack_Sum` | scope, out, `UV_Compare` | V | 54.06 → 32.50 |
| I_cell | `I_Cell_Gain` | `I_Cell_Out` | A | 4.50 |

## 6. Simulation Results (scenario spec §6, all acceptance criteria PASS)

| Metric | Value | Acceptance criterion |
|---|---|---|
| Initial loaded voltage V_pack(0⁺) | 53.95 V | AC1: 52.5–54.5 V ✅ |
| UV cutoff (32.5 V) reached at | 3584.7 s (59.7 min) | AC2: 3300–3650 s ✅ |
| SOC at cutoff | 0.42% | AC3: < 6% ✅ |
| SOC monotonicity | strictly decreasing | AC4 ✅ |
| Max per-cell current | 4.50 A | AC5: ≤ 45 A ✅ |
| V_pack envelope during run | 32.50 – 54.06 V | AC6: within 32.4–54.6 V ✅ |
| OC / Temp flags | 0 throughout | expected ✅ |

## 7. Known Limitations & Pending Validation

- RC parameter split is **ASSUMED** (anchored to two datasheet impedance points, not
  uniquely identified) — spec §9.1.
- OCV table is a **graphical read** of the 0.2C curve (±30 mV) — spec §9.2.
- Identical cells / perfect current sharing; no balancing, contactors, charging,
  thermal dynamics or aging — spec §5 out-of-scope list.
- **Independent validation pending (spec §8):** comparison of a cell-level 45 A
  simulation against the held-back measured 45 A curve — engineer's step, using data
  the model has never seen.

---

*Documentation format: generic harness template v1. A team-specific documentation
template would be encoded as a skill and produce this report in the team's own format.*
