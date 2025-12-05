EREV Transmission Control using Deep Reinforcement Learning
강화학습개론 프로젝트 - 강화학습 기반 EREV 변속 제어

프로젝트 개요
EREV(Extended Range Electric Vehicle) 차량의 2단 변속기를 DQN 알고리즘으로 제어하는 프로젝트입니다. 기존 Rule-based 방식 대신 강화학습을 통해 최적 변속 타이밍을 학습시켰습니다.
개발 환경

MATLAB R2025b
Simulink (차량 모델)
Reinforcement Learning Toolbox

문제 정의

주행 중 1단/2단 변속을 언제 할 것인가?
속도 추종과 효율 최적화의 균형


강화학습 설계
State (8개)
차량 상태를 나타내는 8개 변수
[속도, 가속도, 페달입력, SOC, 현재기어, 효율, 파워, 목표속도]
Action (2개)

Action 0: 1단 유지
Action 1: 2단 유지

*엔진 발전은 SOC 기반 룰로 따로 제어
Reward
matlabR = -속도오차² × 10 + (효율-0.5) × 20 - 변속페널티 × 5
DQN 구조
Input(8) → FC(128) → ReLU → FC(128) → ReLU → FC(64) → ReLU → Output(2)
주요 파라미터

Learning Rate: 5e-4
Discount Factor: 0.99
Experience Buffer: 50000
Epsilon Decay: 0.995 (빠른 수렴 위해)
Batch Size: 128


파일 구조
EREV-RL-Control/
├── models/
│   └── EREV_Model.slx          # Simulink 차량 모델
├── scripts/
│   ├── create_EREV_agent.m     # Agent 생성
│   ├── train_EREV_agent.m      # 학습 실행
│   └── EREV_RL_Parameters.m    # 차량 파라미터
├── results/
│   └── figures/                # 학습 결과 그래프
├── trained_agents/             # 학습된 agent 저장
└── report/
    └── presentation.pptx       # 발표 자료

실행 방법
1. Agent 생성
matlabcd scripts
run('create_EREV_agent.m')

Neural Network 생성 (128-128-64)
DQN agent 설정
agent 파일로 저장

2. 학습 실행
matlabrun('train_EREV_agent.m')

Simulink 모델과 연동
UDDS 사이클로 학습
학습 시간: 약 20시간 (500 episodes)

3. 학습 모니터링
MATLAB Training Progress 창에서 실시간 확인

Episode Reward
Q-value
Average Return

4. 학습된 agent 테스트
matlabload('trained_agents/agent_final.mat')
open_system('models/EREV_Model.slx')
sim('models/EREV_Model.slx')

학습 설정
Training Options
matlabMaxEpisodes = 500
MaxStepsPerEpisode = 13690  % UDDS 사이클 길이
Driving Cycle

UDDS (Urban Dynamometer Driving Schedule)
1369초, 최고속도 91.2 km/h


결과
(학습 완료 후 업데이트 예정)

구현 시 고민했던 점
1. State Space 설계

처음엔 6차원으로 했다가 목표속도, 파워 추가해서 8차원으로 확장
현재/목표 상태 둘 다 필요함

2. Reward 설계

속도추종만 보상하면 효율 무시
효율만 보상하면 속도추종 실패
가중합으로 해결

3. Action 단순화

처음엔 (기어 × 엔진) 4개 action으로 했는데 학습 너무 느림
변속만 RL로, 엔진은 Rule-based로 분리


참고 문헌

Mnih et al., "Human-level control through deep reinforcement learning", Nature, 2015
MATLAB Reinforcement Learning Toolbox Documentation


개발자
박준현 (기계공학과)
2025.12
