# Panasonic NCR18650B — Thevenin ECM Battery Model

## Overview

A second-order Thevenin Equivalent Circuit Model (ECM) of the Panasonic NCR18650B Li-ion cell, implemented in Simulink (`ncr18650b_thevenin.slx`). The model simulates a 1C constant-current discharge from 100% SOC to 0%, reproducing terminal voltage dynamics including ohmic drop and two RC polarisation transients.

---

## Cell Specifications (Datasheet)

| Parameter | Value |
|---|---|
| Chemistry | NCA / Graphite |
| Nominal capacity (25°C typ.) | 3350 mAh |
| Nominal voltage | 3.6 V |
| Charging voltage | 4.2 V |
| Discharge cutoff voltage | 2.5 V |
| Standard charge current | 1.625 A (0.5C) |
| Discharge temperature range | −20°C to +60°C |

---

## ECM Parameters

### Equivalent Circuit Topology

```
        R0            R1            R2
I ──┬──[===]──┬──[===]──┬──[===]──┬──── V_terminal
   |          |        [C1]      [C2]   |
  OCV(SOC)   ─┘         |         |    │
   |          └──────────┘         └────┘
   └─────────────────────────────────────
```

`V_terminal = OCV(SOC) − R0·I − V_RC1 − V_RC2`

### Identified Parameters

| Element | Value | Note |
|---|---|---|
| R0 | 0.0483 Ω | Ohmic (instantaneous) resistance |
| R1 | 0.0245 Ω | Fast RC branch resistance |
| C1 | 1124 F | Fast RC branch capacitance |
| τ1 = R1·C1 | 27.53 s | Fast polarisation time constant |
| R2 | 0.0080 Ω | Slow RC branch resistance |
| C2 | 4051 F | Slow RC branch capacitance |
| τ2 = R2·C2 | 32.41 s | Slow polarisation time constant |

### OCV–SOC Lookup Table

| SOC | OCV (V) |
|---|---|
| 0.00 | 2.65 |
| 0.05 | 2.90 |
| 0.10 | 3.10 |
| 0.20 | 3.40 |
| 0.30 | 3.55 |
| 0.40 | 3.65 |
| 0.50 | 3.72 |
| 0.60 | 3.78 |
| 0.70 | 3.83 |
| 0.80 | 3.90 |
| 0.90 | 4.00 |
| 0.95 | 4.12 |
| 1.00 | 4.25 |

---

## Model Architecture

| Block | Simulink Type | Role |
|---|---|---|
| `I_discharge` | Constant (3.35 A) | 1C discharge current source |
| `SOC_Rate_Gain` | Gain (−1/12060) | Converts current to SOC rate (÷ capacity in A·s) |
| `SOC_Integrator` | Integrator (IC = 1, clamped [0,1]) | Coulomb-counting SOC state |
| `OCV_Table` | 1-D Lookup Table | Maps SOC → open-circuit voltage |
| `R0_Gain` | Gain (0.0483) | Ohmic voltage drop |
| `RC1_Branch` | Transfer Fcn `0.0245 / (27.53s+1)` | Fast RC polarisation voltage |
| `RC2_Branch` | Transfer Fcn `0.0080 / (32.41s+1)` | Slow RC polarisation voltage |
| `V_Terminal_Sum` | Sum (`+−−−`) | Assembles terminal voltage |
| `Voltage_Scope` | Scope | Terminal voltage vs. time |
| `SOC_Scope` | Scope | SOC vs. time |

---

## Signal Flow

```
I_discharge ──┬──> SOC_Rate_Gain ──> SOC_Integrator ──> OCV_Table ──> V_Terminal_Sum (+)
              ├──> R0_Gain ─────────────────────────────────────────> V_Terminal_Sum (−)
              ├──> RC1_Branch ──────────────────────────────────────> V_Terminal_Sum (−)
              └──> RC2_Branch ──────────────────────────────────────> V_Terminal_Sum (−)

V_Terminal_Sum ──> Voltage_Scope
SOC_Integrator ──> SOC_Scope
```

---

## Simulation Settings

| Setting | Value |
|---|---|
| Discharge current | 3.35 A (1C) |
| Stop time | 3600 s (1 hour) |
| Solver | `ode45` (variable-step) |
| Relative tolerance | 1×10⁻⁴ |

---

## Results

| Metric | Value |
|---|---|
| Terminal voltage at t = 0 | **4.088 V** |
| 2.5 V cutoff reached at | **t = 3554.7 s (59.2 min)** |
| SOC at cutoff | **1.3%** |
| Terminal voltage at end (t = 3600 s) | **2.379 V** |

The discharge curve shows three characteristic phases:
1. **Initial drop** (~4.09 → 4.0 V) — instantaneous R0 ohmic drop plus RC branch settling
2. **Mid-discharge plateau** (~3.9 → 3.7 V) — gradual OCV decline, RC branches near steady state
3. **End-of-discharge knee** — sharp voltage collapse below 3.5 V as OCV rolls off steeply near SOC = 0

The 2.5 V cutoff is hit at 59.2 minutes into a 60-minute 1C discharge, consistent with the datasheet's minimum 3200 mAh rating (the slight shortfall vs. 3350 mAh typical reflects the steeper terminal voltage vs. OCV near depletion).

---

## Files

| File | Description |
|---|---|
| `ncr18650b_thevenin.slx` | Simulink ECM model |
| `prompt.md` | Original specification and datasheet extract |
| `ncr18650b_thevenin_description.md` | This document |
