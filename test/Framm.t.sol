// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Framm} from "../src/Framm.sol";
import {WrappedFTS} from "../src/WrappedFTS.sol";
import {FriendtechSharesV1} from "./FriendtechSharesV1.t.sol";

contract FrammTest is Test {
    address alice = address(0xdead);
    address bob = address(0xbeef);
    address eve = address(0xbad);
    address protocolFeeDestination = address(0xaaaa);
    FriendtechSharesV1 friendtechShares;
    Framm framm;
    WrappedFTS wFTS;
    uint256 aliceTokenId;
    uint256 bobTokenId;

    function setUp() public virtual {
        friendtechShares = new FriendtechSharesV1();
        wFTS = new WrappedFTS();
        friendtechShares.setFeeDestination(protocolFeeDestination);
        friendtechShares.setProtocolFeePercent(0.05 ether);
        friendtechShares.setSubjectFeePercent(0.05 ether);
        framm = new Framm(address(friendtechShares));

        vm.deal(eve, 100 ether);
        // create mock shareSubjects
        address[] memory shareSubjects = new address[](2);
        shareSubjects[0] = alice;
        shareSubjects[1] = bob;
        aliceTokenId = framm.createToken(alice);
        assertEq(aliceTokenId, 1);
        assertEq(framm.sharesSubjectToTokenId(alice), 1);
        assertEq(framm.tokenIdtoSharesSubject(1), alice);

        bobTokenId = framm.createToken(bob);
        assertEq(bobTokenId, 2);
        assertEq(framm.sharesSubjectToTokenId(bob), 2);
        assertEq(framm.tokenIdtoSharesSubject(2), bob);

        for (uint256 i = 0; i < shareSubjects.length; i++) {
            vm.deal(shareSubjects[i], 100 ether);
            vm.prank(shareSubjects[i]);
            // weird behavior that the first buy must be from the shareSubject
            // thus, there will always be one share owned by the shareSubject
            friendtechShares.buyShares{value: 0.1 ether}(shareSubjects[i], 1);
        }
    }

    function invariant_leShareSupply() external {
        assertLe(
            framm.sharesSupply(alice),
            friendtechShares.sharesSupply(alice),
            "internal accounting of share supply not le"
        );
    }

    // add invariants for framm solvency
    // function xinvariant_alwaysPurchasable() external payable {
    //     if (bobToken.balanceOf(address(this)) == 0) {
    //         return;
    //     }
    //     uint256 amount = 1;
    //     uint256 sharesSupplyBefore = framm.sharesSupply(bob);
    //     uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(bob, amount);
    //     // for gas
    //     vm.deal(address(this), buyPrice + 1 ether);
    //     framm.buyShares{value: buyPrice}(bob, amount);
    //     assertEq(
    //         framm.sharesSupply(bob),
    //         sharesSupplyBefore + amount,
    //         "wrong shares balance"
    //     );
    //     assertEq(
    //         bobToken.balanceOf(address(this)),
    //         amount,
    //         "wrong token balance"
    //     );
    // }

    function testBuyAndSellShares(uint256 amount) public {
        uint256 snapStart = vm.snapshot();
        vm.assume(amount > 0 && amount < 20);
        vm.startPrank(eve);
        uint256 sharesSupplyBefore = framm.sharesSupply(alice);
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        framm.buyShares{value: buyPrice}(alice, amount);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore + amount,
            "wrong shares balance"
        );
        assertEq(
            wFTS.balanceOf(eve, aliceTokenId),
            amount,
            "wrong token balance"
        );

        uint256 eveBalanceBefore = eve.balance;
        sharesSupplyBefore = framm.sharesSupply(alice);
        uint256 sellPrice = friendtechShares.getSellPriceAfterFee(
            alice,
            amount
        );
        framm.sellShares(alice, amount);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore - amount,
            "wrong shares balance"
        );
        assertEq(wFTS.balanceOf(eve, aliceTokenId), 0, "wrong token balance");
        assertEq(
            eve.balance - eveBalanceBefore,
            sellPrice,
            "native balance after sell"
        );
        vm.stopPrank();
        vm.revertTo(snapStart);
    }

    function testTransferTokens(uint256 amount) public {
        uint256 snapStart = vm.snapshot();
        vm.assume(amount > 0 && amount < 50);
        vm.startPrank(eve);
        uint256 sharesSupplyBefore = framm.sharesSupply(alice);
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        framm.buyShares{value: buyPrice}(alice, amount);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore + amount,
            "wrong shares balance"
        );
        sharesSupplyBefore = framm.sharesSupply(alice);
        assertEq(
            wFTS.balanceOf(eve, aliceTokenId),
            amount,
            "wrong token balance"
        );
        // eve transfers tokens to bob
        wFTS.safeTransferFrom(eve, bob, amount, aliceTokenId, "");
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore,
            "shares balance not equal after transfer"
        );
        assertEq(wFTS.balanceOf(eve, aliceTokenId), 0, "wrong token balance");
        assertEq(
            wFTS.balanceOf(bob, aliceTokenId),
            amount,
            "wrong token balance"
        );
        // eve cannot sell the tokens
        vm.expectRevert("Framm: not enough tokens");
        framm.sellShares(alice, amount);
        vm.stopPrank();

        // bob can now sell the tokens
        vm.startPrank(bob);
        uint256 bobBalanceBefore = bob.balance;
        sharesSupplyBefore = framm.sharesSupply(alice);
        uint256 sellPrice = friendtechShares.getSellPriceAfterFee(
            alice,
            amount
        );
        framm.sellShares(alice, amount);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore - amount,
            "wrong shares balance"
        );
        assertEq(wFTS.balanceOf(bob, aliceTokenId), 0, "wrong token balance");
        assertEq(
            bob.balance - bobBalanceBefore,
            sellPrice,
            "native balance after sell"
        );
        vm.stopPrank();
        vm.revertTo(snapStart);
    }

    function testTransferFromTokens(uint256 amount) public {
        uint256 snapStart = vm.snapshot();
        vm.assume(amount > 0 && amount < 50);
        vm.startPrank(eve);
        uint256 sharesSupplyBefore = framm.sharesSupply(alice);
        uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(alice, amount);
        framm.buyShares{value: buyPrice}(alice, amount);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore + amount,
            "wrong shares balance"
        );
        sharesSupplyBefore = framm.sharesSupply(alice);
        assertEq(
            wFTS.balanceOf(eve, aliceTokenId),
            amount,
            "wrong token balance"
        );
        wFTS.setApprovalForAll(bob, true);
        vm.stopPrank();

        vm.prank(bob);
        wFTS.safeTransferFrom(eve, bob, amount, aliceTokenId, "");
        // eve cannot sell the tokens
        vm.prank(eve);
        vm.expectRevert("Framm: not enough tokens");
        framm.sellShares(alice, amount);

        vm.startPrank(bob);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore,
            "shares balance not equal after transfer"
        );
        assertEq(wFTS.balanceOf(eve, aliceTokenId), 0, "wrong token balance");
        assertEq(
            wFTS.balanceOf(bob, aliceTokenId),
            amount,
            "wrong token balance after transfer"
        );
        uint256 bobBalanceBefore = bob.balance;
        sharesSupplyBefore = framm.sharesSupply(alice);
        uint256 sellPrice = friendtechShares.getSellPriceAfterFee(
            alice,
            amount
        );
        framm.sellShares(alice, amount);
        assertEq(
            framm.sharesSupply(alice),
            sharesSupplyBefore - amount,
            "wrong shares balance"
        );
        assertEq(wFTS.balanceOf(bob, aliceTokenId), 0, "wrong token balance");
        assertEq(
            bob.balance - bobBalanceBefore,
            sellPrice,
            "native balance after sell"
        );
        vm.stopPrank();
        vm.revertTo(snapStart);
    }
}
