%% train_EREV_agent.m
% EREV RL 학습 스크립트 (최종)
% 특징: 초기 SOC 랜덤화, 메모리 관리, 자동 저장

Simulink.sdi.clear; % ★ 메모리 부족 방지 (데이터 캐시 삭제)

fprintf('===========================================\n');
fprintf('   🚀 EREV RL 학습 시작 (Final Run)\n');
fprintf('===========================================\n\n');

%% 1. 준비
if ~exist('EREV_RL_agent.mat', 'file')
    error('❌ Agent 파일이 없습니다. create_EREV_agent.m을 먼저 실행하세요.');
end
load('EREV_RL_agent.mat');

modelName = 'EREV_1_Model_RL';
agentBlock = 'EREV_1_Model_RL/RL_Agent';

if ~bdIsLoaded(modelName)
    load_system(modelName);
end

%% 2. 환경 생성 & 리셋 함수 연결
env = rlSimulinkEnv(modelName, agentBlock);
env.ResetFcn = @myResetFunction; % 하단 함수 참조

%% 3. Training Options (안전 제일)
trainOpts = rlTrainingOptions(...
    'MaxEpisodes', 1000, ...
    'MaxStepsPerEpisode', 30000, ...
    'ScoreAveragingWindowLength', 20, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'StopTrainingCriteria', 'AverageReward', ...
    'StopTrainingValue', 10000, ... 
    'SaveAgentCriteria', 'EpisodeCount', ... % 주기적 저장
    'SaveAgentValue', 50, ...                % 50판마다 저장
    'SaveAgentDirectory', 'saved_agents');

%% 4. 학습 실행
tic;
try
    trainingStats = train(agent, env, trainOpts);
    
    % 종료 후 저장
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    save(sprintf('Final_Agent_%s.mat', timestamp), 'agent', 'trainingStats');
    fprintf('\n✅ 학습 완료! 저장됨.\n');
    
catch ME
    fprintf('\n❌ 오류 발생: %s\n', ME.message);
end

%% [부록] 초기화 함수
function in = myResetFunction(in)
    % SOC를 25% ~ 75% 사이 랜덤 설정
    init_soc = 0.25 + 0.5 * rand();
    in = setVariable(in, 'SOC_init', init_soc);
end