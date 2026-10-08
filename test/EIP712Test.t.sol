// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

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

	// ===========================================================
	// 1: EIP-712 FUNDAMENTALS
	// ===========================================================

	function test_domainSeparatorComputedCorrectly() public view { 
		bytes32 domainTypeHash = keccak256("EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)");

		bytes32 expected = keccak256(
			abi.encode(
				domainTypeHash,
				keccak256("PermitToken"),
				keccak256("1"),
				block.chainid,
				address(token)
			)
		);

		assertEq(token.DOMAIN_SEPARATOR(), expected, "Domain separator mismatch");
	}

	function test_tokenAndVaultHaveDifferentDomainSeparators() public view {
		//The token's domain separator uses name="PermitToken" and address(token)
		//The vault's domain separator uses name="GaslessVault" and address(vault)
		//They are DIFERENT, so signatures cannot be replayed across them
		assertTrue(
			token.DOMAIN_SEPARATOR() != vault.DOMAIN_SEPARATOR(),
			"Token and vault should have different domain separators"
		);
	}

	//===============================================================
	// 2: ERC-2612 PERMIT - Gasless Approvals
	//===============================================================

	function test_permitSetAllowance() public {
		uint256 amount = 1000e18;
		uint256 deadline = block.timestamp + 1 hours;
		uint256 nonce = token.nonces(ALICE);

		bytes32 structHash = keccak256(
			abi.encode(
				PERMIT_TYPEHASH,
				ALICE,
				address(vault),
				amount,
				nonce,
				deadline
			)
		);

		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, digest);

		vm.prank(RELAYER);
		token.permit(ALICE, address(vault), amount, deadline, v, r, s);

		assertEq(token.allowance(ALICE, address(vault)), amount);
		
	}

	// ===============================================================
	// 4: GASLESS VAULT WITHDRAWLS (Custom EIP-712 Struct)
	//===============================================================
	// This section uses a DIFFERENT EIP-712 struct: WithdrawAuthorization. 

	function test_withdrawBySigTransferTokens() public {

		uint256 depositAmount = 500e18;
		uint256 withdrawAmount = 200e18;
		uint256 deadline = block.timestamp + 1 hours;

		_depositToVault(ALICE, ALICE_PK, depositAmount); 

		(uint8 v, bytes32 r, bytes32 s) = _signWithdraw(ALICE, ALICE_PK, BOB, withdrawAmount, 0, deadline);

		vm.prank(RELAYER);
		vault.withdrawBySig(ALICE, BOB, withdrawAmount, deadline, v, r, s);
		assertEq(vault.vaultBalanceOf(ALICE), depositAmount - withdrawAmount);
		assertEq(token.balanceOf(BOB), withdrawAmount);
		
	}


	function _depositToVault(address owner, uint256 ownerPk, uint256 amount) internal {
		uint256 nonce = token.nonces(owner);
		uint256 deadline = block.timestamp + 1 hours; 

		(uint8 v, bytes32 r, bytes32 s) = _signPermit(owner, ownerPk, address(vault), amount, nonce, deadline);
		vault.depositWithPermit(owner, amount, deadline, v, r, s);

	}

	function _signPermit(address owner, uint256 signerPk, address spender, uint256 value, uint256 nonce, uint256 deadline) internal view returns (uint8 v, bytes32 r, bytes32 s) {
		bytes32 strucHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), strucHash));

		(v, r, s) = vm.sign(signerPk, digest); 
	}

	function _signWithdraw(address owner, uint256 signerPk, address to, uint256 amount, uint256 nonce, uint256 deadline) internal view returns (uint8 v, bytes32 r, bytes32 s) {
		bytes32 structHash = keccak256(abi.encode(vault.WITHDRAW_TYPESHASH(), owner, to, amount, nonce, deadline));

		bytes32 digest = keccak256(
			abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), structHash)
		);

		(v, r, s) = vm.sign(signerPk, digest);
	}

	
}