// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {Test} from "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import {DeployUniswapV3} from "./DeployUniswapV3.t.sol";
// import {FrammTest} from "./Framm.t.sol";

// contract UniswapV3Test is DeployUniswapV3, FrammTest {
//     address public aliceTokenBobTokenPool;

//     function setUp() public override(DeployUniswapV3, FrammTest) {
//         FrammTest.setUp();
//         DeployUniswapV3.setUp();
//         // create pool with alice token, bob token
//         aliceTokenBobTokenPool = factory.createPool(
//             address(aliceToken),
//             address(bobToken),
//             3000
//         );

//         // initialize pool at 1:1
//         // sqrtp(1)
//         IUniswapV3Pool(aliceTokenBobTokenPool).initialize(
//             79228162514264337593543950336
//         );

//         // alice buys 100 alice and 100 bob tokens
//         uint256 amountAlice = 100;
//         uint256 sharesSupplyBefore = framm.sharesSupply(alice);
//         uint256 buyPrice = friendtechShares.getBuyPriceAfterFee(
//             alice,
//             amountAlice
//         );
//         vm.prank(alice);
//         framm.buyShares{value: buyPrice}(alice, amountAlice);
//         assertEq(
//             framm.sharesSupply(alice),
//             sharesSupplyBefore + amountAlice,
//             "wrong shares balance"
//         );

//         uint256 amountBob = 100;
//         sharesSupplyBefore = framm.sharesSupply(bob);
//         buyPrice = friendtechShares.getBuyPriceAfterFee(bob, amountBob);
//         vm.prank(alice);
//         framm.buyShares{value: buyPrice}(bob, amountBob);
//         assertEq(
//             framm.sharesSupply(bob),
//             sharesSupplyBefore + amountBob,
//             "wrong shares balance"
//         );
//     }

//     function uniswapV3MintCallback(
//         uint256 amount0Owed,
//         uint256 amount1Owed,
//         bytes calldata data
//     ) external {
//         require(
//             msg.sender == aliceTokenBobTokenPool,
//             "UniswapV3Test: wrong sender"
//         );
//         console.log("%s", amount0Owed);
//         console.log("%s", amount1Owed);
//         // send tokens to pool
//         aliceToken.transferFrom(alice, aliceTokenBobTokenPool, amount0Owed);
//         bobToken.transferFrom(alice, aliceTokenBobTokenPool, amount1Owed);
//     }

//     function xtestCanProvideLiquidity() public {
//         uint256 snapStart = vm.snapshot();
//         // alice approves this contract to spend her tokens
//         vm.startPrank(alice);
//         aliceToken.approve(address(this), type(uint256).max);
//         bobToken.approve(address(this), type(uint256).max);
//         vm.stopPrank();

//         (uint160 sqrtPriceX96, int24 tick, , , , , ) = IUniswapV3Pool(
//             aliceTokenBobTokenPool
//         ).slot0();
//         console.log("%s", sqrtPriceX96);
//         console.logInt(tick);

//         IUniswapV3Pool(aliceTokenBobTokenPool).mint(
//             alice,
//             -6932, // 0.5
//             4054, // 1.5
//             1,
//             ""
//         );

//         vm.revertTo(snapStart);
//     }
// }
