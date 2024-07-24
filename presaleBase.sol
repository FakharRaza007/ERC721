// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import ERC20 interface for token transfers
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function mint(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    function getLatestPrice() public pure returns (uint ) {
        // (, uint price, , , ) = priceFeed.latestRoundData();

        return uint256(59673539231);
    }
}

contract PresaleTEST is PriceConsumerV3 {
    address public owner;
    IERC20 public TEST;
    uint public totalRaisedBNB;
    uint public totalRaisedUSDT;
    uint256 public startTime;
    uint256 public endTime;

    struct TokenDetails {
        IERC20 tokenAddress;
        uint256 price;
        uint256 totalSold;
    }

    TokenDetails[] public tokenList;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(uint _startTime, uint _endTime) {
        startTime = _startTime;
        endTime = _endTime;
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        tokenList.push(TokenDetails(IERC20(address(0)), 66, 0));
        tokenList.push(
            TokenDetails(
                IERC20(0x6594F78B288086BB46CEE09DE871420852DEaDC4),
                66,
                0 
            )
        );
        TEST = IERC20(0xe5a347116B23e31932598F3B0Fa2ec1fbe020d39);
    }

    // Function to update the price of a token (for the owner)
    function updateTokenPrice(
        uint256 _tokenIndex,
        uint256 _price
    ) external onlyOwner {
        require(_tokenIndex < tokenList.length, "Invalid token index");
        tokenList[_tokenIndex].price = _price;
    }

    // Function to set the address of the TEST token (for the owner)
    function setTESTAddress(address _newTokenAddress) external onlyOwner {
        TEST = IERC20(_newTokenAddress);
    }

    // Function to transfer ownership (for the owner)
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner address cannot be zero");
        owner = _newOwner;
    }

    function buyTokens(uint256 _tokenIndex, uint256 _amount) external payable {
        // require(
        //     block.timestamp >= startTime && block.timestamp <= endTime,
        //     "Presale is not active"
        // );
        uint256 tokenBought;
        require(_tokenIndex < tokenList.length, "Invalid token index");

        if (_tokenIndex == 0) {
            tokenBought = calculateTokens(_tokenIndex, msg.value);
            totalRaisedBNB += msg.value;
        } else {
            tokenBought = calculateTokens(_tokenIndex, _amount);
            totalRaisedUSDT += _amount;
        }

        tokenList[_tokenIndex].totalSold += tokenBought;
        TEST.transferFrom(owner, msg.sender, tokenBought);
    }

// 596735392310000000000

    function calculateTokens(
        uint256 _tokenIndex,
        uint256 _amount
    ) public view returns (uint256) {
        require(_tokenIndex < tokenList.length, "Invalid token index");
        uint256 tokenPrice = tokenList[_tokenIndex].price;
        uint256 usdtPrice = getLatestPrice(); // Fetch USDT price from Chainlink
        uint256 decimal = 10 ** TEST.decimals();
        uint256 tokenAmount;
        if (_tokenIndex == 0) {
            uint256 bnbtousdt = _amount * usdtPrice;
            
            tokenAmount = (bnbtousdt * tokenPrice * decimal) / (1 ether) / 1e8;
        } else {
            tokenAmount = (_amount * tokenPrice * decimal) / (1 ether);
        }

        return tokenAmount;
    }
    //39865809524519408283261693

    function withdrawEther(uint256 amount) external onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient balance in the contract"
        );
        payable(owner).transfer(amount);
    }

    function withdrawTokens(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner, amount);
    }

    function getTotalSoldTokens() external view returns (uint256) {
        uint256 totalTokensSold = 0;
        for (uint256 i = 0; i < tokenList.length; i++) {
            totalTokensSold += tokenList[i].totalSold;
        }
        return totalTokensSold;
    }

    function setPresalePeriod(
        uint256 _newStartTime,
        uint256 _newEndTime
    ) external onlyOwner {
        require(
            _newStartTime > block.timestamp,
            "Start time must be in the future"
        );
        require(
            _newEndTime > block.timestamp,
            "End time must be in the future"
        );
        require(
            _newEndTime > _newStartTime,
            "End time must be after the start time"
        );

        startTime = _newStartTime;
        endTime = _newEndTime;
    }

    receive() external payable {}
}
//1 bnb ==