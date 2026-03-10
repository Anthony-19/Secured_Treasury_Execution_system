// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;    
import {IERC20} from "src/interfaces/IERC20.sol";

contract Treasury {
    IERC20 public token;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    mapping (address => uint) public balances;
    uint public totalBalance;
    event Deposit(address indexed sender, uint amount);
    event Withdrawal(address indexed sender, uint amount);

   

    function deposit(uint _amount) external{
        require(msg.sender != address(0));
        require(_amount > 0, "Deposit must be greater than 0");
        balances[msg.sender] += _amount;
        totalBalance += _amount;
         require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
         emit Deposit(msg.sender, _amount);
    }

     function withdraw(uint _amount, address _sender) external{
        require(msg.sender != address(0), "This is an Address zero");
        require(_amount > 0, "withdrawal must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        totalBalance -= _amount;
        require(token.transfer(_sender, _amount), "Transfer failed");
        emit Withdrawal(msg.sender, _amount);
    }

    function proposalWithdrawal(uint _amount, address _sender) external{
        require(msg.sender != address(0), "This is address zero");
        require(msg.sender == address(this), "You cant call this function");
        require(_amount > 0, "withdrawal must be greater than 0");
        require(totalBalance >= _amount, "Insufficient balance in treasury");
        totalBalance -= _amount;
        require(token.transfer(_sender, _amount), "Transfer failed");
        emit Withdrawal(msg.sender, _amount);

    }

    receive() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    fallback() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}