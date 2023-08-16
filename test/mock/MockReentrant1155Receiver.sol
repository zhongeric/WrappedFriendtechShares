// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

import {IWrappedFriendtechSharesFactory} from "../../src/interfaces/IWrappedFriendtechSharesFactory.sol";
import {ERC1155TokenReceiver} from "solmate/src/tokens/ERC1155.sol";

contract MockReentrant1155Receiver is ERC1155TokenReceiver {
    address public shareSubject;

    constructor(address _shareSubject) {
        shareSubject = _shareSubject;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns (bytes4) {
        IWrappedFriendtechSharesFactory(msg.sender).buyShares(shareSubject, 1);
        return this.onERC1155Received.selector;
    }
}
