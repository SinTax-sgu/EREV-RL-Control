%% create_EREV_agent.m
% 변속 제어용 RL Agent 생성 (발전은 Rule-based)
% State: 8차원, Action: 2개 (1단/2단)
% Epsilon Decay: 0.995

clear all; close all; clc;

fprintf('===========================================\n');
fprintf('   EREV RL Agent 생성 (변속 전용)\n');
fprintf('   발전: Rule-based (Hysteresis)\n');
fprintf('===========================================\n\n');

%% 1. Observation (State) - 8차원
% [vel, accel, pedal, SOC, gear, eff, power, vel_desired]
obsInfo = rlNumericSpec([8 1]);
obsInfo.Name = 'EREV_State';
obsInfo.Description = 'vel_kph, accel, pedal, SOC, gear, eff, power, vel_desired';

fprintf('✅ State Space: 8차원\n');
fprintf('   - vel_kph, accel, pedal, SOC\n');
fprintf('   - gear, eff_motor, power, vel_desired\n\n');

%% 2. Action - 2가지 (변속만 제어)
% 1: 1단
% 2: 2단
actInfo = rlFiniteSetSpec([1 2]);
actInfo.Name = 'Control_Command';

fprintf('✅ Action Space: 2개\n');
fprintf('   - Action 1: 1단 선택\n');
fprintf('   - Action 2: 2단 선택\n');
fprintf('   (발전은 Rule-based로 자동 관리)\n\n');

%% 3. Neural Network (128-128-64)
layers = [
    featureInputLayer(8, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(128, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(128, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(64, 'Name', 'fc3')
    reluLayer('Name', 'relu3')
    fullyConnectedLayer(2, 'Name', 'output')  % ★ 2개 출력!
];

fprintf('✅ Neural Network: 128-128-64-2\n');
fprintf('   - 입력: 8차원\n');
fprintf('   - 은닉층: 128-128-64\n');
fprintf('   - 출력: 2개 (Q-value for each action)\n\n');

criticOptions = rlRepresentationOptions('LearnRate', 5e-4, 'GradientThreshold', 1);
critic = rlQValueRepresentation(layers, obsInfo, actInfo, ...
    'Observation', {'state'}, criticOptions);

%% 4. Agent Options (가속 학습 설정)
agentOptions = rlDQNAgentOptions();
agentOptions.SampleTime = 0.1;
agentOptions.DiscountFactor = 0.99;
agentOptions.ExperienceBufferLength = 50000;
agentOptions.MiniBatchSize = 128;

% ★ 핵심: 탐험 속도 (0.995)
agentOptions.EpsilonGreedyExploration.Epsilon = 1.0;
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.05;
agentOptions.EpsilonGreedyExploration.EpsilonDecay = 0.995;

fprintf('✅ DQN Options:\n');
fprintf('   - Epsilon Decay: 0.995 (빠른 학습)\n');
fprintf('   - Batch Size: 128\n');
fprintf('   - Buffer: 50000\n');
fprintf('   - Discount: 0.99\n\n');

%% 5. Agent 생성 및 저장
agent = rlDQNAgent(critic, agentOptions);

save('EREV_RL_agent.mat', 'agent');
fprintf('✅ Agent 저장 완료: EREV_RL_agent.mat\n\n');

fprintf('===========================================\n');
fprintf('   생성 완료!\n');
fprintf('===========================================\n\n');
