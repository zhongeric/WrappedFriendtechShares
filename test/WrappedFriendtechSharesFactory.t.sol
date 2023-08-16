// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

import {Test} from "forge-std/Test.sol";
import {WrappedFriendtechSharesFactory} from "../src/WrappedFriendtechSharesFactory.sol";
import {FriendtechSharesV1} from "./FriendtechSharesV1.t.sol";
import {MockReentrant1155Receiver} from "./mock/MockReentrant1155Receiver.sol";

contract WrappedFriendtechSharesFactoryTest is Test {
    address alice = address(0xdead);
    address bob = address(0xbeef);
    address eve = address(0xbad);
    address protocolFeeDestination = address(0xaaaa);
    FriendtechSharesV1 public friendtechShares;
    WrappedFriendtechSharesFactory public wFTSFactory;
    uint256 aliceTokenId;
    uint256 bobTokenId;

    MockReentrant1155Receiver public mockReentrant1155Receiver;

    function setUp() public virtual {
        friendtechShares = new FriendtechSharesV1();
        friendtechShares.setFeeDestination(protocolFeeDestination);
        friendtechShares.setProtocolFeePercent(0.05 ether);
        friendtechShares.setSubjectFeePercent(0.05 ether);
        wFTSFactory = new WrappedFriendtechSharesFactory(
            address(friendtechShares)
        );

        vm.deal(eve, 100 ether);
        // create mock shareSubjects
        address[] memory shareSubjects = new address[](2);
        shareSubjects[0] = alice;
        shareSubjects[1] = bob;
        aliceTokenId = wFTSFactory.createToken(alice);
        assertEq(aliceTokenId, 1);
        assertEq(wFTSFactory.subjectToTokenId(alice), 1);
        assertEq(wFTSFactory.tokenIdToSubject(1), alice);

        bobTokenId = wFTSFactory.createToken(bob);
        assertEq(bobTokenId, 2);
        assertEq(wFTSFactory.subjectToTokenId(bob), 2);
        assertEq(wFTSFactory.tokenIdToSubject(2), bob);

        for (uint256 i = 0; i < shareSubjects.length; i++) {
            vm.deal(shareSubjects[i], 100 ether);
            vm.prank(shareSubjects[i]);
            // weird behavior that the first buy must be from the shareSubject
            // thus, there will always be one share owned by the shareSubject
            friendtechShares.buyShares{value: 0.1 ether}(shareSubjects[i], 1);
        }

        mockReentrant1155Receiver = new MockReentrant1155Receiver(alice);
    }

    function invariant_leShareSupply() external {
        assertLe(
            wFTSFactory.sharesSupply(alice),
            friendtechShares.sharesSupply(alice),
            "internal accounting of share supply not le"
        );
    }

    // add invariants for wFTSFactory solvency
    function invariant_alwaysRedeemable() external payable {
        if (wFTSFactory.balanceOf(eve, aliceTokenId) == 0) {
            return;
        }
        uint256 sharesSupply = wFTSFactory.sharesSupply(alice);
        assertLe(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            sharesSupply,
            "balance of eve not le to sharesSupply"
        );
        uint256 amount = wFTSFactory.balanceOf(eve, aliceTokenId);
        vm.prank(eve);
        wFTSFactory.sellShares(alice, amount);
    }

    function testBuyAndSellShares(uint8 amount) public {
        uint256 snapStart = vm.snapshot();
        uint256 sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        vm.assume(buyPrice < eve.balance);

        vm.startPrank(eve);
        wFTSFactory.buyShares{value: buyPrice}(alice, amount);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore + amount,
            "wrong shares balance"
        );
        assertEq(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            amount,
            "wrong token balance"
        );

        uint256 eveBalanceBefore = eve.balance;
        sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        uint256 sellPrice = friendtechShares.getSellPriceAfterFee(
            alice,
            amount
        );
        wFTSFactory.sellShares(alice, amount);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore - amount,
            "wrong shares balance"
        );
        assertEq(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            0,
            "wrong token balance"
        );
        assertEq(
            eve.balance - eveBalanceBefore,
            sellPrice,
            "native balance after sell"
        );
        vm.stopPrank();
        vm.revertTo(snapStart);
    }

    function testTransferTokens(uint8 amount) public {
        uint256 snapStart = vm.snapshot();
        uint256 sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        vm.assume(buyPrice < eve.balance);

        vm.startPrank(eve);
        wFTSFactory.buyShares{value: buyPrice}(alice, amount);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore + amount,
            "wrong shares balance"
        );
        sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        assertEq(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            amount,
            "wrong token balance"
        );
        // eve transfers tokens to bob
        wFTSFactory.safeTransferFrom(eve, bob, aliceTokenId, amount, "");
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore,
            "shares balance not equal after transfer"
        );
        assertEq(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            0,
            "wrong token balance"
        );
        assertEq(
            wFTSFactory.balanceOf(bob, aliceTokenId),
            amount,
            "wrong token balance"
        );

        // assume that this is not the last token, as that cannot be sold
        vm.assume(friendtechShares.sharesSupply(alice) > 1);
        vm.expectRevert("WrappedFriendtechSharesFactory: not enough tokens");
        wFTSFactory.sellShares(alice, amount);
        vm.stopPrank();

        // bob can sell the tokens
        vm.startPrank(bob);
        uint256 bobBalanceBefore = bob.balance;
        sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        uint256 sellPrice = friendtechShares.getSellPriceAfterFee(
            alice,
            amount
        );
        wFTSFactory.sellShares(alice, amount);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore - amount,
            "wrong shares balance"
        );
        assertEq(
            wFTSFactory.balanceOf(bob, aliceTokenId),
            0,
            "wrong token balance"
        );
        assertEq(
            bob.balance - bobBalanceBefore,
            sellPrice,
            "native balance after sell"
        );
        vm.stopPrank();
        vm.revertTo(snapStart);
    }

    function testTransferFromTokens() public {
        uint256 snapStart = vm.snapshot();
        uint256 amount = 1;
        vm.startPrank(eve);
        uint256 sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        wFTSFactory.buyShares{value: buyPrice}(alice, amount);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore + amount,
            "wrong shares balance"
        );
        sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        assertEq(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            amount,
            "wrong token balance"
        );
        wFTSFactory.setApprovalForAll(bob, true);
        vm.stopPrank();

        vm.prank(bob);
        wFTSFactory.safeTransferFrom(eve, bob, aliceTokenId, amount, "");
        // eve cannot sell the tokens
        vm.prank(eve);
        vm.expectRevert("WrappedFriendtechSharesFactory: not enough tokens");
        wFTSFactory.sellShares(alice, amount);

        vm.startPrank(bob);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore,
            "shares balance not equal after transfer"
        );
        assertEq(
            wFTSFactory.balanceOf(eve, aliceTokenId),
            0,
            "wrong token balance"
        );
        assertEq(
            wFTSFactory.balanceOf(bob, aliceTokenId),
            amount,
            "wrong token balance after transfer"
        );
        uint256 bobBalanceBefore = bob.balance;
        sharesSupplyBefore = wFTSFactory.sharesSupply(alice);
        uint256 sellPrice = friendtechShares.getSellPriceAfterFee(
            alice,
            amount
        );
        wFTSFactory.sellShares(alice, amount);
        assertEq(
            wFTSFactory.sharesSupply(alice),
            sharesSupplyBefore - amount,
            "wrong shares balance"
        );
        assertEq(
            wFTSFactory.balanceOf(bob, aliceTokenId),
            0,
            "wrong token balance"
        );
        assertEq(
            bob.balance - bobBalanceBefore,
            sellPrice,
            "native balance after sell"
        );
        vm.stopPrank();
        vm.revertTo(snapStart);
    }

    function testBuyTokensNoReentrancy() public {
        vm.deal(address(mockReentrant1155Receiver), 100 ether);
        vm.startPrank(address(mockReentrant1155Receiver));
        uint256 amount = 1;
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        vm.expectRevert("WrappedFriendtechSharesFactory: reentrant call");
        wFTSFactory.buyShares{value: buyPrice}(alice, amount);
        vm.stopPrank();
    }
}
