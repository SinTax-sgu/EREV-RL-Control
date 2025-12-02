%% create_EREV_agent.m
% 통합 제어용 RL Agent 생성 (최종 수정본)
% State: 8차원, Action: 4개 (기어 x 엔진On/Off)
% Epsilon Decay: 0.995 (빠른 학습)

clear all; close all; clc;

fprintf('===========================================\n');
fprintf('   EREV RL Agent 생성 (1주일 완성용)\n');
fprintf('===========================================\n\n');

%% 1. Observation (State) - 8차원
% [vel, accel, pedal, SOC, gear, eff, power, vel_desired]
obsInfo = rlNumericSpec([8 1]);
obsInfo.Name = 'EREV_State';
obsInfo.Description = 'Vehicle State Data';

%% 2. Action - 4가지 (통합 제어)
% 1: 1단 + EV (엔진 끔)
% 2: 2단 + EV (엔진 끔)
% 3: 1단 + 발전 (엔진 켬)
% 4: 2단 + 발전 (엔진 켬)
actInfo = rlFiniteSetSpec([1 2 3 4]);
actInfo.Name = 'Control_Command';

%% 3. Neural Network (128-128-64)
layers = [
    featureInputLayer(8, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(128, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(128, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(64, 'Name', 'fc3')
    reluLayer('Name', 'relu3')
    fullyConnectedLayer(4, 'Name', 'output')
];

criticOptions = rlRepresentationOptions('LearnRate', 5e-4, 'GradientThreshold', 1);
critic = rlQValueRepresentation(layers, obsInfo, actInfo, ...
    'Observation', {'state'}, criticOptions);

%% 4. Agent Options (가속 학습 설정)
agentOptions = rlDQNAgentOptions();
agentOptions.SampleTime = 0.1;
agentOptions.DiscountFactor = 0.99;
agentOptions.ExperienceBufferLength = 50000;
agentOptions.MiniBatchSize = 128;

% ★ 핵심: 탐험 속도 가속 (0.9995 -> 0.995)
agentOptions.EpsilonGreedyExploration.Epsilon = 1.0;
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.05;
agentOptions.EpsilonGreedyExploration.EpsilonDecay = 0.995; 

%% 5. Agent 생성 및 저장
agent = rlDQNAgent(critic, agentOptions);
save('EREV_RL_agent.mat', 'agent');

fprintf('✅ Agent 저장 완료 (Epsilon Decay: 0.995)\n');