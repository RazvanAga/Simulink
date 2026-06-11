# Pipeline Config — emr4_eaxle

> Product-specific parameterization for the generic skills in `/skills`.
> This file is the ONLY place where this example's product, topology, and file names
> are defined — the skills stay product-agnostic.

## Product

- **Unit:** Vitesco Technologies EMR4 electric axle drive (Electronics Motor Reducer,
  4th generation) — integrated PSM motor + EPF4 inverter + 2-stage reducer, 400 V class
- **Variant modeled:** **Base** configuration (mid platform: ~155 kW / ~2,750 Nm axle,
  550 A inverter, reducer family < 3,000 Nm)

## Target model

- **Family:** quasi-static longitudinal eAxle drivetrain model — torque request →
  motor torque/power/speed limiter → fixed-ratio reducer → wheel force → single-mass
  vehicle longitudinal dynamics; DC-link power/current via average efficiency factors.
  **No** dq motor model, no inverter switching, no efficiency maps (public docs carry
  envelope data only — see spec).
- **Protection subset to model:** motor overspeed cut (16,000 rpm), peak power limit,
  motor torque limit, DC-link current vs inverter rating flag.
  **Out of scope (state explicitly):** thermal derating, regenerative braking, aero/rolling
  road loads, efficiency maps, FOC/PWM behavior, NVH, EMC, parking brake, torque
  vectoring/differential split, aging.

## Output file names

| Artifact | Name |
|---|---|
| Model | `4_model/emr4_eaxle.slx` |
| Parameters | `4_model/emr4_eaxle_params.m` |
| Docs | `5_docs/emr4_eaxle_architecture.md` |

## Fixed architecture (Stage 2 must not improvise)

```
Drive path:   T_req → T_Limiter (min of: T_motor_max, P_peak/ω_m, 0 if overspeed-latched)
                    → Gear_Gain (i × η_red) → T_axle → Wheel_Force_Gain (1/r_wheel)
                    → Accel_Gain (1/m_veh) → v_Integrator → v_veh
Feedback:     v_veh → Axle_Speed_Gain (1/r_wheel) → Motor_Speed_Gain (×i) → ω_m
Electrical:   T_lim × ω_m → P_mech → P_DC_Gain (1/η_em_inv) → P_dc → I_DC_Gain (1/V_dc_nom) → I_dc
Protection:   ω_m ≥ ω_max → Overspeed_Latch → torque cut + flag + sim stop
              I_dc > I_inverter_rated → OC_Flag
Outputs:      v_veh, n_motor (rpm), T_axle, P_dc, I_dc, Overspeed_Flag, OC_Flag
              → Outports + Scopes
```

## Status of this run

Stage 1 (spec extraction) executed; `3_spec/spec.md` awaiting engineer sign-off.
Stages 2–3 not started.
