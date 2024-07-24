// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Vesting is Ownable(msg.sender) {
    IERC20 public KAFA;

    struct VestingSchedule {
        uint256 cliff;
        uint256 duration;
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
    }

    mapping(address => VestingSchedule[]) private vestingSchedules;

    constructor(address _KAFAAddress) {
        KAFA = IERC20(_KAFAAddress);
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 cliff,
        uint256 duration
    ) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");
        require(cliff <= duration, "Cliff must be less than or equal to duration");

        vestingSchedules[beneficiary].push(VestingSchedule({
            cliff: cliff,
            duration: duration,
            amount: amount,
            start: block.timestamp,
            withdrawn: 0
        }));
    }

    function claim(uint256 index) public {
        VestingSchedule storage schedule = vestingSchedules[msg.sender][index];
        require(block.timestamp >= schedule.start + schedule.cliff, "Cliff period not reached");

        uint256 vestedAmount = calculateVestedAmount(msg.sender, index);
        uint256 claimable = vestedAmount - schedule.withdrawn;

        require(claimable > 0, "No tokens available for claim");

        schedule.withdrawn += claimable;

        require(KAFA.transfer(msg.sender, claimable), "Token transfer failed");
    }

    function calculateVestedAmount(address beneficiary, uint256 index) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary][index];
        
        if (block.timestamp < schedule.start + schedule.cliff) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.duration) {
            return schedule.amount;
        } else {
            uint256 elapsedTime = block.timestamp - (schedule.start + schedule.cliff);
            uint256 vestingDuration = schedule.duration - schedule.cliff;
            uint256 vestedAmount = (schedule.amount * elapsedTime) / vestingDuration;
            return vestedAmount;
        }
    }

    function getVestingSchedule(address beneficiary, uint256 index) public view returns (uint256, uint256, uint256, uint256, uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary][index];
        return (
            schedule.cliff,
            schedule.duration,
            schedule.amount,
            schedule.start,
            schedule.withdrawn
        );
    }

    function getTotalVestingSchedules(address beneficiary) public view returns (uint256) {
        return vestingSchedules[beneficiary].length;
    }

    function setKAFA(address _tokenAddress) external onlyOwner {
        KAFA = IERC20(_tokenAddress);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        uint256 contractBalance = KAFA.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient contract balance");
        KAFA.transfer(msg.sender, amount);
    }

    function getAllVestingSchedules(address beneficiary) public view returns (VestingSchedule[] memory) {
        return vestingSchedules[beneficiary];
    }
}
