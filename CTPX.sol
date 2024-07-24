// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CPTXcoin is IERC20, Ownable {
    string public _name = "CPTXcoin";
    string public _symbol = "CPTX";
    uint8 public _decimals = 18;
    uint256 public _totalSupply;
    uint256 public perSecond;
    uint256 public burnPerSecond;
    uint256 public tokenForBurn;
    uint256 public OpenMARKETSUPPLY;
    uint256 public stTime;
    uint256 public endTime;
    uint256 public tokenAvailableforSale;
    uint256 public totalSecondsin6years;
    uint256 public burnFor1Month;
    uint256 public TokensInyears;
    uint256 public userIndex;

    AggregatorV3Interface public priceFeedforBNB;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    struct UserRewardList {
        address _address;
        uint256 stTime;
        uint256 totalReward;
        uint256 totalStaked;
        uint256 endTime;
        uint256 userIndex;
    }

    mapping(uint256 => UserRewardList) public userRewardlist;
    uint256[] Ids;
    event Staked(address indexed _address, uint256 amount, uint256 endTime);
    event Unstaked(address indexed user, uint256 amount);

    constructor() {
        TokensInyears = 7_000_000 * 10**_decimals;
        _totalSupply = 10_000_000 * 10**_decimals;
        totalSecondsin6years = 189_216_000;
        burnFor1Month = 6944444 * 10**(_decimals - 2);
        perSecond = (22196 * 10**(_decimals - 3)) / 60; // Per second rate based on per minute
        burnPerSecond = burnFor1Month / (30 * 24 * 60 * 60); // Per second burn rate
        OpenMARKETSUPPLY = 3_000_000 * 10**_decimals;
        tokenForBurn = 5_000_000 * 10**_decimals;
        stTime = block.timestamp;
        endTime = stTime + totalSecondsin6years;
        // priceFeedforBNB = AggregatorV3Interface(
        //     0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        // );
    }

    function perc_lockforyears(uint256 _percentage) external onlyOwner {
        TokensInyears = (_totalSupply * _percentage) / 100;
        perSecond = TokensInyears / totalSecondsin6years;
    }

    function perc_burn(uint256 _percentage) external onlyOwner {
        burnFor1Month = (_totalSupply * _percentage) / 100;
        burnPerSecond = burnFor1Month / (30 * 24 * 60 * 60);
    }

    function set_percMarketSupply(uint256 _percentage) public onlyOwner {
        OpenMARKETSUPPLY = (_totalSupply * _percentage) / 100;
    }

    function tokensForSale() public onlyOwner returns (uint256) {
        require(block.timestamp <= endTime, "Sale Time has passed");

        uint256 timeElapsed = block.timestamp - stTime;
        uint256 tokenToSale = perSecond * timeElapsed;
        _balances[owner()] += tokenToSale;

        uint256 currentBurnToken = burnPerSecond * timeElapsed;
        require(
            _balances[owner()] >= currentBurnToken,
            "Not enough tokens to burn"
        );
        _balances[owner()] -= currentBurnToken;
        _totalSupply -= currentBurnToken;
        emit Transfer(owner(), address(0), currentBurnToken);

        tokenAvailableforSale = _balances[owner()];

        return tokenAvailableforSale;
    }

    // function StakeBNB() public payable {
    //     uint256 latestPrice = 700/*uint256(getLatestPrice()) / 10**8*/;
    //     uint256 latestBNBPrice = latestPrice;
    //     uint256 dollarsFromBnb = (msg.value * latestBNBPrice) / 1 ether;
    //     uint256 _index = Ids.length + 1;
    //     Ids.push(_index);
    //     UserRewardList memory listed;
    //     listed._address = msg.sender;
    //     listed.stTime = block.timestamp;
    //     listed.totalReward = dollarsFromBnb * 2;
    //     listed.totalStaked = dollarsFromBnb;

    //     if (dollarsFromBnb >= 100 && dollarsFromBnb < 200) {
    //         listed.endTime = block.timestamp + 34560000; // 400 days
    //     } else if (dollarsFromBnb >= 200 && dollarsFromBnb < 500) {
    //         listed.endTime = block.timestamp + 28800000; // 333.33 days
    //     } else if (dollarsFromBnb >= 500 && dollarsFromBnb < 1000) {
    //         listed.endTime = block.timestamp + 30; // 250 days
    //     } else if (dollarsFromBnb >= 1000) {
    //         listed.endTime = block.timestamp + 17280000; // 200 days
    //     }
    //     userRewardlist[_index] = listed;
    //     emit Staked(msg.sender, dollarsFromBnb, listed.endTime);
    // }

    // function unStake(uint256 _index) public {
    //     uint256 latestPrice = 700/*uint256(getLatestPrice()) / 10**8*/;
    //     uint256 latestBNBPrice = latestPrice;
    //     UserRewardList memory listed = userRewardlist[_index];
    //     require(listed._address == msg.sender, "Only the staker can unstake");
    //     require(
    //         block.timestamp >= listed.endTime,
    //         "You can't unStake until your reward becomes double"
    //     );
    //     uint256 returnReward = (listed.totalReward * 1 ether) / latestBNBPrice;
    //     payable(msg.sender).transfer(returnReward);
    //     delete userRewardlist[_index];
    //     emit Unstaked(msg.sender, returnReward);
    // }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeedforBNB.latestRoundData();
        return price;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}