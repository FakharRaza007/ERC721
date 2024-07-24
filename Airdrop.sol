// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function decimal() external view returns (uint8);
}

contract AirDrop {
    ERC20  token;
    ERC20 usdtToken;
    address public  owner;
    uint256 public dropOfTokens;
    uint public dropers;
    bool Open ;
    address[] droppersAllowed ;
    mapping(address => bool) private hasGotten;
    mapping(address => bool) private hasBlacklisted;

    constructor(address _tokenAddress/*address _usdtToken*/) {
        token = ERC20(_tokenAddress);
        // usdtToken = ERC20(_usdtToken);
       
        owner = msg.sender;
        dropOfTokens = 1000 * 10 ** uint8(token.decimal());
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }


    function getDrop() public {
       for (uint i; i<=droppersAllowed.length; i++) 
       {    
    if (msg.sender==droppersAllowed[i]) {
          break; } 
    
        }  
        require(Open,"Drop is close");
        require(dropers <= 100, "Drop has ended");
        require(!hasBlacklisted[msg.sender], "You are blacklisted");
        require(!hasGotten[msg.sender], "You have already gotten the drop");
        dropers++;
        token.transferFrom(owner, msg.sender, dropOfTokens);
        hasGotten[msg.sender] = true;
       }
       
    function changeDrop(uint256 amount) external onlyOwner {   
        dropOfTokens = amount;
    }

   function Opendrop(bool openORclose) external   onlyOwner returns(bool) {
       Open =openORclose ;
        return Open ; 
   }
    function blacklist(address _address, bool listedTo) external onlyOwner returns (bool) {
        hasBlacklisted[_address] = listedTo;
        return listedTo;
    }

      function setDroppers(address[]calldata arrayOfDroppers) external onlyOwner {
       droppersAllowed = arrayOfDroppers ;
    }

}
//["0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7","0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C","0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x17F6AD8Ef982297579C203069C1DbfFE4348c372","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]