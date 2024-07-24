// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract VestingPresale {
    address payable public owner;
    IERC20 public KAFA;
    uint256 private totalSupply;
    bool public CanBuy;

    struct PhaseDetail {
        uint256 price;
        uint256 cliff;
        uint256 duration;
        uint256 amount;
        
    }
    
    struct PhaseDetails {
        uint256 price;
        uint256 cliff;
        uint256 duration;
        uint256 amount;
        uint256 start;
        address beneficiary;
        uint256 tokenBought;
        uint256 tokenWithdrawn;
    }

    mapping(uint => PhaseDetail) public phaseDetails;
    mapping(address => mapping(uint => mapping(uint => PhaseDetails))) public UserDetailPhase;
    mapping(address => uint) public UserPhase;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    event BuyToken(address indexed user, uint256 indexed phase, uint256 indexed index, uint256 amount);
    event ClaimToken(address indexed user, uint256 indexed phase, uint256 indexed index, uint256 amount);

    constructor(address _token) {
        owner = payable(msg.sender);
        KAFA = IERC20(_token);
        totalSupply = KAFA.totalSupply();
        CanBuy = true;

        phaseDetails[0] = PhaseDetail({
            price: 2 ether,
            cliff: 30 seconds,
            duration: 60 seconds,
            amount: 10 * 10 ** KAFA.decimals()
        });
        phaseDetails[1] = PhaseDetail({
            price: 1 ether,
            cliff: 40 seconds,
            duration: 60 seconds,
            amount: 10 * 10 ** KAFA.decimals()
            
        });
    }

    function BuyTokens(uint SelectPhase, uint index) public payable {
        require(CanBuy, "Buying is disabled");
        require(msg.value >= phaseDetails[SelectPhase].price, "Insufficient ETH sent");

        PhaseDetails storage userPhase = UserDetailPhase[msg.sender][SelectPhase][index];
        PhaseDetail storage phase = phaseDetails[SelectPhase];
        
        userPhase.price = phase.price;
        userPhase.duration = phase.duration;
        userPhase.cliff = phase.cliff;
        userPhase.amount = phase.amount;
        userPhase.start = block.timestamp;
        userPhase.beneficiary = msg.sender;

        uint256 numberOfTokens = ETHToToken(msg.value, SelectPhase); 
        userPhase.tokenBought = numberOfTokens;

        emit BuyToken(msg.sender, SelectPhase, index, numberOfTokens);
    }

    function claimTokens(uint256 SelectPhase, uint index) public {
        PhaseDetails storage schedule = UserDetailPhase[msg.sender][SelectPhase][index];
        require(block.timestamp >= schedule.start + schedule.cliff, "Cliff period not reached");

        uint256 vestedAmount = calculateVestedAmount(msg.sender, SelectPhase, index);
        uint256 claimable = vestedAmount - schedule.tokenWithdrawn;

        require(claimable > 0, "No tokens available for claim");

        schedule.tokenWithdrawn += claimable;
        require(KAFA.transferFrom(owner,msg.sender, claimable), "Token transfer failed");

        emit ClaimToken(msg.sender, SelectPhase, index, claimable);
    }

    function calculateVestedAmount(address _address, uint SelectPhase, uint256 index) public view returns (uint256) {
        PhaseDetails memory schedule = UserDetailPhase[_address][SelectPhase][index];
        
        if (block.timestamp < schedule.start + schedule.cliff) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.duration) {
            return schedule.tokenBought;
        } else {
            uint256 elapsedTime = block.timestamp - (schedule.start + schedule.cliff);
            uint256 vestingDuration = schedule.duration - schedule.cliff;
            uint256 vestedAmount = (schedule.tokenBought * elapsedTime) / vestingDuration;
            return vestedAmount;
        }
    }

    function ETHToToken(uint256 _amount, uint SelectPhase) public view returns (uint256) {
        uint256 tokenTransfer = (_amount * phaseDetails[SelectPhase].amount) / phaseDetails[SelectPhase].price; 
        uint256 tokens = (tokenTransfer * (10 ** KAFA.decimals())) / 1 ether;
        return tokens;
    }

    function setCanBuy(bool _canBuy) external onlyOwner {
        CanBuy = _canBuy;
    }
}
