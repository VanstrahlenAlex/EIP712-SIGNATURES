// SPDX-License-Identifier: MIT

pragma solidity ^0.8.36;

import {Test, console2} from "forge-std/Test.sol";
import {GaslessVault} from "../src/GaslessVault.sol";
import {PermitToken} from "../src/PermitToken.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// @title EIP712Test - Comprehensive tests for EIP-712 Typed Structured Data Signing
// @notice These tests demonstrate the FULL EIP-712 signing flow step by step, using OpenZeppelin's EIP712 implementation.

contract EIP712Test is Test {
	PermitToken token;
	GaslessVault vault;

	//ACTORS
	uint256 constant ALICE_PK = 0xA11CE;
	address ALICE; 

	uint256 constant BOB_PK = 0x1B0B;
	address BOB; 

	address RELAYER = makeAddr("relayer");
	address OWNER = makeAddr("owner");

	//CONSTANTS
	uint256 constant INITIAL_SUPPLY = 1_000_000e18;
	uint256 constant ALICE_AMOUNT = 10_000e18;

	/// @dev The EIP-712 Permit typehash (same constant OZ uses internally)
	bytes32 constant PERMIT_TYPEHASH = keccak256("Permit(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)");

	function setUp() public {
		ALICE = vm.addr(ALICE_PK);
		BOB = vm.addr(BOB_PK);

		vm.startPrank(OWNER);
		token = new PermitToken("PermitToken", "PTK", INITIAL_SUPPLY);
		vault = new GaslessVault(token);

		token.transfer(ALICE, ALICE_AMOUNT);
		vm.stopPrank();
	}
}