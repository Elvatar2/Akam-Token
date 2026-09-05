// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AKAMToken is ERC20, Ownable {
    constructor() ERC20("AKAM Token", "AKAM") Ownable(msg.sender) {
        _mint(msg.sender, 400000000 * 10 ** decimals());
    }
}
