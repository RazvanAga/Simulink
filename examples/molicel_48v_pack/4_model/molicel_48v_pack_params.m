%% molicel_48v_pack_params.m
% Parameter script for molicel_48v_pack.slx
% 48 V pack (13s4p), Molicel INR-21700-P45B — 2nd-order Thevenin ECM
%
% Source of truth: ../3_spec/spec.md (VALIDATED BY: Razvan Aga, 11.06.2026).
% Every value below cites its spec section. DRAFT — pending engineer validation.

%% Cell limits — spec §2
Cell_Capacity_Typ_Ah  = 4.5;    % §2 Typical capacity (DS)
Cell_V_Max            = 4.2;    % §2 Charge voltage max (DS)
Cell_V_Cutoff         = 2.5;    % §2 Discharge cutoff (DS)
Cell_I_Max_Cont_A     = 45;     % §2 Max continuous discharge (DS)
Temp_Discharge_Min_C  = -40;    % §2 Discharge temp window, lower (DS)
Temp_Discharge_Max_C  = 60;     % §2 Discharge temp window, upper (DS)

%% Cell ECM (2nd-order Thevenin) — spec §3
Cell_R0_Ohm = 7.0e-3;           % §3 R0 ohmic (DS, AC impedance)
Cell_R1_Ohm = 5.5e-3;           % §3 R1 fast branch (ASSUMED — spec §9.1)
Tau1_s      = 3;                % §3 tau1 fast (ASSUMED — spec §9.1)
Cell_R2_Ohm = 4.0e-3;           % §3 R2 slow branch (ASSUMED — spec §9.1)
Tau2_s      = 50;               % §3 tau2 slow (ASSUMED — spec §9.1)

% OCV(SOC) lookup table — spec §3 (TR p.7, 0.2C curve, graphical read ±30 mV)
OCV_SOC_Breakpoints = [0 0.02 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 0.95 1.00];
OCV_Cell_V          = [2.50 2.85 3.16 3.31 3.44 3.52 3.59 3.65 3.74 3.84 3.92 4.02 4.08 4.19];

%% Pack topology & derived parameters — spec §4
N_Series   = 13;                                        % §4 design choice
N_Parallel = 4;                                         % §4 design choice
Pack_Capacity_Ah  = N_Parallel * Cell_Capacity_Typ_Ah;  % §4 -> 18 Ah
Pack_R0_Ohm       = Cell_R0_Ohm * N_Series/N_Parallel;  % §4 -> 22.75 mOhm
Pack_R1_Ohm       = Cell_R1_Ohm * N_Series/N_Parallel;  % §4 -> 17.875 mOhm (spec rounds to 17.9)
Pack_R2_Ohm       = Cell_R2_Ohm * N_Series/N_Parallel;  % §4 -> 13.0 mOhm
Pack_V_Cutoff     = N_Series * Cell_V_Cutoff;           % §4 -> 32.5 V
Pack_V_Max        = N_Series * Cell_V_Max;              % §4 -> 54.6 V (spec §9.4 VDA320 note)
Pack_I_Max_Cont_A = N_Parallel * Cell_I_Max_Cont_A;     % §4 -> 180 A
SOC_Rate_Gain     = -1/(Pack_Capacity_Ah * 3600);       % §4 -> -1.5432e-5 1/(s*A)

%% Simulation scenario — spec §6
Load_Current_A = 18;            % §6 constant-current load (1C pack rate)
SOC_Initial    = 1.0;           % §6 initial SOC = 100%
Stop_Time_s    = 4000;          % §6 safety stop
T_Ambient_C    = 25;            % NOT IN SPEC — §6 omits ambient temperature.
                                % In-window value chosen so Temp_Flag = 0; no
                                % acceptance criterion depends on it. Flagged
                                % as spec defect in handover report.
