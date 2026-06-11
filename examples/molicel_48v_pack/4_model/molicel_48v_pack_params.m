%% molicel_48v_pack_params.m
% Parameter definitions for molicel_48v_pack.slx
% Every value is traceable to spec.md (engineer-validated, signed 11.06.2026).
% DO NOT edit values here without updating spec.md first — spec is the source of truth.

%% Cell parameters — spec.md §2 (source: datasheet v1.2)
Q_cell_Ah      = 4.5;       % [Ah]  typical capacity
V_cell_nom     = 3.6;       % [V]   nominal voltage
V_cell_max     = 4.2;       % [V]   charge voltage limit
V_cell_cutoff  = 2.5;       % [V]   discharge cutoff
I_cell_max     = 45;        % [A]   max continuous discharge

%% ECM parameters — spec.md §3 (R0: datasheet; RC split: ASSUMED, anchored to 15 mOhm @10 s)
R0_cell   = 0.0070;         % [Ohm] ohmic resistance (AC impedance, DS)
R1_cell   = 0.0055;         % [Ohm] fast branch resistance (ASSUMED)
tau1      = 3;              % [s]   fast branch time constant (ASSUMED)
R2_cell   = 0.0040;         % [Ohm] slow branch resistance (ASSUMED)
tau2      = 50;             % [s]   slow branch time constant (ASSUMED)

% OCV(SOC) lookup — spec.md §3 (test report p.7, 0.2C curve, graphical read)
SOC_breakpoints = [0 0.02 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 0.95 1.00];
OCV_cell_table  = [2.50 2.85 3.16 3.31 3.44 3.52 3.59 3.65 3.74 3.84 3.92 4.02 4.08 4.19]; % [V]

%% Pack topology — spec.md §4 (13s4p, DERIVED)
N_series     = 13;
N_parallel   = 4;
Q_pack_Ah    = N_parallel * Q_cell_Ah;          % 18 [Ah]
V_pack_cutoff = N_series * V_cell_cutoff;       % 32.5 [V]
V_pack_max   = N_series * V_cell_max;           % 54.6 [V]
R0_pack      = R0_cell * N_series / N_parallel; % 22.75e-3 [Ohm]
R1_pack      = R1_cell * N_series / N_parallel; % 17.875e-3 [Ohm]
R2_pack      = R2_cell * N_series / N_parallel; % 13.0e-3 [Ohm]
I_pack_max   = N_parallel * I_cell_max;         % 180 [A]
SOC_rate_gain = -1 / (Q_pack_Ah * 3600);        % -1.5432e-5 [1/(s*A)]

%% Simulation scenario — spec.md §6
I_load_pack  = 18;          % [A] constant discharge, 1C pack rate
SOC_initial  = 1.0;         % [-] 100% SOC
t_stop       = 4000;        % [s] safety stop (UV cutoff expected ~3600 s)
T_ambient_C  = 23;          % [degC] scenario ambient (TR test conditions, 23 degC)

%% Protection window — spec.md §5 (discharge temp window, DS)
T_dis_min_C  = -40;         % [degC]
T_dis_max_C  = 60;          % [degC]
