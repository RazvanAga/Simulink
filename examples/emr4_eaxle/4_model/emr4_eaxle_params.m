% emr4_eaxle_params.m — parameters for emr4_eaxle.slx
% EMR4 eAxle (Base variant), quasi-static drivetrain model.
% Single source of truth: ../3_spec/spec.md (signed off: Razvan Aga, 11.06.2026).
% Every value below cites its spec table cell. Do NOT change a number here
% without changing the spec first — model generation is traceability-bound.

%% §3 Model parameters (Base variant, quasi-static drivetrain)
T_motor_max  = 255;            % Nm  — §3 T_motor_max (VMS p.9 reducer input limit)
P_peak       = 155e3;          % W   — §3 P_peak, 155 kW (VMS p.7 Fig.2; open item §9.1)
n_motor_max  = 16000;          % rpm — §3 w_max (VMS p.9–10)
w_motor_max  = n_motor_max * 2*pi/60;   % rad/s — §3 w_max conversion (= 1675.5 rad/s)
i_gear       = 11.64;          % –   — §3 i_gear (ASSUMED, selected from VMS p.9 range; §9.2)
eta_red      = 0.97;           % –   — §3 eta_red (ASSUMED, literature-typical; §9.3)
eta_em_inv   = 0.94;           % –   — §3 eta_em_inv (ASSUMED, literature-typical; §9.3)
V_dc_nom     = 400;            % V   — §3 V_dc_nom (ASSUMED; VMS title / p.11 window)
I_inv_rated  = 550;            % A   — §3 I_inv_rated, Base inverter (VMS p.8)
m_veh        = 2300;           % kg  — §3 m_veh (ASSUMED, mid of 1800–2800 kg; §9.4)
r_wheel      = 0.35;           % m   — §3 r_wheel (ASSUMED, typical C/D-segment EV; §9.4)

%% §6 Simulation scenario
T_req_step   = 300;            % Nm  — §6 torque request step (deliberately > T_motor_max)
t_stop       = 40;             % s   — §6 safety stop time
v_init       = 0;              % m/s — §6 initial condition (vehicle at rest)

%% Derived display/guard values (formulas per §4; implementation guards declared)
radps2rpm    = 60/(2*pi);      % rad/s → rpm conversion (unit change only)
v_top        = (w_motor_max / i_gear) * r_wheel;   % m/s — §4 top speed (= 50.4 m/s)
% Integrator physical guard (skill hard rule 4): lower bound 0 (no reverse in
% this scenario), upper bound 5 % above §4 top speed. The overspeed cut (§5)
% must engage before this saturation ever acts.
v_sat_upper  = 1.05 * v_top;   % m/s — guard only, NOT a spec value
% Divide-by-zero guard for the P/ω limiter branch at standstill (ω = 0):
% below w_eps the torque limit is T_motor_max anyway (P_peak/w_eps >> 255 Nm).
w_eps        = 1;              % rad/s — guard only, NOT a spec value
