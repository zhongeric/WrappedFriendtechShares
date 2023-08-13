// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {IFriendTechSharesV1} from "./external/IFriendTechSharesV1.sol";

// AMM built ontop of friends.tech
contract Framm {
    address public friendtechSharesV1;
    IFriendTechSharesV1 FTS;

    // Storage copied from IFriendTechSharesV1
    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;
    // Framm storage
    mapping(address => address) public sharesSubjectToToken;

    constructor(address _friendtechSharesV1) {
        friendtechSharesV1 = _friendtechSharesV1;
        FTS = IFriendTechSharesV1(friendtechSharesV1);
    }

    function buyShares(address sharesSubject, uint256 amount) external payable {
        require(
            msg.value > FTS.getBuyPrice(sharesSubject, amount),
            "Framm: not enough for buy"
        );
        FTS.buyShares{value: msg.value}(sharesSubject, amount);
        sharesBalance[sharesSubject][msg.sender] += amount;
    }

    function sellShares(address sharesSubject, uint256 amount) external {
        require(
            amount <= sharesBalance[sharesSubject][msg.sender],
            "Framm: not enough shares"
        );
        sharesBalance[sharesSubject][msg.sender] -= amount;
        FTS.sellShares(sharesSubject, amount);
    }

    receive() external payable {}
}
