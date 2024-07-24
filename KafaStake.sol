// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract KAFASTAKING is Ownable(msg.sender) {
    IERC20 public KAFA;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    struct Deposit {
        uint256 planDuration;
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        uint256 end;
    }

    mapping(address => Deposit[]) private users;

    constructor(address _KAFAAddress) {
        KAFA = IERC20(_KAFAAddress);
    }

    function invest(uint256 amount, uint256 _planDuration) public {
        require(_planDuration >= 1 && _planDuration <= 3, "Invalid duration");
        require(amount > 0, "Investment amount must be greater than zero");
        require(
            KAFA.transferFrom(msg.sender, address(this), amount),
            "KAFA transfer failed"
        );
        uint256 TIME_STEP;

        Deposit[] storage userDeposits = users[msg.sender];

        if (userDeposits.length == 0) {
            totalUsers++;
        }
        if (_planDuration == 1) {
            TIME_STEP = 30 days;
        } else if (_planDuration == 2) {
            TIME_STEP = 60 days;
        } else if (_planDuration == 3) {
            TIME_STEP = 90 days;
        }

        userDeposits.push(
            Deposit(_planDuration, amount, 0, block.timestamp, TIME_STEP)
        );

        totalInvested += amount;
        totalDeposits++;
    }

    function withdraw(uint256 index) public {
        Deposit[] storage userDeposits = users[msg.sender];
        require(index < userDeposits.length, "Invalid deposit index");

        Deposit storage deposit = userDeposits[index];

        uint256 amountToWithdraw = getUserDividends(msg.sender, index);
        require(amountToWithdraw > 0, "Withdrawal not available yet");

        deposit.withdrawn += amountToWithdraw;
        totalWithdrawn += amountToWithdraw;

        require(
            KAFA.transfer(msg.sender, amountToWithdraw),
            "KAFA transfer failed"
        );
    }

    function getUserDividends(address userAddress, uint256 index)
        public
        view
        returns (uint256 dividends)
    {
        Deposit[] storage userDeposits = users[userAddress];
        require(index < userDeposits.length, "Invalid deposit index");

        Deposit storage deposit = userDeposits[index];
        uint256 ROI_PERCENTAGE;

        if (deposit.end == 30 days) {
            ROI_PERCENTAGE = 200;
        } else if (deposit.end == 60 days) {
            ROI_PERCENTAGE = 300;
        } else if (deposit.end == 90 days) {
            ROI_PERCENTAGE = 400;
        }

        if (deposit.withdrawn < (deposit.amount * ROI_PERCENTAGE) / 100) {
            uint256 timeElapsed = block.timestamp - deposit.start;

            uint256 currentDividends = (deposit.amount *
                ROI_PERCENTAGE *
                timeElapsed) / (100 * deposit.end);

            if (
                deposit.withdrawn + currentDividends >
                (deposit.amount * ROI_PERCENTAGE) / 100
            ) {
                currentDividends =
                    (deposit.amount * ROI_PERCENTAGE) /
                    100 -
                    deposit.withdrawn;
            }

            dividends = currentDividends;
        } else {
            dividends = 0;
        }

        return dividends;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256 planDuration,
            uint256 amount,
            uint256 withdrawn,
            uint256 start,
            uint256 end
        )
    {
        Deposit[] storage userDeposits = users[userAddress];
        require(index < userDeposits.length, "Invalid deposit index");

        Deposit storage deposit = userDeposits[index];
        return (
            deposit.planDuration,
            deposit.amount,
            deposit.withdrawn,
            deposit.start,
            deposit.end
        );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        Deposit[] storage userDeposits = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < userDeposits.length; i++) {
            totalAmount += userDeposits[i].amount;
        }

        return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        Deposit[] storage userDeposits = users[userAddress];
        uint256 _totalWithdrawn;

        for (uint256 i = 0; i < userDeposits.length; i++) {
            _totalWithdrawn += userDeposits[i].withdrawn;
        }

        return _totalWithdrawn;
    }

    function setKAFA(address _tokenAddress) external onlyOwner {
        KAFA = IERC20(_tokenAddress);
    }

    function withdrawTokens(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient contract balance");
        token.transfer(msg.sender, amount);
    }

      function getUserDepositIds(address userAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256 depositCount = users[userAddress].length;
        uint256[] memory depositIds = new uint256[](depositCount);

        for (uint256 i = 0; i < depositCount; i++) {
            depositIds[i] = i;
        }

        return depositIds;
    }
}