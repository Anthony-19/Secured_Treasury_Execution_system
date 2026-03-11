// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {IERC20} from "src/interfaces/IERC20.sol";
import {Errors} from "src/libraries/Errors.sol";

contract Treasury {
    IERC20 public token;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    mapping(address => uint) public balances;
    uint public totalBalance;
    event Deposit(address indexed sender, uint amount);
    event Withdrawal(address indexed sender, uint amount);

    function deposit(uint _amount) external {
        if (msg.sender == address(0)) revert Errors.ZeroAddress();

        if (_amount == 0) revert Errors.InvalidAmount(_amount);

        balances[msg.sender] += _amount;
        totalBalance += _amount;
        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert Errors.TokenTransferFailed();
        }
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint _amount, address _sender) external {
        if (msg.sender == address(0)) revert Errors.ZeroAddress();

        if (msg.sender != address(this))
            revert Errors.UnauthorizedCaller(msg.sender);

        if (_amount == 0) revert Errors.InvalidAmount(_amount);

        if (totalBalance < _amount) {
            revert Errors.TreasuryInsufficientBalance(totalBalance, _amount);
        }

        balances[msg.sender] -= _amount;
        totalBalance -= _amount;
        if (!token.transfer(_sender, _amount)) {
            revert Errors.TokenTransferFailed();
        }
        emit Withdrawal(msg.sender, _amount);
    }

    function proposalWithdrawal(address _sender, uint _amount) external {
        if (msg.sender == address(0)) revert Errors.ZeroAddress();

        if (msg.sender != address(this))
            revert Errors.UnauthorizedCaller(msg.sender);
        if (_amount == 0) revert Errors.InvalidAmount(_amount);
        if (totalBalance < _amount) {
            revert Errors.TreasuryInsufficientBalance(totalBalance, _amount);
        }
        totalBalance -= _amount;
        require(token.transfer(_sender, _amount), "Transfer failed");
        emit Withdrawal(msg.sender, _amount);
    }

   
    receive() external payable {
       if (msg.value == 0) revert Errors.InvalidAmount(msg.value);
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
       if (msg.value == 0) revert Errors.InvalidAmount(msg.value);
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
