// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint256 private constant MAX_SUPPLY = 1_000_000 ether;

    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
