# emr4_eaxle — Architecture & Block Reference

> **Status: DRAFT — generated documentation, pending engineer validation.**
> Source of truth: `spec.md` (engineer-signed 11.06.2026). Every parameter cited below
> is traceable to a spec table cell; provenance tags (`VMS`, `SHF`, `ASSUMED`, `DERIVED`)
> are inherited from the spec.

---

## 1. Model Purpose

The model (`emr4_eaxle.slx`) simulates the **quasi-static longitudinal behaviour of the
EMR4 electric axle drive, Base variant** (~155 kW / ~2,750 Nm, 550 A inverter) driving a
single-mass vehicle in a full-throttle launch. It implements the torque/power envelope,
fixed-ratio reducer, longitudinal dynamics, DC-link power draw, and the protection
subset defined in the signed spec — no dq motor model, no switching, no efficiency maps
(the public sources carry envelope data only).

The model answers three questions at every point in time:

- What **axle torque and vehicle speed** does the Base envelope deliver?
- What **DC-link power and current** does that operating point draw?
- Are any **protection limits** (motor overspeed, inverter current) violated?

## 2. Physical Basis

An e-axle at full throttle is governed by whichever of its capability limits binds at
the current speed:

| Mechanism | Physical cause | Binds when | Modeled by |
|---|---|---|---|
| Torque limit | Motor/reducer mechanical capability (255 Nm input) | ω low (launch) | `T_Motor_Max_Const` → `Torque_Limiter` |
| Power limit | Electrical capability, T = P/ω | ω > base speed | `P_Peak_Const`, `Power_Torque_Limit` |
| Gear multiplication & loss | 2-stage reducer + differential | always | `Gear_Gain` (i·η) |
| Vehicle inertia | Newton: m·dv/dt = F_wheel | always | `Wheel_Force_Gain` → `Accel_Gain` → `v_Integrator` |
| Overspeed protection | Motor mechanical limit 16,000 rpm | end of run | `Overspeed_Compare` → latch → cut/stop |
| DC-link draw | P_dc = P_mech/η, I_dc = P_dc/V_dc | always | `P_DC_Gain`, `I_DC_Gain` |

Topology assumptions (spec §4): single lumped mass, no aero/rolling road load, no
regenerative braking, perfect torque-split symmetry (differential not modeled),
constant average efficiencies — stated first-order limitations.

## 3. System Architecture

### 3.1 Signal regions

```
Drive path:
  T_Req_Step(300 Nm) ─→ Torque_Limiter [min(T_req, 255, P/ω)] ─→ Overspeed_Cut_Switch
    ─→ Gear_Gain(i·η) ─→ T_axle ─→ Wheel_Force_Gain(1/r) ─→ Accel_Gain(1/m)
    ─→ v_Integrator ─→ v_veh

Feedback (speed):
  v_veh ─→ Axle_Speed_Gain(1/r) ─→ Motor_Speed_Gain(×i) ─→ ω_motor [rad/s]
  ω_motor ─→ Motor_RPM_Gain ─→ n_motor [rpm]

Electrical:
  T_lim × ω_motor ─→ P_Mech_Product ─→ P_DC_Gain(1/η_em_inv) ─→ P_dc
    ─→ I_DC_Gain(1/V_dc) ─→ I_dc

Protection (monitors + actuation):
  ω_motor ─→ Overspeed_Compare(≥ ω_max) ─→ Overspeed_Latch_Or ⇄ Overspeed_Latch_Memory
    ─→ Overspeed_Cut_Switch (torque → 0) + Overspeed_Stop + Overspeed_Flag
  I_dc ─→ OC_Compare(> 550 A) ─→ OC_Flag
```

### 3.2 Governing equation, with measured contributions

```
m·dv/dt = T_axle / r_wheel ,   T_axle = min(T_req, T_motor_max, P_peak/ω_m) · i_gear · η_red
```

Two phases in the actual run: **torque-limited** launch at a = 3.577 m/s² (measured;
DERIVED prediction 3.58) with T_axle = 2,879 Nm, until base speed v ≈ 18.3 m/s
(65.8 km/h) at t ≈ 5.1 s; then **power-limited** at P_mech = 155.0 kW, torque falling
as 1/ω down to 1,044.5 Nm, until the overspeed cut at t = 21.97 s and v = 50.38 m/s
(181.4 km/h).

### 3.3 Storage elements

- `v_Integrator` — the single continuous state. No exponential settle (quasi-static
  model, no road load): speed rises monotonically until the cut, then stays constant
  because torque is latched to zero and nothing decelerates the mass.
- `Overspeed_Latch_Memory` — one discrete state; with `Overspeed_Latch_Or` it forms the
  latch that holds the cut once tripped (standard OR + Memory idiom, one-step delay).

## 4. Block-by-Block Reference

### Drive path

**`T_Req_Step` — Step.** 0 → `T_req_step` = 300 Nm at t = 0 (spec §6). Deliberately
**above** the 255 Nm motor limit so the run exercises the torque limiter from the first
step. To change the maneuver, replace with Signal Editor or From Workspace.

**`T_Motor_Max_Const` — Constant.** `T_motor_max` = 255 Nm (spec §3, `VMS` p. 9 —
reducer input limit; Base motor sized to it).

**`P_Peak_Const` — Constant.** `P_peak` = 155 kW (spec §3, `VMS` p. 7 Fig. 2 — ⚠ open
item §9.1: body text says 135/165 kW; engineer ruling pending).

**`W_Eps_Const` — Constant / `Motor_Speed_Guard` — MinMax (max).** Floor the speed used
in the P/ω division at `w_eps` = 1 rad/s. **Guard only, NOT a spec value** — at
standstill P/ω would divide by zero; below 1 rad/s the torque limit binds anyway
(155 kW/1 rad/s ≫ 255 Nm), so the guard never affects the physics.

**`Power_Torque_Limit` — Product (÷).** `P_peak` / ω_guarded — the available torque on
the constant-power hyperbola. Crosses below 255 Nm at base speed (ω = 608 rad/s,
5,804 rpm), where the model hands over from torque-limited to power-limited.

**`Torque_Limiter` — MinMax (min, 3 inputs).** min(T_req, 255, P/ω) — the envelope in
one block. Output `T_lim` is the motor shaft torque before the protection cut.

**`Zero_Torque_Const` — Constant (0) / `Overspeed_Cut_Switch` — Switch.** If the
overspeed latch is set, route 0 Nm instead of `T_lim` (spec §5: torque cut to 0,
latched). Deviation from the config sketch, by design: the sketch folded the cut into
the limiter's min(); the built model implements it as a separate Switch so the cut is
its own observable action. Structurally equivalent.

**`Gear_Gain` — Gain.** `i_gear`·`eta_red` = 11.64 × 0.97 = 11.29 (spec §3 — both
**ASSUMED**: ratio selected from the documented 9.3–11.64 range, §9.2; efficiency
literature-typical, §9.3). Motor torque → axle torque: 255 → 2,879 Nm.

**`Wheel_Force_Gain` — Gain.** 1/`r_wheel` = 1/0.35 (spec §3 — **ASSUMED**, typical
C/D-segment tire, §9.4). Axle torque → traction force: 2,879 Nm → 8,226 N.

**`Accel_Gain` — Gain.** 1/`m_veh` = 1/2,300 (spec §3 — **ASSUMED**, mid of the
documented 1,800–2,800 kg class range, §9.4). Force → acceleration: peak 3.58 m/s².

**`v_Integrator` — Integrator.** IC = `v_init` = 0 (spec §6); output limited to
[0, `v_sat_upper` = 52.90 m/s]. **Both saturation bounds are guards, NOT spec values**
(skill hard rule 4): lower 0 = no reverse in this scenario; upper = 1.05 × derived top
speed. The overspeed cut (50.38 m/s) engages before the upper guard ever acts — verified
in the run.

### Feedback (speed) path

**`Axle_Speed_Gain` — Gain.** 1/`r_wheel` — vehicle speed → wheel/axle angular speed
[rad/s]. Same numeric value as `Wheel_Force_Gain` but a different physical conversion;
kept separate so each gain carries its own spec reference.

**`Motor_Speed_Gain` — Gain.** `i_gear` = 11.64 — axle speed → motor speed ω_m [rad/s].
Closes the algebraic feedback that makes the P/ω limiter and the protection live.

**`Motor_RPM_Gain` — Gain.** `radps2rpm` = 60/2π — unit conversion only, for the rpm
outport/scope (spec §6 asks for n_motor in rpm). No physics.

### Electrical path

**`P_Mech_Product` — Product.** `T_lim` × ω_m = mechanical power. Measured plateau:
155.00 kW (AC3).

**`P_DC_Gain` — Gain.** 1/`eta_em_inv` = 1/0.94 (spec §3 — **ASSUMED**,
literature-typical, §9.3). DC-link power; measured max 164.9 kW — the DC side sees
P_mech/η, deliberately above the mechanical peak.

**`I_DC_Gain` — Gain.** 1/`V_dc_nom` = 1/400 (spec §3 — **ASSUMED**; platform titled
400 V, inside the documented 210–470 V window). Measured max I_dc = 412.2 A, matching
the spec's DERIVED 412 A and well under the 550 A Base inverter rating.

### Protection subset (spec §5)

**`Overspeed_Compare` — Compare To Constant (≥ `w_motor_max` = 1,675.5 rad/s).**
Trips at the documented 16,000 rpm motor limit (`VMS` p. 9–10). Input is ω in rad/s —
the comparison constant is the converted spec value, not the rpm figure.

**`Overspeed_Latch_Or` — Logic (OR) / `Overspeed_Latch_Memory` — Memory.** Latch: once
the compare trips, the OR holds itself through the Memory feedback for the rest of the
run (spec §5: latched cut). Memory introduces a one-step delay — the standard idiom.

**`Overspeed_Stop` — Stop Simulation.** Ends the run when the latch sets — the
model-level equivalent of the drive shutting down. This is why the simulation ends at
21.97 s rather than the 40 s safety stop.

**`OC_Compare` — Compare To Constant (> `I_inv_rated` = 550 A).** DC overcurrent flag
(`VMS` p. 8, Base inverter). Per spec AC6 it must never assert in this scenario —
measured max 412.2 A, flag 0 throughout. Becomes meaningful with other scenarios or
parameter sets (e.g. the held-back Enhanced variant).

### Instrumentation

**`Mech_Scope` — Scope (3 in).** v_veh, n_motor [rpm], T_axle — the mechanical headline
traces. **`Elec_Scope` — Scope (2 in).** P_dc, I_dc. **`Flags_Scope` — Scope (2 in).**
Overspeed latch, OC flag.

**Outports 1–7.** `v_veh`, `n_motor`, `T_axle`, `P_dc`, `I_dc`, `Overspeed_Flag`,
`OC_Flag` → `out.yout{1..7}` for post-processing and test assertions. Note the order:
the two flags are ports 6 and 7 — verify with `get_param(...,'Port')` before scripting
against them.

## 5. Signal Summary

| Signal | Source | Destination(s) | Units | Value/Range in scenario (measured) |
|---|---|---|---|---|
| T_req | `T_Req_Step` | `Torque_Limiter` | Nm | 0 → 300 (step at t=0) |
| T_avail,P | `Power_Torque_Limit` | `Torque_Limiter` | Nm | ≫255 → 92.5 (at ω_max) |
| T_lim | `Overspeed_Cut_Switch` | `Gear_Gain`, `P_Mech_Product` | Nm | 255 → 92.5 → 0 (post-cut) |
| T_axle | `Gear_Gain` | outport, scope, `Wheel_Force_Gain` | Nm | 2,879.2 → 1,044.5 → 0 |
| F_wheel | `Wheel_Force_Gain` | `Accel_Gain` | N | 8,226 → 2,984 → 0 |
| v_veh | `v_Integrator` | outport, scope, `Axle_Speed_Gain` | m/s | 0 → 50.38, constant after cut |
| ω_motor | `Motor_Speed_Gain` | limiter ÷, compare, `P_Mech_Product`, rpm gain | rad/s | 0 → 1,675.5 |
| n_motor | `Motor_RPM_Gain` | outport, scope | rpm | 0 → 16,000 |
| P_dc | `P_DC_Gain` | outport, scope, `I_DC_Gain` | kW | 0 → 164.9 |
| I_dc | `I_DC_Gain` | outport, scope, `OC_Compare` | A | 0 → 412.2 |
| Overspeed_Latched | `Overspeed_Latch_Or` | switch, stop, memory, outport, scope | bool | 0; 1 at t = 21.97 s |
| OC_Flag | `OC_Compare` | outport, scope | bool | 0 throughout |

## 6. Simulation Results (scenario spec §6 — all acceptance criteria PASS)

Measured from an actual run (variable-step auto solver, stop on overspeed cut at
t = 21.97 s; 0–100 km/h time interpolated between logged samples).

| Metric | Measured | Acceptance criterion |
|---|---|---|
| Axle torque peak | 2,879.2 Nm | AC1: 2,820–2,940 Nm, never > 3,000 ✅ |
| Motor speed max | 16,000.0 rpm | AC2: ≤ 16,160 rpm ✅ |
| Mech. power plateau | 155.00 kW | AC3: 152–158 kW ✅ |
| Time 0 → 100 km/h | 8.46 s | AC4: 7.5–9.5 s ✅ |
| Overspeed cut at | 21.97 s, terminal 50.38 m/s (181.4 km/h) | AC5: 19–25 s; 50.4 m/s ± 2 % ✅ |
| DC current max | 412.2 A, OC flag 0 throughout | AC6: ≤ 550 A, flag never asserts ✅ |
| Speed monotonicity | strictly increasing to cut, constant after | AC7 ✅ |
| Launch acceleration | 3.577 m/s² | (cross-check vs DERIVED 3.58) ✅ |

## 7. Known Limitations & Pending Validation

- **Base variant power figure is contested in the source** — `VMS` Fig. 2 says 155 kW,
  the body text 135/165 kW. The spec uses Fig. 2; the engineer ruling is pending
  (spec §9.1). A switch to 165 kW shifts AC3/AC4/AC5.
- **`i_gear` = 11.64 is a selection** from the documented range, not a documented Base
  value (spec §9.2) — top speed and axle torque scale with it directly.
- **Efficiencies, vehicle mass, wheel radius are ASSUMED** (spec §9.3–9.4) — the public
  documents contain no absolute efficiency data and no reference vehicle.
- No road loads, no thermal derating, no regenerative braking — quasi-static envelope
  only (spec §5 out-of-scope list).
- **Independent validation pending (spec §8):** re-parameterize to the held-back
  **Entry** (80 kW / 1,700 Nm / 290 A) and **Enhanced** (230 kW / 4,000 Nm / 820 A)
  variants — parameter changes only, no structural edits — and check the envelope
  bounds. The model has never seen these numbers; this is the engineer's step.
- Document vintage: sources describe the 2021 platform status, independently confirmed
  by the 2025 Schaeffler page at envelope level (spec §9.6).

---

*Documentation format: generic harness template v1. A team-specific documentation
template would be encoded as a skill and produce this report in the team's own format.*
