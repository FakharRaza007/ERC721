// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() {
        _transferOwnership(msg.sender);
    }

   
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TradingStats is Ownable {
    
    struct TradeStatistics {
        int256 totalNetProfit;
        int256 grossProfit;
        int256 grossLoss;
        int256 maxDrawdown;
        int256 profitFactor;
        int256 numberOfTrades;
        int256 winRate;
        int256 averageTrade;
        int256 averageWinningTrade;
        int256 averageLosingTrade;
        int256 ratioAvgWinningLosing;
        int256 maxConsecutiveWinners;
        int256 minConsecutiveLosers;
        int256 largestWinningTrade;
        int256 largestLosingTrade;
        int256 riskOfRuin;
    }

    //  TradeStatistics[] private stats;
    mapping(uint=>TradeStatistics) stats ;
    uint[] public ids;
    
    event TradeStatisticsRegistered(uint indexed id, TradeStatistics stats);
    event TradeStatisticsUpdated(uint indexed id, TradeStatistics stats);
    event TradeStatisticsDeleted(uint indexed id);

    modifier onlyRegistered(uint id) {
        require(stats[id].numberOfTrades != 0, "Stats not registered");
        _;
    }

    function registerStats(TradeStatistics memory _stats) public onlyOwner {
        require(
            _stats.numberOfTrades >= 0,
            "Invalid trade statistics"
        );

        uint newId = ids.length+1;
        ids.push(newId);
        stats[newId] = _stats;
        emit TradeStatisticsRegistered(newId, _stats);
    }

    function viewStats(uint id) public view returns (TradeStatistics memory) {
        return stats[id];
    }

    function updateStats(uint id, TradeStatistics memory _stats) public onlyOwner onlyRegistered(id) {
        stats[id] = _stats;
        emit TradeStatisticsUpdated(id, _stats);
    }

    function deleteStats(uint id) public onlyOwner onlyRegistered(id) {
        delete stats[id];
        emit TradeStatisticsDeleted(id);
    }

    function getTotalTradeStatistics() public view returns (uint) {
        return ids.length;
    }
}


//["323","54545","3242","4343","5453","5343","70000","4000","12000","4300","550","23232","1232","877976","326236","4545"]