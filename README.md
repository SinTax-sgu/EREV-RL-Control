# EREV Transmission Control using Deep Reinforcement Learning

강화학습개론 프로젝트 - DQN 기반 EREV 변속 제어

작성자: 박준현 (기계공학과)  
날짜: 2025.12

---

## 1. 프로젝트 개요

EREV 차량의 2단 변속기를 DQN 알고리즘으로 제어하는 프로젝트입니다.

**개발 환경**
- MATLAB R2025b
- Simulink
- Reinforcement Learning Toolbox

**목표**
- 주행 중 최적 변속 타이밍 학습
- 속도 추종과 연비 최적화

---

## 2. 강화학습 설계

### 2.1 State (8차원)
```
[속도, 가속도, 페달입력, SOC, 현재기어, 효율, 파워, 목표속도]
```

### 2.2 Action (2개)
- Action 0: 1단 유지
- Action 1: 2단 유지

엔진 발전은 SOC 기반 Rule-based 제어
- SOC < 30%: 엔진 ON
- SOC > 40%: 엔진 OFF

### 2.3 Reward Function
```
R = -속도오차² × 0.02 + eff_Motor × W
```

W: eff_Motor 가중치 (실험별 변경)
- Version A: W = 10
- Version B: W = 15
- Version C: W = 20

추가 조건:
- 속도 오차 10km/h 이상 5초 지속 시 종료 (Reward -100)
- 변속 시 0.3초간 50% 동력 전달

### 2.4 DQN 구조

**Neural Network**
```
Input(8) → FC(128) → ReLU → FC(128) → ReLU → FC(64) → ReLU → Output(2)
```

**Hyperparameter**
- Learning Rate: 5e-4
- Discount Factor: 0.995
- Experience Buffer: 50,000
- Epsilon Decay: 0.995
- Batch Size: 128

---

## 3. 실험 조건

### 3.1 Hyperparameter 비교
eff_Motor 가중치를 변경하여 효율 중시 정도 조절

- Version A: W = 10 (Baseline)
- Version B: W = 15 (효율 강조)
- Version C: W = 20 (효율 극대화)

### 3.2 Random Seed 재현성 검증
각 조건을 Random seed와 Fixed seed(42)로 2회 실험하여 재현 가능성 확인

### 3.3 실험 요약

| 실험명 | eff gain | Random Seed | 비고 |
|--------|----------|-------------|------|
| A | 10 | Random | Baseline |
| B | 15 | Random | 효율 강조 |
| C | 20 | Random | 효율 극대화 |
| A2 | 10 | 42 (고정) | A 재현 |
| B2 | 15 | 42 (고정) | B 재현 |
| C2 | 20 | 42 (고정) | C 재현 |

### 3.4 학습 설정
- Episodes: 1000
- 주행 사이클: UDDS (1369초, 11.99km)
- 학습 시간: 약 6-8시간/실험
- 총 실험 횟수: 6회 (3가지 조건 × 2회)

---

## 4. 파일 구조

```
EREV-RL-Control/
├── models/
│   └── EREV_Model.slx              (Simulink 차량 모델)
├── scripts/
│   ├── create_EREV_agent.m         (DQN agent 생성)
│   ├── train_EREV_agent.m          (학습 실행)
│   ├── EREV_RL_Parameters.m        (차량 파라미터)
│   └── Reward_Calculator.m         (보상 함수)
├── results/
│   ├── agent_A_eff10_random.mat    (학습 결과)
│   ├── agent_B_eff15_random.mat
│   ├── agent_C_eff20_random.mat
│   ├── agent_A_eff10_seed42.mat
│   ├── agent_B_eff15_seed42.mat
│   ├── agent_C_eff20_seed42.mat
│   └── figures/                    (그래프)
├── report/
│   └── presentation.pptx           (발표 자료)
└── README.md
```

---

## 5. 실행 방법

### 5.1 Agent 생성 및 학습 준비

MATLAB에서:

1. Agent 생성
```matlab
cd scripts
run('create_EREV_agent.m')
```
출력: EREV_RL_agent.mat

2. 파라미터 파일 실행
```matlab
run('EREV_RL_Parameters.m')
```
(차량 파라미터 workspace에 로드)

### 5.2 학습 실행 (Random seed)

Reward_Calculator.m에서 eff_Motor 가중치 설정 후:
```matlab
run('train_EREV_agent.m')
```

과정:
1. Simulink 모델 로드
2. UDDS 사이클로 학습 (1000 episodes)
3. Training Progress 창 표시
4. 완료 후 자동 저장

### 5.3 학습 실행 (Fixed seed)

train_EREV_agent.m 맨 위에 추가:
```matlab
rng(42, 'twister');
```

이후 5.2와 동일하게 실행

### 5.4 결과 확인

학습된 agent 테스트:
```matlab
load('results/agent_A_eff10_random.mat')
open_system('models/EREV_Model.slx')
sim('models/EREV_Model.slx')
```

---

## 6. 실험 결과

### 6.1 성능 비교

| 실험명 | eff gain | Seed | 연비(km/L) | 변속횟수 | Episode Reward |
|--------|----------|------|-----------|----------|----------------|
| Rule | - | - | 151 | - | - |
| A | 10 | Random | TBD | TBD | TBD |
| A2 | 10 | 42 | TBD | TBD | TBD |
| B | 15 | Random | TBD | TBD | TBD |
| B2 | 15 | 42 | TBD | TBD | TBD |
| C | 20 | Random | TBD | TBD | TBD |
| C2 | 20 | 42 | TBD | TBD | TBD |

(학습 완료 후 업데이트 예정)

### 6.2 분석 지표

**Hyperparameter 영향**
- eff_Motor gain에 따른 성능 변화
- 효율 vs 변속 횟수 trade-off

**Random Seed 영향**
- 각 조건별 Random vs Fixed seed 결과 비교
- 재현 가능성 및 결과 안정성

### 6.3 평가 지표
- 연비 (km/L)
- 변속 횟수
- 속도 추종 오차
- 평균 모터 효율
- Episode Reward

---

## 7. 참고 문헌

[1] Mnih et al., "Human-level control through deep reinforcement learning", Nature, 2015

[2] MATLAB Reinforcement Learning Toolbox Documentation

---




