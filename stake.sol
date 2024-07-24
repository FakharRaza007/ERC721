// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Staking {
    uint256 Stakerindex;
    IERC20 token;

    struct Users {
        address _address;
        uint256 stTime;
        uint256 StakedAmount;
        uint256 rewardReturn;
    }
    struct rewarded {
        
              uint256 rewardReturn;
    }
   

    constructor(address _Token) {
        token = IERC20(_Token);
    }

    mapping(uint256 => Users) public checkUserDetail;
    mapping(uint256 =>rewarded ) public checkDetail;
 
    function calculations(uint256 _Index) public view returns (uint256) {
        require(_Index <= Stakerindex, "Invalid index");

        uint256 timeElapsed = block.timestamp - checkUserDetail[_Index].stTime;
        uint256 rewardCalculate = (checkUserDetail[_Index].StakedAmount * 1) /
            100;
        uint256 reward = timeElapsed * rewardCalculate;

        return reward;
    }

    function stake(uint256 amount) public {
        Stakerindex++;
        token.transferFrom(msg.sender, address(this), amount);
        Users storage user = checkUserDetail[Stakerindex];
          rewarded storage gotreward  =checkDetail[Stakerindex] ;

        //    Detail[Stakerindex].amount =  amount ;

        user._address = msg.sender;
        user.StakedAmount = amount;
        user.stTime = block.timestamp;

        user.rewardReturn = 0;
        gotreward.rewardReturn = amount ;
    }

    uint  public remainingReward;

    uint256 public _amount;

    function Unstake(uint256 _index) public {
        uint256 calculater = (checkUserDetail[_index].StakedAmount * 1) / 100;
        uint256 timeElapsed = block.timestamp - checkUserDetail[_index].stTime;
        uint256 timeDuration = checkUserDetail[_index].StakedAmount /
            calculater;

        Users storage userReward = checkUserDetail[_index];
        rewarded storage gotreward  =checkDetail[_index] ;

    

    //  remainingReward = checkUserDetail[_index].StakedAmount - userReward.rewardReturn  ;

        //   remainingReward =  ;

        uint256 rewardPersecond = calculations(_index) -
            checkUserDetail[_index].rewardReturn;

        if (timeElapsed >= timeDuration) {
            token.transfer(
                msg.sender,
                checkUserDetail[_index].StakedAmount + gotreward.rewardReturn  
            );

            delete checkUserDetail[_index];
        } else {
            token.transfer(msg.sender, rewardPersecond);
            userReward.rewardReturn += rewardPersecond;
            gotreward.rewardReturn -=rewardPersecond ;

        }
    }

    // uint timeDuration  =  checkUserDetail[_index].StakedAmount / calculater ;

    // uint remainingReward = checkUserDetail[_index].StakedAmount ;

    //

    // token.transfer(msg.sender,checkUserDetail[_index].StakedAmount+remainingReward);
    // delete checkUserDabout:blank#blockedetail[_index] ;

    // }
}
