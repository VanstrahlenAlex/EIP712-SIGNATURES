// SPDX-License-Identifier: MIT

pragma solidity ^0.8.36;

import {PermitToken} from "./PermitToken.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract GaslessVault is EIP712, Nonces {
    
}