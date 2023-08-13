// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IFramm} from "./interfaces/IFramm.sol";

contract UserToken is ERC20 {
    address public minter;
    bool public locked;
    event NameSymbolChanged(string name, string symbol);

    modifier onlyMinter() {
        require(msg.sender == minter, "UserToken: not minter");
        _;
    }

    modifier reentrancyLock() {
        require(!locked, "UserToken: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, 18) {
        minter = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function changeNameSymbol(
        string memory _name,
        string memory _symbol
    ) external onlyMinter {
        name = _name;
        symbol = _symbol;
        emit NameSymbolChanged(name, symbol);
    }
}
