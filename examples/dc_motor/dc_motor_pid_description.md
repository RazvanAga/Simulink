# DC Motor Speed Control — PID Simulink Model

## Overview

A closed-loop speed control system for a DC motor, implemented in Simulink (`dc_motor_pid.slx`). A PID controller tracks a 1000 RPM step reference using feedback from the motor plant output.

---

## System Architecture

```
Speed_Reference (Step)
        |
        v
   Error_Sum (+/-)  <─────────────────────────┐
        |                                      |
        v                                      |
  PID_Controller                               |
        |                                      |
        v                                      |
  DC_Motor_Plant ──> Speed_Scope         (feedback)
        |                                      |
        └──────────────────────────────────────┘
```

---

## Blocks

| Block | Simulink Type | Role |
|---|---|---|
| `Speed_Reference` | Step | Target speed command (0 → 1000 RPM at t = 0) |
| `Error_Sum` | Sum (`+-`) | Computes tracking error: reference − feedback |
| `PID_Controller` | PID Controller | Generates control effort to minimize error |
| `DC_Motor_Plant` | Transfer Fcn | First-order motor model |
| `Speed_Scope` | Scope | Visualizes motor speed over time |
| `Speed_Out` | Out1 | Simulation output port for logged data |

---

## Plant Model

The DC motor is approximated as a first-order transfer function:

```
        K           0.5
G(s) = ─────── = ─────────
       τs + 1    0.1s + 1
```

| Parameter | Symbol | Value | Meaning |
|---|---|---|---|
| DC gain | K | 0.5 | Steady-state RPM per unit control input |
| Time constant | τ | 0.1 s | Motor mechanical response speed |

---

## PID Tuning

| Gain | Value | Effect |
|---|---|---|
| Proportional (P) | 5 | Fast initial response |
| Integral (I) | 50 | Eliminates steady-state error |
| Derivative (D) | 0.01 | Damping to prevent overshoot |
| Filter coefficient (N) | 100 | High-frequency noise rejection on D term |

---

## Simulation Settings

| Setting | Value |
|---|---|
| Stop time | 2 s |
| Solver | `ode45` (variable-step) |
| Relative tolerance | `1e-4` |

---

## Results

| Metric | Value |
|---|---|
| Final speed | **1000.00 RPM** |
| Peak overshoot | **0.0%** |
| Settle time (±2%) | **~0.171 s** |

The step response is smooth and monotonically rising — no oscillation, no overshoot. The motor reaches the 1000 RPM setpoint in approximately 170 ms and holds it flat for the remainder of the 2-second simulation.

---

## Files

| File | Description |
|---|---|
| `dc_motor_pid.slx` | Simulink model |
| `dc_motor_pid_description.md` | This document |
