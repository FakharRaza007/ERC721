// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 interface ERC20 {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface  AggregatorV3Interface{
 function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

}
contract  priceFetcher{
   AggregatorV3Interface internal priceFeedforBNB ;

function getprice() public view returns (int256 price){
  (,price,,,) =priceFeedforBNB.latestRoundData();
   return price ;   
}

}
contract preSale is priceFetcher {

    ERC20  token;
    ERC20  busdtToken ;
    address public  owner ;  
    uint tokenPrice = 10 ;
        constructor() {
         token = ERC20(0x13e54D69b3B78bb28b3515820455dE6fdB03F3E4);
         busdtToken =  ERC20(0xf4530fe397766C4140DD516929BF5F72bD87781e);
            priceFeedforBNB = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
            owner = msg.sender;
        }

        modifier onlyOwner(){
require(msg.sender==owner,"only owner can call");
_;
        }


function buyTokenByBNB(uint amount) public payable {
        uint returnAmount =  checkTokensForBNB(amount);
        token.transferFrom(owner, msg.sender, returnAmount);
}
function buyTokens(uint amount) public  {
        uint returnAmount =  checkTokensForanyToken(amount);
        token.transferFrom(owner, msg.sender, returnAmount);
        busdtToken.transferFrom(msg.sender,address(this),amount);

}

function checkTokensForBNB(uint256 amount)public view returns(uint256) {
     uint price = 60 /*getprice();*/ ;
     uint Decimal = 10**token.decimals();
     uint BnbToUsdt = amount*price ;
     uint tokenAmount = (BnbToUsdt*tokenPrice*Decimal) / (1 ether) ; 
     return tokenAmount ;
}

function checkTokensForanyToken(uint256 amount)public view returns(uint256) {
     uint Decimal = 10**uint8(token.decimals());
     uint returnTokens = (amount*tokenPrice*Decimal) / (1 ether) ;
    return returnTokens ;

}
// function sellTokens(uint amount)public  {
//     uint BNbPrice = 60;
//     uint valueOftoken  =  amount /(10**uint256(token.decimal()));
//     uint returnBNB = (valueOftoken*1 ether)/BNbPrice;
//     token.transferFrom(msg.sender, address(this), amount);
//     payable(msg.sender).transfer(returnBNB);

// }
// function sellUSDT(uint amount)public  {
//     uint BNbPrice = 60;
//     uint valueOftoken  =  amount /(10**uint256(token.decimal()));
//     uint returnBNB = (valueOftoken*1 ether)/BNbPrice;
//     token.transferFrom(msg.sender, address(this), amount);
//     payable(msg.sender).transfer(returnBNB);

// }

// function withdrawBNB()public onlyOwner {
// payable (msg.sender).transfer(address(this).balance);

// }
receive() external payable {}
    
}