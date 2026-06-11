%% TI_BQ76952_params.m
% Parameters for TI_BQ76952.slx — BQ76952 voltage protection state machine.
% Single source of truth: examples/TI_BQ76952/3_spec/spec.md
%   (signed off: Razvan Aga, 11.06.2026)
% Every value below is traceable to a spec table cell; the spec section is
% given in each comment. DRAFT — pending engineer validation.

%% Solver / simulation (spec section 6)
T_s       = 1e-3;  % [s] fixed-step discrete sample time           — spec sec. 6
t_sim_end = 4.0;   % [s] end of voltage profile                    — spec sec. 6

%% Application configuration, 14s NMC (spec section 3 — values tagged ASSUMED in spec)
num_cells    = 14;     % [-] number of series cells                — spec sec. 3
V_COV_Thresh = 4.25;   % [V] cell overvoltage threshold            — spec sec. 3
t_COV_Delay  = 0.330;  % [s] COV delay (100 hw counts x 3.3 ms)    — spec sec. 3
V_CUV_Thresh = 2.75;   % [V] cell undervoltage threshold           — spec sec. 3
t_CUV_Delay  = 0.330;  % [s] CUV delay (mapped symmetric to COV)   — spec sec. 3
V_COV_Hyst   = 0.100;  % [V] overvoltage recovery hysteresis       — spec sec. 3
V_CUV_Hyst   = 0.100;  % [V] CUV recovery hysteresis — NOT tabulated in spec
                       %     sec. 3; mirrored from V_COV_Hyst per sec. 5
                       %     "identical state machine logic". Reported as a
                       %     spec gap in the handover report.

%% Derived (spec section 4 + section 6)
% Spec sec. 4 gives the HARDWARE timer threshold: 330 ms / 3.3 ms = 100 ticks.
% The model chart ticks at T_s = 1 ms (spec sec. 6), so the equivalent
% threshold in chart ticks is t_COV_Delay / T_s = 330 — same 330 ms of
% physical time as the hardware's 100 x 3.3 ms.
N_COV_Delay_Ticks = round(t_COV_Delay / T_s);  % = 330 — DERIVED sec. 3 / sec. 6
N_CUV_Delay_Ticks = round(t_CUV_Delay / T_s);  % = 330 — DERIVED sec. 3 / sec. 6

%% Simulation scenario stimulus (spec section 6)
Cell_Base_V    = 3.7;  % [V] all cells steady                      — spec sec. 6
V_Cell5_Phase1 = 4.3;  % [V] cell #5 from t_Phase1 (trigger)       — spec sec. 6
V_Cell5_Phase2 = 4.2;  % [V] cell #5 from t_Phase2 (in hyst band)  — spec sec. 6
V_Cell5_Phase3 = 4.1;  % [V] cell #5 from t_Phase3 (full recovery) — spec sec. 6
t_Phase1 = 1.0;        % [s]                                       — spec sec. 6
t_Phase2 = 2.0;        % [s]                                       — spec sec. 6
t_Phase3 = 3.0;        % [s]                                       — spec sec. 6
Stim_Cell_Idx = 5;     % [-] cell #5 is the stimulus               — spec sec. 6

% Injection vector: routes the scalar stimulus onto cell #5 only.
Cell5_Select = zeros(num_cells, 1);
Cell5_Select(Stim_Cell_Idx) = 1;
