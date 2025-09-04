// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SmartContractWallet{
    address payable public owner;

    mapping(uint => address) public owners;
    uint ownerCount;

    mapping (address => uint) public allowance;
    mapping (address => bool) public isAllowedToSpend;

    constructor(){
        owner = payable(msg.sender);
        owners[ownerCount] = msg.sender;
        ownerCount++;
    }

    function checkBalance() public view returns ( uint ) {
        return address(this).balance;
    }

    //Good for sending to EOAs (users)
    //user wallet only require a max of 2300 gas unlike a contract that can need more
    /*
    function sendMoney(address payable _to, uint _amount) public payable {
        uint balanceBeforeTransfer = address(this).balance;

        require(msg.sender == owner, "Only owner can send money!!");
        require(balanceBeforeTransfer >= _amount, "Insufficient balance!!");
        
        _to.transfer(_amount);
    }
    */

    //Allows you to call EOAs and Contracts safely
    //If _to is an EOA, _payload is just ignored
    //If _to is a contract, _payload can be something like encoded function call data
    function transferMoney(address payable _to, uint _amount, bytes memory _payload) public payable returns(bytes memory){
        //require(msg.sender == owner, "Only owner can send money!!");
        require(address(this).balance >= _amount, "Insufficient balance!!");
        if(msg.sender != owner)
        {
            require(isAllowedToSpend[msg.sender], "You are not allowed to spend!!");
            require(allowance[msg.sender] >= _amount, "You have exceeded your spending limit!!");

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Aborting!! call was not successful!");
        return returnData;
    }

    function setAllowance(address _spender, uint _amount) public {
        require(msg.sender == owner, "You are not allowed, Aborting!!");

        allowance[_spender] = _amount;

        if(_amount > 0){
            isAllowedToSpend[_spender] = true;
        }else {
            isAllowedToSpend[_spender] = false;
        }
    }

    function setRecovery(address payable _backUpAddress) public{
        require(msg.sender == owner, "Only current owner can add backup owner!");
        require(ownerCount < 3, "You have reached the maximum number of owners!!");
        require(_backUpAddress != address(0), "Invalid address!");

        for(uint i = 0; i < ownerCount; i++){
            require(_backUpAddress != owners[i], "Address already exists!!");
        }

        owners[ownerCount] = _backUpAddress;
        ownerCount++;
    }

    receive() external payable { }
    fallback() external payable { }
}
