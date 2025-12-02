%% EREV Parameters - Optimized Shift Strategy
% =========================================================================
% Vehicle: Based on Hyundai/Kia EREV System Architecture
% Updates:
%   - Motor extended to 15,000 RPM (realistic for modern EV motors)
%   - Gear ratios optimized: 1st=12.0, 2nd=7.0
%   - 🆕 Shift points OPTIMIZED: 35/30 km/h (based on efficiency crossover)
% =========================================================================
% 변경 이력:
%   - 2024.11.11: 변속점 최적화 (50/35 → 35/30 km/h)
%   - 이유: 효율 역전 지점(34 km/h)에 맞춰 조정
% =========================================================================

%% Vehicle Selection Justification
% Santa Fe PHEV를 기본으로 선택한 이유:
% 1. 국내 제조사 (현대) 모델
% 2. 전륜/후륜 모터 분리 구조
% 3. 제원 데이터 공개
% 4. EREV 모드 시뮬레이션 가능한 구조

%% ===== VEHICLE SPECIFICATIONS (Santa Fe PHEV 2024 기반) =====
% Source: Hyundai Motor Company Official Specifications

% Vehicle Mass and Dimensions
M_veh = 2165;              % Vehicle curb weight [kg] (Santa Fe PHEV)
M_payload = 200;           % Typical payload [kg]
M_total = M_veh + M_payload;  % Total mass [kg]

% Vehicle Dimensions
L_wheelbase = 2.765;       % Wheelbase [m]
Lf = 1.383;               % Front axle to CG [m] (50% weight dist.)
Lr = 1.382;               % Rear axle to CG [m]
h = 0.65;                 % CG height [m] (estimated)
track_width = 1.68;       % Track width [m]

% Tire Specifications
tire_type = '235/55R20';  % Tire specification
r_tire = 0.369;           % Tire radius [m] - calculated from 235/55R20
% Calculation: (235*0.55*2 + 20*25.4)/2/1000 = 0.369m

%% ===== AERODYNAMICS & RESISTANCE =====
% Source: Hyundai Technical Data

Cd = 0.33;                % Drag coefficient (Santa Fe)
Af = 2.95;                % Frontal area [m^2] (W:1.9m × H:1.68m × 0.92)
rho = 1.225;              % Air density at sea level [kg/m^3]
f_roll = 0.008;           % Rolling resistance (low resistance tires)
g = 9.81;                 % Gravity [m/s^2]

% Environment
theta = 0;  % [deg] Road grade angle (0 = flat)

%% ===== BATTERY SPECIFICATIONS =====
% Based on Santa Fe PHEV Battery Pack (Modified for EREV)

% Battery Pack Specifications
Q_bat_kWh = 13.8;         % Battery capacity [kWh] (Santa Fe PHEV)
Q_bat_Ah = 38.3;          % Battery capacity [Ah] (360V system)
V_nominal = 360;          % Nominal voltage [V]
No_cell = 96;             % Number of cells in series

% Battery Chemistry: NCM (Nickel Cobalt Manganese)
battery_type = 'NCM622';  % LG Chem NCM battery

% SOC Operating Range (EREV optimized)
SOC_min = 0.15;           % Minimum SOC (protect battery)
SOC_max = 0.95;           % Maximum SOC (protect battery)
SOC_init = 0.5;           % Initial SOC
SOC_target_low = 0.3;     % Start charging
SOC_target_high = 0.7;    % Stop charging

% Internal Resistance Model (SOC & Temperature dependent)
R_int_base = 0.15;        % Base internal resistance [Ohm] at SOC=50%, 25°C

% SOC-dependent resistance multiplier
SOC_R_table = [0.0  0.1  0.2  0.3  0.4  0.5  0.6  0.7  0.8  0.9  1.0];
R_multiplier = [3.0  2.0  1.5  1.2  1.1  1.0  1.0  1.1  1.2  1.8  2.5];

% Open Circuit Voltage vs SOC (NCM battery characteristics)
VOC_SOC = [0    0.05  0.1   0.2   0.3   0.4   0.5   0.6   0.7   0.8   0.9   0.95  1.0];
VOC_cell = [3.0  3.35  3.50  3.60  3.65  3.70  3.75  3.82  3.90  3.95  4.00  4.10  4.20];
VOC_map = No_cell * VOC_cell;

% Battery Thermal Model
T_bat_init = 25;         % Initial battery temperature [°C]
C_bat_thermal = 100;      % Battery thermal capacity [J/K/kg]

% Memory block 초기값
Vt_init = 374.4;  % SOC_init에서의 전압 [V]

%% ===== MOTOR SPECIFICATIONS (Dual Motor) =====
% UPDATED: Extended to 15,000 RPM (realistic for modern EV motors)

%% Front Motor (Main Drive + Generator Mode)
% Type: Permanent Magnet Synchronous Motor (PMSM)
P_motor_F_max = 66.9;     % Maximum power [kW] (90 hp)
T_motor_F_max = 264;      % Maximum torque [Nm]
w_motor_F_max = 12000;    % Maximum speed [rpm]

% Front Motor Torque-Speed Curve (Extended)
w_motor_F_rpm = [0    500  1000  1500  2000  2500  3000  3500  4000  4500  5000  ...
                 5500  6000  6500  7000  7500  8000  8500  9000  9500  10000 10500 11000 11500 12000];
T_motor_F_curve = [264  264  264   264   264   250   230   210   195   180   168  ...
                   156  145   135   126   118   111   104    98    92    87    82    77    73    68];
% Power limit: P = T × w → Torque decreases at high speed

% Front Motor Efficiency Map
eff_spd_F_rpm = [0    1000  2000  3000  4000  5000  6000  7000  8000  9000  10000 11000 12000];
eff_trq_F = [0   26   53   79   106  132  158  185  211  238  264];
eff_map_F = [
    60   70   72   70   68   65   63   61   60   59   58   57   56;  % 0 Nm
    70   80   82   81   79   77   75   73   71   70   69   68   67;  % 26 Nm
    75   86   88   87   86   84   82   80   78   76   75   74   73;  % 53 Nm
    78   89   91   90   89   87   85   83   81   79   78   77   76;  % 79 Nm
    80   91   93   92   91   89   87   85   83   81   80   79   78;  % 106 Nm
    81   92   94   93   92   90   88   86   84   82   81   80   79;  % 132 Nm
    82   92   94   94   93   91   89   87   85   83   82   81   80;  % 158 Nm
    82   91   93   93   92   90   88   86   84   82   81   80   79;  % 185 Nm
    81   90   92   92   91   89   87   85   83   81   80   79   78;  % 211 Nm
    80   88   90   90   89   87   85   83   81   79   78   77   76;  % 238 Nm
    78   86   88   88   87   85   83   81   79   77   76   75   74;  % 264 Nm
];

% Front Motor Parameters
tau_m_F = 0.02;           % Motor time constant [s]
J_motor_F = 0.15;         % Motor inertia [kg⋅m²]

%% Rear Motor (Traction Motor) - UPDATED
% Type: Interior Permanent Magnet (IPM) Motor
P_motor_R_max = 91;       % Maximum power [kW] (122 hp)
T_motor_R_max = 304;      % Maximum torque [Nm]
w_motor_R_max = 15000;    % Maximum speed [rpm] - UPDATED from 7000!

% Rear Motor Torque-Speed Curve (Extended to 15,000 RPM)
w_motor_R_rpm = [0    500  1000  1500  2000  2500  3000  3500  4000  4500  5000  ...
                 5500  6000  6500  7000  7500  8000  8500  9000  9500  10000 10500 ...
                 11000 11500 12000 12500 13000 13500 14000 14500 15000];
T_motor_R_curve = [304  304  304   304   304   304   295   280   265   250   235  ...
                   220  205   192   180   169   159   150   141   133   126   119  ...
                   113  107   101    96    91    86    82    78    74];
% Torque decreases due to power limit: P_max = 91 kW

% Rear Motor Efficiency Map (Extended)
eff_spd_R_rpm = [0    1000  2000  3000  4000  5000  6000  7000  8000  9000  10000 11000 12000 13000 14000 15000];
eff_trq_R = [0   30   61   91   122  152  182  213  243  274  304];
eff_map_R = [
    60   70   72   70   68   65   63   61   60   59   58   57   56   55   54   53;  % 0 Nm
    70   80   82   81   79   77   75   73   71   70   69   68   67   66   65   64;  % 30 Nm
    75   86   88   87   86   84   82   80   78   76   75   74   73   72   71   70;  % 61 Nm
    78   89   91   90   89   87   85   83   81   79   78   77   76   75   74   73;  % 91 Nm
    80   91   93   92   91   89   87   85   83   81   80   79   78   77   76   75;  % 122 Nm
    81   92   94   93   92   90   88   86   84   82   81   80   79   78   77   76;  % 152 Nm
    82   92   94   94   93   91   89   87   85   83   82   81   80   79   78   77;  % 182 Nm
    82   91   93   93   92   90   88   86   84   82   81   80   79   78   77   76;  % 213 Nm
    81   90   92   92   91   89   87   85   83   81   80   79   78   77   76   75;  % 243 Nm
    80   88   90   90   89   87   85   83   81   79   78   77   76   75   74   73;  % 274 Nm
    78   86   88   88   87   85   83   81   79   77   76   75   74   73   72   71;  % 304 Nm
];

% Rear Motor Parameters
tau_m_R = 0.02;           % Motor time constant [s]
J_motor_R = 0.18;         % Motor inertia [kg⋅m²]

%% ===== ENGINE SPECIFICATIONS (Range Extender) =====
% Based on Hyundai 1.6L Turbo-GDI (Modified for EREV operation)

% Engine Basic Specifications
engine_type = '1.6L Turbo-GDI';
V_displacement = 1.598;    % Displacement [L]
N_cylinders = 4;          % Number of cylinders
compression_ratio = 10.5; % Compression ratio

% Engine Performance
P_engine_max = 132;       % Maximum power [kW] (180 hp)
T_engine_max = 265;       % Maximum torque [Nm]
w_engine_idle = 750;      % Idle speed [rpm]
w_engine_max = 6000;      % Maximum speed [rpm]

% Engine Operating Points for EREV Mode
eng_speed_rpm = [1000  1500  2000  2500  3000  3500  4000  4500  5000  5500  6000];
eng_torque_curve = [180   240   265   265   255   240   220   195   170   145   120];

% BSFC Map (Brake Specific Fuel Consumption) [g/kWh]
eng_speed_bsfc = [1000  1500  2000  2500  3000  3500  4000  4500  5000];
eng_torque_bsfc = [0  50  100  150  200  250];
bsfc_map = [
    450  400  350  340  350  380;  % 1000 rpm
    420  360  300  280  290  320;  % 1500 rpm
    400  330  275  255  265  295;  % 2000 rpm
    395  315  265  245  255  285;  % 2500 rpm
    395  315  265  245  255  285;  % 3000 rpm
    410  330  280  265  275  305;  % 3500 rpm
    430  350  300  285  295  325;  % 4000 rpm
    450  380  330  315  325  355;  % 4500 rpm
    480  410  360  345  355  385;  % 5000 rpm
];

% Engine Sweet Spot (최적 운전점)
eng_sweet_spot_speed = 2200; % [rpm]
eng_sweet_spot_torque = 180; % [Nm]
eng_sweet_spot_power = eng_sweet_spot_torque * eng_sweet_spot_speed * pi / 30000; % [kW]
eng_sweet_spot_bsfc = 238;   % [g/kWh] - Best efficiency point

% Engine Thermal Model
eng_coolant_temp_init = 25;  % Initial temperature [°C]
eng_warmup_time = 120;        % Warmup time to reach optimal temp [s]

%% ===== TRANSMISSION & DRIVELINE ===== 
% UPDATED: Optimized 2-Speed Transmission for 15,000 RPM Motor

% Gear Ratios - Optimized for realistic motor speed
G_final_F = 8.0;          % Front motor fixed gear ratio (Typical EV ratio)

% 2-Speed Rear Transmission (OPTIMIZED)
G_1st = 12.0;             % 1st gear ratio (Launch & Hill)
G_2nd = 7.0;              % 2nd gear ratio (Cruise)
G_final_R_diff = 3.5;     % Rear differential ratio

% Total gear ratios
G_final_R_1st = G_1st;    % Total 1st gear ratio: 12.0
G_final_R_2nd = G_2nd;    % Total 2nd gear ratio: 7.0

% 🆕 Shift Schedule Parameters - OPTIMIZED
V_upshift_kph = 35;       % Upshift speed [km/h] - OPTIMIZED! (was 50)
V_downshift_kph = 30;     % Downshift speed [km/h] - OPTIMIZED! (was 35)
shift_duration = 0.3;     % Shift time [s]

% Driveline Efficiency
eff_transmission = 0.97;  % Transmission efficiency
eff_differential = 0.98;  % Differential efficiency
eff_driveline = eff_transmission * eff_differential;

%% ===== REGENERATIVE BRAKING SYSTEM =====
% Based on Hyundai-Kia i-Pedal System

% Regenerative Braking Limits
regen_torque_max_F = T_motor_F_max * 0.8;  % 80% of max motor torque
regen_torque_max_R = T_motor_R_max * 0.8;

% Speed-dependent Regen Limits
v_regen_min = 8;          % Minimum speed for regen [km/h]
v_regen_full = 15;        % Full regen available [km/h]

% Regen Efficiency
eff_regen = 0.85;         % Regenerative braking efficiency

% Brake Blending
brake_regen_ratio_max = 0.7;  % Maximum regen/total brake ratio

%% ===== CONTROL PARAMETERS =====
% VCU Control Strategy Parameters

% SOC Management
SOC_charge_start = 0.30;  % Start engine charging
SOC_charge_stop = 0.40;   % Stop engine charging
SOC_ev_min = 0.30;        % Minimum SOC for EV mode
SOC_power_limit = 0.20;   % Start power limitation

% Mode Transition
mode_transition_delay = 0.5;  % Delay for mode changes [s]
mode_hysteresis = 0.05;       % SOC hysteresis band

% Torque Distribution
torque_split_F_4wd = 0.4;     % Front torque in 4WD mode
torque_split_R_4wd = 0.6;     % Rear torque in 4WD mode

% Driver Demand Interpretation
driver_aggression_threshold = 0.7;  % Aggressive driving threshold

%% ===== VCU CONTROL PARAMETERS =====  
T_wheel_brake_max = 5000;
T_wheel_prop_max_1st = T_motor_R_max * G_final_R_1st;
T_wheel_prop_max_2nd = T_motor_R_max * G_final_R_2nd;

Ap_4WD_threshold = 0.5;
V_upshift = V_upshift_kph;
V_downshift = V_downshift_kph;
regen_min_speed = v_regen_min;
regen_full_speed = v_regen_full;
regen_max_SOC = 0.9;
regen_torque_max_ratio = 0.8;
SOC_gen_start = SOC_charge_start;
SOC_gen_stop = SOC_charge_stop;
torque_split_F = torque_split_F_4wd;
torque_split_R = torque_split_R_4wd;

%% ===== AUXILIARY SYSTEMS =====
% Power consumption of auxiliary systems

P_aux_base = 0.5;         % Base auxiliary power [kW]
P_hvac = 2.0;            % HVAC power consumption [kW]
P_lights = 0.2;          % Lights power [kW]
P_infotainment = 0.1;    % Infotainment system [kW]

%% ===== SIMULATION PARAMETERS =====

Ts = 0.01;               % Simulation time step [s]
T_sim = 3600;            % Total simulation time [s] (1 hour)

% Initial Conditions
V_init = 0;              % Initial velocity [km/h]
Gear_init = 1;           % Initial gear
Mode_init = 1;           % Initial mode (0: EV, 1: 4WD)

%% ===== DRIVING CYCLES =====
% Standard test cycles

cycle_WLTC = 'WLTC_Class3';      % WLTC Class 3 for this vehicle weight
cycle_FTP75 = 'FTP75';           % US Federal Test Procedure
cycle_NEDC = 'NEDC';             % New European Driving Cycle
cycle_HWFET = 'HWFET';           % Highway Fuel Economy Test
cycle_Korea = 'K_CITY';          % Korean city driving cycle

%% ===== VALIDATION & REFERENCE DATA =====
% Target performance metrics (based on similar vehicles)

% Performance Targets
target_accel_0_100 = 8.5;        % 0-100 km/h time [s]
target_top_speed = 180;          % Top speed [km/h]
target_ev_range = 50;            % EV-only range [km]
target_total_range = 600;        % Total range [km]
target_fuel_economy = 20;        % Combined fuel economy [km/L]

% Reference Vehicle Performance (Santa Fe PHEV)
ref_fuel_economy_city = 18.7;    % City fuel economy [km/L]
ref_fuel_economy_hwy = 17.8;     % Highway fuel economy [km/L]
ref_ev_range = 45;               % EV range [km]
ref_co2_emission = 39;           % CO2 emission [g/km]

%% ===== PERFORMANCE VERIFICATION =====
% Check motor speed limits at maximum vehicle speed

fprintf('\n');
fprintf('=========================================\n');
fprintf('   EREV MODEL - OPTIMIZED SHIFT POINTS  \n');
fprintf('=========================================\n');
fprintf('Vehicle: Hyundai Santa Fe PHEV Based\n');
fprintf('Battery: %.1f kWh NCM Pack\n', Q_bat_kWh);
fprintf('Motors: Front %.0fkW, Rear %.0fkW\n', P_motor_F_max, P_motor_R_max);
fprintf('Engine: %.1fL Turbo-GDI (%.0fkW)\n', V_displacement, P_engine_max);
fprintf('Transmission: 2-Speed Rear (%.1f/%.1f)\n', G_final_R_1st, G_final_R_2nd);
fprintf('-----------------------------------------\n');
fprintf('🆕 KEY OPTIMIZATION:\n');
fprintf('✓ Shift points optimized to 35/30 km/h\n');
fprintf('  (Based on efficiency crossover at 34 km/h)\n');
fprintf('✓ Expected: 2-speed > 1st fixed > 2nd fixed\n');
fprintf('-----------------------------------------\n');
fprintf('Performance Check:\n');

% Calculate motor RPM at key speeds
V_test = [30 35 40 50 60 80 100];
for v = V_test
    w_wheel = v / (3.6 * r_tire);  % rad/s
    rpm_1st = w_wheel * G_1st * 60 / (2*pi);
    rpm_2nd = w_wheel * G_2nd * 60 / (2*pi);
    
    fprintf('  @ %.0f km/h: 1st=%.0f rpm, 2nd=%.0f rpm', v, rpm_1st, rpm_2nd);
    
    if v < V_upshift_kph
        fprintf(' [Using 1st]');
    else
        fprintf(' [Using 2nd]');
    end
    
    if rpm_1st > w_motor_R_max
        fprintf(' ⚠️ 1st OVERSPEED\n');
    elseif rpm_2nd > w_motor_R_max
        fprintf(' ⚠️ 2nd OVERSPEED\n');
    else
        fprintf(' ✓\n');
    end
end

fprintf('-----------------------------------------\n');
fprintf('Shift Strategy:\n');
fprintf('  Upshift point:   %.0f km/h ⬆️\n', V_upshift_kph);
fprintf('  Downshift point: %.0f km/h ⬇️\n', V_downshift_kph);
fprintf('  Hysteresis:      %.0f km/h\n', V_upshift_kph - V_downshift_kph);
fprintf('-----------------------------------------\n');
fprintf('Efficiency Analysis:\n');

% 주요 속도에서 효율 체크
test_speeds_eff = [20, 30, 35, 40, 50, 60, 80];
for v = test_speeds_eff
    w_wheel = v / (3.6 * r_tire);
    rpm_1st = w_wheel * G_final_R_1st * 60 / (2*pi);
    rpm_2nd = w_wheel * G_final_R_2nd * 60 / (2*pi);
    
    [~, idx_1st] = min(abs(w_motor_R_rpm - rpm_1st));
    [~, idx_2nd] = min(abs(w_motor_R_rpm - rpm_2nd));
    
    eff_1st = mean(eff_map_R(:, idx_1st));
    eff_2nd = mean(eff_map_R(:, idx_2nd));
    
    if v < V_upshift_kph
        used = '1st';
        used_eff = eff_1st;
    else
        used = '2nd';
        used_eff = eff_2nd;
    end
    
    if eff_1st > eff_2nd
        best = '1st';
    else
        best = '2nd';
    end
    
    if strcmp(used, best)
        marker = '✓';
    else
        marker = '⚠️';
    end
    
    fprintf('  @ %.0f km/h: Using %s (eff=%.1f%%) %s\n', v, used, used_eff, marker);
end

fprintf('=========================================\n\n');

%% ===== SAVE CONFIGURATION =====
save('EREV_Config_Optimized.mat');
fprintf('✓ Configuration saved to EREV_Config_Optimized.mat\n\n');