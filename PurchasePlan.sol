
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract AIPLAN {
    address payable public owner; 
    IERC20 public USDT;
    uint256 private nextPackageIndex;

    struct Package {
        string packageName;
        uint256 usdtAmount;
        uint256 aiAmount;
        IERC20 aiConnect;
        bool aiConnectTokenSend;
        uint256 directBonusPercentage;
        uint256 binaryBonusPercentage;
        uint256 maxPayout;
        uint256[] matchingPointsArray;
        uint256 packagePoints;
        uint256 tokenlockPeriod;
        uint256 tokenStakePeriod;
        uint256 stakerewardPercentage;
    }

    struct Purchase {
        string packageName;
        uint256 packageIndex;
        uint256 timestamp;
        uint256 usdtAmount;
        uint256 aiAmount;
        uint256 lockPeriod;
        uint256 stakeTime;
        bool isStake;
        bool aiTokensClaimed;
        bool package;
    }
    
// ["Starter","1000_000000000000000000","2000_000000000000000000","0xE3Ca443c9fd7AF40A2B5a95d43207E763e56005F","true","20","10","500_000000000000000000","[100, 200, 300]","150","30","60","5"]
    struct PackageParams {
        string packageName;
        uint256 usdtAmount;
        uint256 aiAmount;
        IERC20 aiConnect;
        bool aiConnectTokenSend;
        uint256 directBonusPercentage;
        uint256 binaryBonusPercentage;
        uint256 maxPayout;
        uint256[] matchingPointsArray;
        uint256 packagePoints;
        uint256 tokenlockPeriod;
        uint256 tokenStakePeriod;
        uint256 stakerewardPercentage;
    }

    mapping(uint256 => Package) private packages;
    mapping(address => Purchase[]) public userPurchasesPackage;

    mapping(address => uint256) public userPoints;
    mapping(address => uint256) public userPayouts;

    uint256 public totalPoints;
    uint256 public totalAmountCollected;
    uint256 public maxPayout = 3000; 

    event PlanPurchased(address indexed user, uint256 indexed packageIndex, uint256 usdtAmount, uint256 timestamp);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event USDTAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event PackageAdded(uint256 indexed packageIndex, string packageName, uint256 usdtAmount, uint256 aiAmount, address aiConnect, bool aiConnectTokenSend, uint256 directBonusPercentage, uint256 binaryBonusPercentage , uint256 maxPayout, uint256[] matchingPointsArray, uint256 packagePoints);
    event PackageUpdated(uint256 indexed packageIndex, string packageName, uint256 usdtAmount, uint256 aiAmount, address aiConnect, bool aiConnectTokenSend, uint256 directBonusPercentage, uint256 binaryBonusPercentage, uint256 maxPayout, uint256[] matchingPointsArray, uint256 packagePoints);
    event TokensClaimed(address indexed user, uint256 indexed purchaseIndex, uint256 aiAmount);

    constructor() {
        owner = payable(msg.sender);
        USDT = IERC20(0x35BD1509a00CE3D6a7969A97cB075e0086A943cB);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    function addPackage(PackageParams memory params) external onlyOwner {
        uint256 packageIndex = nextPackageIndex++;
        packages[packageIndex] = Package({
            packageName: params.packageName,
            usdtAmount: params.usdtAmount,
            aiAmount: params.aiAmount,
            aiConnect: params.aiConnect,
            aiConnectTokenSend: params.aiConnectTokenSend,
            directBonusPercentage: params.directBonusPercentage,
            binaryBonusPercentage: params.binaryBonusPercentage,
            maxPayout: params.maxPayout,
            matchingPointsArray: params.matchingPointsArray,
            packagePoints: params.packagePoints,
            tokenlockPeriod: params.tokenlockPeriod,
            tokenStakePeriod: params.tokenStakePeriod,
            stakerewardPercentage: params.stakerewardPercentage
        });
        emit PackageAdded(packageIndex, params.packageName, params.usdtAmount, params.aiAmount, address(params.aiConnect), params.aiConnectTokenSend, params.directBonusPercentage, params.binaryBonusPercentage, params.maxPayout, params.matchingPointsArray, params.packagePoints);
    }

    function addPoints(address user, uint256 points) external onlyOwner {
        userPoints[user] += points;
        totalPoints += points;
    }

    function calculateXFactor() public view returns (uint256) {
        uint256 xFactor = (totalAmountCollected * 35) / totalPoints;
        if (xFactor < 1 ether) {
            xFactor = 1 ether; 
        }
        return xFactor;
    }

    function purchasePlan(uint256 selectedPlan, address msg_sender) external {
        // require(selectedPlan < nextPackageIndex, "Invalid plan selected");

        for (uint256 i = 0; i < selectedPlan; i++) {
            require(
                userHasPackage(msg_sender, i),
                "Purchase previous packages first"
            );
        }

        uint256 amountToPay = getRequiredPayment(selectedPlan, msg_sender);

        require(
            USDT.transferFrom(msg.sender, address(this), amountToPay),
            "USDT transfer failed"
        );

        Package memory selectedPackage = packages[selectedPlan];
        uint256 tokenAmount;
        if (selectedPackage.aiConnectTokenSend) {
            tokenAmount += selectedPackage.aiAmount;
        }

        Purchase memory newPurchase = Purchase({
            packageName: selectedPackage.packageName,
            packageIndex: selectedPlan,
            timestamp: block.timestamp,
            usdtAmount: selectedPackage.usdtAmount,
            aiAmount: tokenAmount,
            lockPeriod:block.timestamp + selectedPackage.tokenlockPeriod,
            stakeTime:0,
            isStake: false,
            aiTokensClaimed: false,
            package: true
        });

        userPurchasesPackage[msg_sender].push(newPurchase);
        emit PlanPurchased(msg_sender, selectedPlan, selectedPackage.usdtAmount, block.timestamp);
    }


function stake(uint256 _Package) external {
    require(_Package < nextPackageIndex, "Invalid Package");

    Package storage selectedPackage = packages[_Package];

    require(userPurchasesPackage[msg.sender][_Package].aiAmount > 0, "No AI tokens to stake");

    userPurchasesPackage[msg.sender][_Package].lockPeriod += selectedPackage.tokenStakePeriod;
    userPurchasesPackage[msg.sender][_Package].stakeTime = block.timestamp;
    userPurchasesPackage[msg.sender][_Package].isStake = true;
}



    function getRequiredPayment(uint256 selectedPlan, address user) public view returns (uint256) {
        uint256 existingIndex = getUserCurrentPackageIndex(user);
        uint256 amountToPay;

        if (existingIndex < selectedPlan) {
            uint256 priceDifference = packages[selectedPlan].usdtAmount - packages[existingIndex].usdtAmount;
            amountToPay = priceDifference;
        } else {
            amountToPay = packages[selectedPlan].usdtAmount;
        }

        return amountToPay;
    }

    function getUserCurrentPackageIndex(address user) public view returns (uint256) {
        uint256 purchaseCount = userPurchasesPackage[user].length;
        if (purchaseCount == 0) {
            return 0; 
        } else {
            return userPurchasesPackage[user][purchaseCount - 1].packageIndex;
        }
    }


function claim(uint256 _index) public {
    require(_index < userPurchasesPackage[msg.sender].length, "Invalid purchase index");

    Purchase storage userPurchase = userPurchasesPackage[msg.sender][_index];
    require(!userPurchase.aiTokensClaimed && userPurchase.package, "Tokens already claimed or not a valid package");

    require(block.timestamp >= userPurchase.lockPeriod, "Tokens are still locked");
    
    Package memory purchasedPackage = packages[userPurchase.packageIndex];
    uint256 rewardAmount = userPurchase.aiAmount; 

    if (userPurchase.isStake && purchasedPackage.stakerewardPercentage > 0) {
        rewardAmount = calculateStakeReward(userPurchase.aiAmount, purchasedPackage.stakerewardPercentage);
        userPurchase.isStake = true; 
    }

    require(
        purchasedPackage.aiConnect.transferFrom(owner, msg.sender, rewardAmount),
        "AI token transfer failed"
    );

    userPurchase.aiTokensClaimed = true;
    emit TokensClaimed(msg.sender, _index, rewardAmount);
}

function calculateStakeReward(uint256 stakedAmount, uint256 rewardPercentage) internal pure returns (uint256) {
    return (stakedAmount * rewardPercentage) / 100;
}


    function findEligiblePurchaseIndex(address user) internal view returns (uint256) {
        for (uint256 i = 0; i < userPurchasesPackage[user].length; i++) {
            if (!userPurchasesPackage[user][i].aiTokensClaimed && block.timestamp >= userPurchasesPackage[user][i].lockPeriod) {
                return i;
            }
        }
        revert("No eligible purchases to claim");
    }

    function getUserClaimableAmount(address user) public view returns (uint256) {
        uint256 totalClaimableAmount = 0;
        Purchase[] memory purchases = userPurchasesPackage[user];
        for (uint256 i = 0; i < purchases.length; i++) {
            if (!purchases[i].aiTokensClaimed && purchases[i].package && block.timestamp >= purchases[i].lockPeriod) {
                totalClaimableAmount += purchases[i].aiAmount;
            }
        }
        return totalClaimableAmount;
    }

    function userHasPackage(address _user, uint256 packageIndex) internal view returns (bool) {
        for (uint256 i = 0; i < userPurchasesPackage[_user].length; i++) {
            if (userPurchasesPackage[_user][i].packageIndex == packageIndex) {
                return true;
            }
        }
        return false;
    }

    function getUserPurchases(address user) public view returns (Purchase[] memory) {
        return userPurchasesPackage[user];
    }

    function getPackage(uint256 index) public view returns (string memory packageName, uint256 usdtAmount, uint256 aiAmount, address aiConnect, bool aiConnectTokenSend, uint256 directBonusPercentage, uint256 binaryBonusPercentage, uint256 maxPayoutAmount, uint256[] memory matchingPointsArray, uint256 packagePoints) {
        Package storage package = packages[index];
        return (package.packageName, package.usdtAmount, package.aiAmount, address(package.aiConnect), package.aiConnectTokenSend, package.directBonusPercentage, package.binaryBonusPercentage, package.maxPayout, package.matchingPointsArray, package.packagePoints);
    }

    function getTotalPackages() public view returns (uint256) {
        return nextPackageIndex;
    }

    function getUserPurchaseCount(address _user) public view returns (uint256) {
        return userPurchasesPackage[_user].length;
    }

    function getBalance() public view returns (uint256) {
        return IERC20(USDT).balanceOf(address(this)); 
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(oldOwner, _newOwner);
    }

    function setUSDT(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        address oldAddress = address(USDT);
        USDT = IERC20(_tokenAddress);
        emit USDTAddressUpdated(oldAddress, _tokenAddress);
    }
    /*


["Gold Package",
  "100000000000000000000",
  "100000000000000000000",
  "0xaE036c65C649172b43ef7156b009c6221B596B8b",
  true,
  "10",
  "5",
  "3000",
  [50, 150],
  "100",
  "60",
  "60",
  "200"]

    */
}