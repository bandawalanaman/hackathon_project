// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FitnessTracker is ERC20, Ownable {
    struct Goal {
        uint256 targetSteps;
        uint256 targetWorkouts;
        uint256 deadline;
        bool completed;
        uint256 rewardAmount;
    }
    
    mapping(address => Goal) public userGoals;
    mapping(address => uint256) public userSteps;
    mapping(address => uint256) public userWorkouts;
    
    uint256 public constant STEPS_REWARD_RATE = 100; // tokens per 10000 steps
    uint256 public constant WORKOUT_REWARD_RATE = 50; // tokens per workout
    
    event GoalSet(address indexed user, uint256 targetSteps, uint256 targetWorkouts, uint256 deadline);
    event StepsUpdated(address indexed user, uint256 steps);
    event WorkoutCompleted(address indexed user);
    event GoalCompleted(address indexed user, uint256 reward);
    
    constructor(address initialOwner) 
        ERC20("FitnessToken", "FIT") 
        Ownable(initialOwner) 
    {
        _mint(initialOwner, 1000000 * 10**decimals()); // Initial supply of 1 million tokens
    }
    
    function setGoal(uint256 _targetSteps, uint256 _targetWorkouts, uint256 _durationInDays) external {
        require(_targetSteps > 0 || _targetWorkouts > 0, "Must set at least one target");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        uint256 rewardAmount = calculateReward(_targetSteps, _targetWorkouts);
        
        userGoals[msg.sender] = Goal({
            targetSteps: _targetSteps,
            targetWorkouts: _targetWorkouts,
            deadline: deadline,
            completed: false,
            rewardAmount: rewardAmount
        });
        
        emit GoalSet(msg.sender, _targetSteps, _targetWorkouts, deadline);
    }
    
    function updateSteps(address user, uint256 newSteps) external onlyOwner {
        require(newSteps >= userSteps[user], "Steps can only increase");
        userSteps[user] = newSteps;
        checkGoalCompletion(user);
        emit StepsUpdated(user, newSteps);
    }
    
    function logWorkout(address user) external onlyOwner {
        userWorkouts[user]++;
        checkGoalCompletion(user);
        emit WorkoutCompleted(user);
    }
    
    function checkGoalCompletion(address user) internal {
        Goal storage goal = userGoals[user];
        if (goal.completed || goal.deadline < block.timestamp) {
            return;
        }
        
        if (userSteps[user] >= goal.targetSteps && userWorkouts[user] >= goal.targetWorkouts) {
            goal.completed = true;
            _mint(user, goal.rewardAmount);
            emit GoalCompleted(user, goal.rewardAmount);
        }
    }
    
    function calculateReward(uint256 targetSteps, uint256 targetWorkouts) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 stepReward = (targetSteps / 10000) * STEPS_REWARD_RATE;
        uint256 workoutReward = targetWorkouts * WORKOUT_REWARD_RATE;
        return stepReward + workoutReward;
    }
    
    function getUserProgress(address user) 
        external 
        view 
        returns (
            uint256 steps,
            uint256 workouts,
            uint256 targetSteps,
            uint256 targetWorkouts,
            uint256 deadline,
            bool completed,
            uint256 rewardAmount
        ) 
    {
        Goal memory goal = userGoals[user];
        return (
            userSteps[user],
            userWorkouts[user],
            goal.targetSteps,
            goal.targetWorkouts,
            goal.deadline,
            goal.completed,
            goal.rewardAmount
        );
    }
}