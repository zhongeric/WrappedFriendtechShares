// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC1155} from "solmate/src/tokens/ERC1155.sol";
import {IWrappedFriendtechSharesFactory} from "./interfaces/IWrappedFriendtechSharesFactory.sol";

contract WrappedFTS is ERC1155 {
    string public constant NAME_PREFIX = "WrappedFTS: ";
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "WrappedFTS: not minter");
        _;
    }

    constructor() {
        minter = msg.sender;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return "";
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyMinter {
        _mint(to, id, amount, data);
    }

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyMinter {
        _burn(from, id, amount);
    }

    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }
}
