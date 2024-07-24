// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleMultiSig {
    address[] public owners;
    uint256 public required;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 1, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid number of required confirmations");

        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            owners.push(_owners[i]);
        }
        required = _required;
    }

    function submitTransaction(address to) public payable {
        // uint256 txIndex = transactions.length;

        transactions.push(Transaction({
            to: to,
            value: msg.value,
            executed: false
        }));
    }

    function confirmTransaction(uint256 txIndex) public {
        require(isOwner(msg.sender), "Not owner");
        require(transactions[txIndex].to != address(0), "Transaction does not exist");
        require(!confirmations[txIndex][msg.sender], "Already confirmed");

        confirmations[txIndex][msg.sender] = true;

        if (getConfirmationCount(txIndex) >= required) {
            executeTransaction(txIndex);
        }
    }

    function executeTransaction(uint256 txIndex) public payable {
        require(transactions[txIndex].to != address(0), "Transaction does not exist");
        require(!transactions[txIndex].executed, "Transaction already executed");
        require(getConfirmationCount(txIndex) >= required, "Not enough confirmations");

        Transaction storage txn = transactions[txIndex];
        txn.executed = true;

        (bool success,) = txn.to.call{value: txn.value}("");
        require(success, "Transaction failed");
    }

    function getConfirmationCount(uint256 txIndex) public view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[txIndex][owners[i]]) {
                count += 1;
            }
        }
    }

    function isOwner(address account) internal view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {}
}
