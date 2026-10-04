// SPDX-License-Identifier: MIT

pragma solidity ^0.8.36;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract PermitToken is ERC20, ERC20Permit {
    constructor(string memory _name, string memory _symbol, uint256 initialSupply) ERC20(_name, _symbol) ERC20Permit(_name) {
        
    }
}