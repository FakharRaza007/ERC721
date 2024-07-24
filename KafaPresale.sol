
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IToken {
    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external view returns (uint8);
}


contract KAFAPresale {
    IToken public KAFA;
 

    address payable public owner;
    uint256 public amountRaisedMatic;
    
    uint256 private totalSupply;

    bool public CanBuy;

    enum SalePhase {
        Phase1,
        Phase2,
        Closed
    }
    SalePhase private currentPhase;

    struct User {
        uint256 Matic_balance;
        uint256 token_balance;
    }

    struct PhaseDetail {
        uint256 price;
        uint256 maxTokens;
        uint256 soldTokens;
        uint256 amountRaisedMatic;
    }

    mapping(SalePhase => PhaseDetail) private phaseDetails;
    mapping(address => User) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event PhaseChanged(SalePhase newPhase);

    constructor(address _token) {
     
        owner = payable(msg.sender);
        KAFA = IToken(_token);
        totalSupply = KAFA.totalSupply();
        CanBuy = true;

        phaseDetails[SalePhase.Phase1] = PhaseDetail({
            price: 125 ether,
            maxTokens: 1050_000_000 * 10**KAFA.decimals(),
            soldTokens: 0,
            amountRaisedMatic: 0
        });
        phaseDetails[SalePhase.Phase2] = PhaseDetail({
            price: 111.11 ether,
            maxTokens: 1050_000_000 * 10**KAFA.decimals(),
            soldTokens: 0,
            amountRaisedMatic: 0
        });
        currentPhase = SalePhase.Phase1;
    }

    receive() external payable {}

    function buyTokenMatic() public payable {
        require(CanBuy == true, "Can't buy token");
        require(currentPhase != SalePhase.Closed, "Sale is closed");
        uint256 numberOfTokens = MaticToToken(msg.value);
        uint256 tokenValue = tokenForSale();
        require(tokenValue >= numberOfTokens, "Insufficient tokens for sale");

        PhaseDetail storage phase = phaseDetails[currentPhase];
        require(
            phase.soldTokens + numberOfTokens <= phase.maxTokens,
            "Exceeds phase limit"
        );

        phase.soldTokens += numberOfTokens;
        phase.amountRaisedMatic += msg.value;
        amountRaisedMatic += msg.value;
        users[msg.sender].Matic_balance += msg.value;
        users[msg.sender].token_balance += numberOfTokens;

        KAFA.transferFrom(owner, msg.sender, numberOfTokens);

        if (phase.soldTokens >= phase.maxTokens) {
            currentPhase = SalePhase.Closed;
            emit PhaseChanged(SalePhase.Closed);
        }
    }

    function MaticToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * phaseDetails[currentPhase].price) / 1 ether;
        uint256 tokens = (numberOfTokens * (10**KAFA.decimals())) / 1 ether;
        return tokens;
    }
    //https://github.com/FakharRaza007/ERC721
    function MaticToToken_phaseDetail(uint256 _amount,SalePhase _phase) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * phaseDetails[_phase].price) / 1 ether;
        uint256 tokens = (numberOfTokens * (10**KAFA.decimals())) / 1 ether;
        return tokens;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        totalSupply = _totalSupply;
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeToken(address _token) external onlyOwner {
        KAFA = IToken(_token);
    }
    function contractBalanceMatic() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalTokensSold() external view returns (uint256) {
        uint256 totalSoldTokens = 0;
        for (uint8 i = 0; i <= uint8(SalePhase.Closed); i++) {
            totalSoldTokens += phaseDetails[SalePhase(i)].soldTokens;
        }
        return totalSoldTokens;
    }

    function setBuying(bool enable) external onlyOwner {
        require(enable != CanBuy, "Already in that state");
        CanBuy = enable;
    }

    function withdrawMatic(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    function tokenForSale() public view returns (uint256) {
        return KAFA.allowance(owner, address(this));
    }

    function withdrawTokens(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        IToken token = IToken(_tokenAddress);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
        token.transfer(owner, _amount);
    }

    function setPhase(SalePhase _phase) external onlyOwner {
        require(_phase != currentPhase, "Already in that phase");
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }

    function getActivePhase() external view returns (SalePhase) {
        return currentPhase;
    }

    function closePhase(SalePhase _phase) external onlyOwner {
        require(_phase != SalePhase.Closed, "Phase is already closed");
        currentPhase = SalePhase.Closed;
        emit PhaseChanged(SalePhase.Closed);
    }

    function setPhasePrice(SalePhase _phase, uint256 _price)
        external
        onlyOwner
    {
        phaseDetails[_phase].price = _price;
    }

    function setPhaseMaxTokens(SalePhase _phase, uint256 _maxTokens)
        external
        onlyOwner
    {
        phaseDetails[_phase].maxTokens = _maxTokens;
    }

    function getPhaseDetails(SalePhase _phase)
        external
        view
        returns (
            uint256 _price,
            uint256 _maxTokens,
            uint256 _soldTokens,
            uint256 _amountRaisedMatic
        )
    {
        PhaseDetail memory phase = phaseDetails[_phase];
        return (
            phase.price,
            phase.maxTokens,
            phase.soldTokens,
            phase.amountRaisedMatic
        );
    }
}