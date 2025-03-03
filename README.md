# LoopTrack: Fitness Tracker with Tokenized Rewards

A blockchain-based fitness tracking system that rewards users with tokens for achieving their fitness goals.

## Features
- Track fitness activities and goals
- Earn tokens for completing fitness milestones
- Transfer tokens between accounts
- View activity history and rewards
- Set and update fitness goals

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Log a fitness activity
(contract-call? .loop-track log-activity 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "running" u30 u5000)

;; Check rewards balance
(contract-call? .loop-track get-reward-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Set fitness goal
(contract-call? .loop-track set-goal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "running" u1000)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
