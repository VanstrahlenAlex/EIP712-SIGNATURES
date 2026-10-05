// SPDX-License-Identifier: MIT

pragma solidity ^0.8.36;

import {PermitToken} from "./PermitToken.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract GaslessVault is EIP712, Nonces {
    
	PermitToken public immutable token;

	mapping(address deposit => uint256) public vaultBalanceOf;

	bytes32 public constant WITHDRAW_TYPESHASH = keccak256("WithdrawAuthorization(address owner, address to, uint256 amount, uint256 nonce, uint256 deadline)");

	//Errors
	error DeadlineExpried();
	error InvalidWithdrawSignature();
	error InsufficientVaultBalance();
	error ZeroAmount();

	event Deposited(address indexed depositor, uint256 amount);
	event Withdrawn(address indexed owner, address indexed to, uint256 amount);
	
	constructor(PermitToken _token) EIP712("GaslessVault", "1") {
		token = _token;
	}

	function deposit(uint256 amount) external { 
		if(amount == 0) revert ZeroAmount();
		vaultBalanceOf[msg.sender] += amount;
		token.safeTransferFrom(msg.sender, address(this), amount);
		
		emit Deposited(msg.sender, amount);
	}

	function DOMAIN_SEPARATOR() external view returns (bytes32) {
		return _domainSeparatorV4();
	}


}