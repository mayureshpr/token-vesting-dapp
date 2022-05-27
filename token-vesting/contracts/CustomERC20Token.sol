// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 *@title Basic custom token code that we will use for testing
 */
contract CustomToken is ERC20 {

    constructor( 
        string memory name, 
        string memory symbol,
        uint256 tokenSupply) ERC20(name, symbol) {
            _mint(msg.sender, tokenSupply * (10 ** uint256(decimals())));
    }
}