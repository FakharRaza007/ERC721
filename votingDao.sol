// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interface Token {
//     function transfer(address recipient, uint256 amount)
//         external
//         returns (bool);

//     function decimals() external view returns (uint8);

//     function balanceOf(address account) external view returns (uint256);
// }

contract Voting {
    // Token token;
   
    // uint256 public winningVoteCount = 0;
    uint128 public candidatesCount;
    uint256 public totalVotes;
    uint8 public ExecutedCount;
    address contractOwner  ;
    address public  winnerAdress ;
    uint256 winnerId;
    uint256 winnerVoteCount;
    uint limit ;
    uint8 public DAOsCount ;
    uint8 VALUE ;
    

    struct Candidate {
        uint128 id;
        string name;
        uint256 voteCount;
        address candidateAddress;
        bool hasAdded;
    }
    struct votersData {
        address candidateAddress;
        uint128 candidateId;
        bool hasVoted;
    }
    struct Register {
        address voterAddress;
        bool hasRegistered;
    }

     struct Proposal {
        address candidateAddress;
        uint id;
        bool executed;
        uint voteCount;
        uint premitted;
        
    }
    Proposal[] public _proposal ;

    event WinningDetails(string indexed winnerName ,uint  winnerVoteCount,address indexed  winnerAdress  ,uint  id   );
    
       constructor(/*Token _token*/) {
       
        // token = _token;
        contractOwner = msg.sender ;
    }
    modifier onlycontractOwner(){
        require(msg.sender==contractOwner,"you are not the owner");
        _;
    }
    modifier onlyDAOs(){
        for (uint128 i; i>_proposal.length; i++) 
        {
           require(msg.sender==_proposal[i].candidateAddress,"onlyDAOs can execute Proposal");
        }
        _;
    }
    

    mapping(uint128 => Candidate) public candidates;
    mapping(address => votersData) public votersDetail;
    mapping(address => Register) register;
    mapping (address=>bool) hasregisetered ;

    function addCandidate(
        string memory _name,
        address _addr
        
    ) public onlycontractOwner {
        
        require(hasregisetered[_addr]==false,"you cannot enter");
        require(candidates[candidatesCount].candidateAddress!=_addr,"you already added");
        limit++;
        require(limit<=4,"only four candidates are allowed");
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _addr, false);
        hasregisetered[_addr] = true ;
         

        }

    function vote(uint128 _candidateId) public {
        require(register[msg.sender].hasRegistered, "Register first");
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Invalid candidate ID."
        );

        votersData storage detail = votersDetail[msg.sender];
        detail.candidateId = _candidateId;
        detail.hasVoted = true;
        detail.candidateAddress = candidates[_candidateId].candidateAddress;
        candidates[_candidateId].voteCount++;
        totalVotes++;
        register[msg.sender].hasRegistered = false;
    }

    function registerVoter(address voterAddress) public {
           require(
            register[msg.sender].hasRegistered == false,
            "you can  register only one time"
        );
        require(
            register[voterAddress].voterAddress != msg.sender,
            "don't do that"
        );
        require(msg.sender==voterAddress,"enter valid address");
     
        Register storage list = register[voterAddress];
        list.voterAddress = voterAddress;
        list.hasRegistered = true;
    }

    function getResults()
        public onlycontractOwner
        returns (
            string memory winnerName,
            
            bool winnerIs
        )
    {
        uint256  winningVoteCount =0;

        for (uint128 i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerName = candidates[i].name;
                winnerAdress = candidates[i].candidateAddress;
                winnerVoteCount = winningVoteCount;
                winnerId = candidates[i].id;
                candidates[i].hasAdded = true;
                winnerIs = candidates[i].hasAdded;
           
            }
         delete candidates[i]  ;
            }
         emit WinningDetails(winnerName,winnerVoteCount,winnerAdress,winnerId );
         limit=0;
         winningVoteCount=0;
         candidatesCount = 0 ;
        }
    

    function executeProposal() public onlyDAOs returns(string memory) {
    
        
        for (uint256 i = 0; i < _proposal.length; i++) {
        require(_proposal[i].premitted==0, "Permission already given");
           bool isOwner ;
            if (msg.sender ==_proposal[i].candidateAddress && !isOwner) {
                isOwner = true;
                _proposal[i].premitted=1;
                break;
            }
        }

       
        ExecutedCount++;
        return "transfer proposal executed";
    }
//
      function calculateApprovalPercentage() public  returns (uint8) {
       
       VALUE =  uint8((ExecutedCount * 60) / 100);
        return VALUE ;
    }

    // function transfer(address _address ,uint amount) public onlycontractOwner {
    //     require(calculateApprovalPercentage() == VALUE, "Approval from 60% of DAOs required");
    //     token.transfer(_address, amount);

    // }


function addDAOs()public {
     for (uint128 i; i<=_proposal.length; i++) 
        {
    if (winnerAdress !=_proposal[i].candidateAddress) {
                
     _proposal.push(Proposal(winnerAdress, winnerId, true, winnerVoteCount,0));
      DAOsCount++;  

            }
            else{
                revert("ERROR");
            }
          
        }

}}

  



