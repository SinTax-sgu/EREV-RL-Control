# EREV RL Control

DQN 기반 EREV 2단 변속기 제어

---

## 1. 프로젝트 개요

강화학습(DQN)을 이용한 EREV 차량 2단 변속기 최적 제어

- 차량: Hyundai Santa Fe PHEV 기반
- 주행 사이클: UDDS (1,369초, 11.96km)
- 알고리즘: DQN
- Reward 함수 가중치를 변경하여 3가지 버전 실험

---

## 2. State & Action

**State Space (8차원)**
```
[속도, 가속도, 페달입력, SOC, 현재기어, 모터효율, 모터파워, 목표속도]
```

**Action Space (2개)**
- Action 1: 1단 유지
- Action 2: 2단 유지

**Reward Function**
```
R = -(v - v_target)² × 0.02 + eff_motor × W + shift × P_shift
```

**DQN Network**
```
Input(8) → FC(128,ReLU) → FC(128,ReLU) → FC(64,ReLU) → Output(2)
```

---

## 3. 필수 환경

MATLAB R2025a 이상
- Simulink
- Deep Learning Toolbox
- Reinforcement Learning Toolbox

---

## 4. 파일 구조

```
EREV-RL-Control/
├─ models/
│  └─ EREV_1_Model_RL.slx          # Simulink 차량 모델
│
├─ scripts/
│  ├─ create_EREV_agent.m          # Agent 생성 (먼저 실행)
│  ├─ EREV_RL_Parameters.m         # 차량 파라미터
│  ├─ train_EREV_agent.m           # 학습 실행
│  └─ calculate_EREV_efficiency.m  # 성능 비교 
│
├─ results/
│  ├─ agents/
│  │  ├─ agent_A_random.mat        # Ver A (Random seed)
│  │  ├─ agent_A_seed42.mat        # Ver A (Fixed seed)
│  │  ├─ agent_B_random.mat        # Ver B (Random seed)
│  │  ├─ agent_B_seed42.mat        # Ver B (Fixed seed)
│  │  ├─ agent_C_random.mat        # Ver C (Random seed)
│  │  └─ agent_C_seed42.mat        # Ver C (Fixed seed)
│  │
│  └─ training_curves/             # 학습 곡선 그래프
│
├─ report/
│  ├─ 강화학습프로젝트보고서_20201807.pptx    # PPT 보고서
│  └─ EREV_모델링_자료.pptx         # 추가 자료 (차량 모델링)
│
└─ README.md
```

---

## 5. 실행 방법

### 5.1 Agent 생성
```matlab
cd scripts
run('create_EREV_agent.m')
```

### 5.2 파라미터 로드
```matlab
run('EREV_RL_Parameters.m')
```

### 5.3 학습 실행

Simulink 모델에서 MATLAB Function 블록의 Reward 가중치 수정:
```
W_eff = 10;      # Ver A: 10, Ver B/C: 20
P_shift = 0;     # Ver A/C: 0, Ver B: -0.03
```

학습 실행:
```matlab
run('train_EREV_agent.m')
```

Fixed seed로 학습하려면 train_EREV_agent.m 상단에 추가:
```matlab
rng(42, 'twister');
```

### 5.4 테스트
```matlab
load('results/agents/agent_A_random.mat')
open_system('models/EREV_1_Model_RL.slx')
sim('models/EREV_1_Model_RL.slx')
```

---

## 6. 실험 내용

총 3가지 Reward 함수 버전으로 실험:

| 버전 | W (eff) | P_shift | 설명 |
|------|---------|---------|------|
| Ver A | 10 | 0.00 | Baseline |
| Ver B | 20 | -0.03 | 변속 비용 반영 |
| Ver C | 20 | 0.00 | 효율 극대화 |

각 버전당 Random seed, Fixed seed(42) 2회씩 학습.

학습 조건:
- Episodes: 1,000
- Step: 13,690 (0.1초당 1번)
- 학습 시간: 약 12시간/실험

---

## 7. 실험 결과

| Method | 연비 (km/kWh) | 변속 횟수 | 속도 RMSE |
|--------|---------------|----------|----------|
| Rule-based | 17.02 | 42 | 0.00278 | ~0.003 |
| Ver A | 15.52 ± 0.21 | 635 ± 381 | ~0.003 |
| Ver B | 15.58 ± 0.13 | 128 ± 126 | ~0.003 |
| Ver C | 15.59 ± 0.14 | 146 ± 143 | ~0.003 |

---

**Last Updated:** 2025.12.07
