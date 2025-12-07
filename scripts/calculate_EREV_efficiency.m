%% EREV_Final_Test_Complete.m
% EREV 연비 테스트 (완전 수정판)

clear; clc; close all;

fprintf('========================================\n');
fprintf('   EREV 연비 테스트\n');
fprintf('========================================\n\n');

%% 1. 파라미터 로드
run('EREV_RL_Parameters.m');

%% 2. 모델 선택
fprintf('테스트 선택:\n');
fprintf('1. Rule-based (EREV_1_Model)\n');
fprintf('2. RL Agent (EREV_1_Model_RL)\n');
choice = input('선택 (1 or 2): ');

if choice == 1
    modelName = 'EREV_1_Model';
    testName = 'Rule-based';
    is_RL = false;
    fprintf('\n✅ %s\n', testName);
else
    modelName = 'EREV_1_Model_RL';
    is_RL = true;
    
    [file, path] = uigetfile('*.mat', 'Agent 선택');
    if file == 0
        error('Agent를 선택하지 않았습니다.');
    end
    load(fullfile(path, file));
    testName = file;
    fprintf('\n✅ %s\n', testName);
end

%% 3. 시뮬레이션
fprintf('\n🚗 시뮬레이션 실행 (1369초)...\n');
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

tic;
simOut = sim(modelName, 'StopTime', '1369');
sim_time = toc;
fprintf('✅ 완료 (%.1f초)\n\n', sim_time);

%% 4. 데이터 추출
SOC_data = simOut.SOC.Data;
SOC_time = simOut.SOC.Time;
P_bat_data = simOut.P_bat_W.Data;
P_bat_time = simOut.P_bat_W.Time;
vel_data = simOut.vel_kph.Data;
eff_motor_data = simOut.eff_motor_R.Data;

% 기어 데이터 (모델에 따라 다름)
if is_RL
    % RL: Gear_R 사용 (실제 적용된 기어)
    Gear_data = simOut.Gear_R.Data;
    % RL Action도 함께 분석
    RL_action = simOut.RL_action_log.Data;
else
    % Rule-based: Gear_Actual 사용
    Gear_data = simOut.Gear_Actual.Data;
end

%% 5. 연비 계산
distance_km = 11.99;
battery_kWh = Q_bat_kWh;

SOC_initial = SOC_data(1);
SOC_final = SOC_data(end);
SOC_consumed = SOC_initial - SOC_final;

energy_kWh = SOC_consumed * battery_kWh;
efficiency = distance_km / energy_kWh;

dt = P_bat_time(2) - P_bat_time(1);
gear_changes = sum(abs(diff(Gear_data)));
gear1_pct = sum(Gear_data == 1) / length(Gear_data) * 100;
gear2_pct = sum(Gear_data == 2) / length(Gear_data) * 100;

%% 6. 결과 출력
fprintf('========================================\n');
fprintf('   최종 결과\n');
fprintf('========================================\n');
fprintf('제어:           %s\n', testName);
fprintf('주행 거리:      %.2f km\n', distance_km);
fprintf('시뮬레이션:     %.1f초 (실제 %.1f초)\n', SOC_time(end), sim_time);
fprintf('\n');
fprintf('--- 배터리 ---\n');
fprintf('초기 SOC:       %.2f%%\n', SOC_initial * 100);
fprintf('최종 SOC:       %.2f%%\n', SOC_final * 100);
fprintf('소모:           %.2f%%\n', SOC_consumed * 100);
fprintf('전력 소비:      %.4f kWh\n', energy_kWh);
fprintf('\n');
fprintf('--- 성능 ---\n');
fprintf('📊 전비:        %.2f km/kWh\n', efficiency);
fprintf('평균 속도:      %.2f km/h\n', mean(vel_data));
fprintf('변속 횟수:      %d회\n', gear_changes);
fprintf('1단 사용:       %.1f%%\n', gear1_pct);
fprintf('2단 사용:       %.1f%%\n', gear2_pct);
fprintf('평균 효율:      %.2f%%\n', mean(eff_motor_data) * 100);

if is_RL
    action_changes = sum(abs(diff(RL_action)));
    action1_pct = sum(RL_action == 1) / length(RL_action) * 100;
    action2_pct = sum(RL_action == 2) / length(RL_action) * 100;
    
    fprintf('\n--- RL Agent 결정 ---\n');
    fprintf('Action 변화:    %d회\n', action_changes);
    fprintf('1단 선택:       %.1f%%\n', action1_pct);
    fprintf('2단 선택:       %.1f%%\n', action2_pct);
end

fprintf('========================================\n\n');

%% 7. 비교 표시
fprintf('📌 참고:\n');
fprintf('   Rule-based: 17.02 km/kWh, 변속 42회\n');
if is_RL
    fprintf('   현재 RL:    %.2f km/kWh, 변속 %d회\n', efficiency, gear_changes);
    
    improvement = (efficiency / 17.02 - 1) * 100;
    if improvement > 0
        fprintf('   ✅ RL이 %.1f%% 더 효율적!\n', improvement);
    else
        fprintf('   ❌ RL이 %.1f%% 덜 효율적\n', -improvement);
    end
    
    gear_reduction = (1 - gear_changes / 42) * 100;
    if gear_reduction > 0
        fprintf('   ✅ 변속 횟수 %.1f%% 감소\n', gear_reduction);
    else
        fprintf('   ⚠️  변속 횟수 %.1f배 증가\n', gear_changes / 42);
    end
end

%% 8. 결과 저장
result.name = testName;
result.is_RL = is_RL;
result.distance_km = distance_km;
result.energy_kWh = energy_kWh;
result.efficiency_kmkWh = efficiency;
result.SOC_consumed = SOC_consumed;
result.gear_changes = gear_changes;
result.gear1_pct = gear1_pct;
result.gear2_pct = gear2_pct;
result.avg_speed = mean(vel_data);
result.avg_eff = mean(eff_motor_data);

if is_RL
    result.action_changes = action_changes;
    result.action1_pct = action1_pct;
    result.action2_pct = action2_pct;
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('Result_%s.mat', timestamp);
save(filename, 'result');

fprintf('\n✅ 저장: %s\n', filename);