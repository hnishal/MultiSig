// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract MultiSig {
    using Counters for Counters.Counter;
    Counters.Counter pendingTransactions;
    address public deployer;
    address public treasuryAddress;
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationRequired;
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transaction;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transaction.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transaction[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _numConfirmations) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmations > 0 && _numConfirmations <= _owners.length,
            "invalid no of confirmation"
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid address");
            require(!isOwner[owner], "owners not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationRequired = _numConfirmations;
        deployer = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address _to, uint256 _value)
        public
        payable
        onlyOwner
    {
        require(_value == msg.value, "insufficiet funds transfered");
        uint256 txIndex = transaction.length;
        transaction.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );
        pendingTransactions.increment;
        emit SubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    function signTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        transaction[_txIndex].numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    //implement the whole treasury thing
    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(
            transaction[_txIndex].numConfirmations >= numConfirmationRequired,
            "Cannot Execute tx"
        );
        require(
            address(this).balance >= transaction[_txIndex].value,
            "not enough funds"
        );
        (bool sent, ) = transaction[_txIndex].to.call{
            value: transaction[_txIndex].value
        }("");
        require(sent, "Transaction failed");
        pendingTransactions.decrement;
        transaction[_txIndex].executed = true;
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(isConfirmed[_txIndex][msg.sender], "tx not Confirmed");

        transaction[_txIndex].numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTotalTransactionCount() public view returns (uint256) {
        return transaction.length;
    }

    function getpendingTransaxtion() public view returns (uint256) {
        return pendingTransactions.current();
    }

    function getTransactionStatus(uint256 _txIndex) public view returns (bool) {
        return transaction[_txIndex].executed;
    }

    function retSigned(uint256 _txIndex, address _owner)
        public
        view
        returns (bool)
    {
        return isConfirmed[_txIndex][_owner];
    }

    function getDeployers() public view returns (address) {
        return deployer;
    }
}
