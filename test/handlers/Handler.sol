// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {IWrappedFriendtechSharesFactory} from "../../src/interfaces/IWrappedFriendtechSharesFactory.sol";
import {IFriendTechSharesV1} from "../../src/external/IFriendTechSharesV1.sol";

struct AddressSet {
    address[] addrs;
    mapping(address => bool) saved;
}

// taken from by https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw
library LibAddressSet {
    function rand(AddressSet storage s, uint256 seed) internal view returns (address) {
        if (s.addrs.length > 0) {
            return s.addrs[seed % s.addrs.length];
        } else {
            // default to alice
            return address(0xdead);
        }
    }

    function add(AddressSet storage s, address addr) internal {
        if (!s.saved[addr]) {
            s.addrs.push(addr);
            s.saved[addr] = true;
        }
    }

    function contains(AddressSet storage s, address addr) internal view returns (bool) {
        return s.saved[addr];
    }

    function count(AddressSet storage s) internal view returns (uint256) {
        return s.addrs.length;
    }

    function forEach(AddressSet storage s, function(address) external returns (address) func) internal {
        for (uint256 i; i < s.addrs.length; ++i) {
            func(s.addrs[i]);
        }
    }

    function reduce(AddressSet storage s, uint256 acc, function(uint256,address) external returns (uint256) func)
        internal
        returns (uint256)
    {
        for (uint256 i; i < s.addrs.length; ++i) {
            acc = func(acc, s.addrs[i]);
        }
        return acc;
    }
}

// inspired by https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw
contract Handler is CommonBase, StdCheats, StdUtils {
    using LibAddressSet for AddressSet;

    IWrappedFriendtechSharesFactory public wFTSFactory;
    IFriendTechSharesV1 public friendtechSharesV1;

    AddressSet internal _actors;
    address public sharesSubject = address(0xffff);

    constructor(address _wFTSFactory, address _friendtechSharesV1) {
        wFTSFactory = IWrappedFriendtechSharesFactory(_wFTSFactory);
        friendtechSharesV1 = IFriendTechSharesV1(_friendtechSharesV1);
        deal(address(this), 1_000_000 ether);
        deal(sharesSubject, 1 ether);

        wFTSFactory.createToken(sharesSubject);
        vm.prank(sharesSubject);
        friendtechSharesV1.buyShares{value: 0.01 ether}(sharesSubject, 1);
    }

    modifier createActor() {
        _actors.add(msg.sender);
        _;
    }

    function buyShares(uint256 actorSeed, uint8 amount) public payable createActor {
        if (amount == 0) {
            return;
        }
        address caller = _actors.rand(actorSeed);
        // asssume caller is EOA just to make sure they can receive the ETH from the sell.
        // this is a limitation of the friendstechSharesV1 contract
        if(caller.code.length == 0) {
            return;
        }
        uint256 buyPrice = friendtechSharesV1.getBuyPriceAfterFee(sharesSubject, amount);
        buyPrice = bound(buyPrice, 1, address(this).balance);
        _pay(caller, buyPrice);
        vm.prank(caller);
        wFTSFactory.buyShares{value: buyPrice}(sharesSubject, amount);
    }

    function sellShares(uint256 actorSeed, uint8 amount) public createActor {
        address caller = _actors.rand(actorSeed);
        // asssume caller is EOA just to make sure they can receive the ETH from the sell.
        // this is a limitation of the friendstechSharesV1 contract
        if(caller.code.length == 0) {
            return;
        }
        uint256 tokenId = wFTSFactory.subjectToTokenId(sharesSubject);
        if (wFTSFactory.balanceOf(caller, tokenId) == 0) {
            return;
        }
        amount = uint8(bound(amount, 1, wFTSFactory.balanceOf(caller, tokenId)));
        uint256 ethToReceive = friendtechSharesV1.getSellPriceAfterFee(sharesSubject, amount);
        vm.startPrank(caller);
        wFTSFactory.sellShares(sharesSubject, amount);
        _pay(address(this), ethToReceive);
        vm.stopPrank();
    }

    function safeTransferFrom(uint256 fromSeed, uint256 toSeed, uint256 amount) public createActor {
        address from = _actors.rand(fromSeed);
        address to = _actors.rand(toSeed);
        uint256 tokenId = wFTSFactory.subjectToTokenId(sharesSubject);
        if (wFTSFactory.balanceOf(from, tokenId) == 0) {
            return;
        }
        amount = bound(amount, 0, wFTSFactory.balanceOf(from, tokenId));
        vm.prank(from);
        wFTSFactory.safeTransferFrom(from, to, tokenId, amount, "");
    }

    receive() external payable {}

    // helper functions
    function _pay(address to, uint256 amount) internal {
        (bool s,) = to.call{value: amount}("");
        require(s, "pay() failed");
    }

    function actors() external view returns (address[] memory) {
        return _actors.addrs;
    }

    function forEachActor(function(address) external returns (address) func) public {
        return _actors.forEach(func);
    }

    function reduceActors(uint256 acc, function(uint256,address) external returns (uint256) func)
        public
        returns (uint256)
    {
        return _actors.reduce(acc, func);
    }
}
