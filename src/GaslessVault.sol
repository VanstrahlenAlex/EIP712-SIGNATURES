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
		token.transferFrom(msg.sender, address(this), amount);
		
		emit Deposited(msg.sender, amount);
	}

	function depositWithPermit(
		address owner,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		if (amount == 0) revert ZeroAmount();

		// Step 1: Use the permit signature to approve this vault.
		token.permit(owner, address(this), amount, deadline, v, r, s);

		// Step 2: Deposit the tokens in the user's vault.
		vaultBalanceOf[owner] += amount;

		// Step 3: Transfer the tokens from the owner to this contract.
		token.transferFrom(owner, address(this), amount);
		
		emit Deposited(owner, amount);
	}

	function withdraw(address to, uint256 amount) external {
		if (amount == 0) revert ZeroAmount();
		if (vaultBalanceOf[msg.sender] < amount) revert InsufficientVaultBalance();

		vaultBalanceOf[msg.sender] -= amount;
		token.transfer(to, amount);
		emit Withdrawn(msg.sender, to, amount);
	}




	function DOMAIN_SEPARATOR() external view returns (bytes32) {
		return _domainSeparatorV4();
	}


}