// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {WrappedFriendtechSharesFactory} from '../../src/WrappedFriendtechSharesFactory.sol';

// inspired by https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw
contract Handler is CommonBase, StdCheats, StdUtils {
    WrappedFriendtechSharesFactory public wFTSFactory;

    constructor(address _wFTSFactory) {
        wFTSFactory = new WrappedFriendtechSharesFactory(_wFTSFactory);
    }

    function createToken(address sharesSubject) public {
        wFTSFactory.createToken(sharesSubject);
    }

    function buyShares(address sharesSubject, uint256 amount) public payable {
        vm.assume(wFTSFactory.subjectToTokenId(sharesSubject) != 0);
        wFTSFactory.buyShares{value: msg.value}(sharesSubject, amount);
    }

    function sellShares(address sharesSubject, uint256 amount) public {
        uint256 tokenId = wFTSFactory.subjectToTokenId(sharesSubject);
        vm.assume(tokenId != 0);
        vm.assume(wFTSFactory.balanceOf(msg.sender, tokenId) >= amount);
        wFTSFactory.sellShares(sharesSubject, amount);
    }
}