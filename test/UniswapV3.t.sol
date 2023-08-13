// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Test} from "forge-std/Test.sol";
import {Framm} from "../src/Framm.sol";
import {UserToken} from "../src/UserToken.sol";
import {FrammTest} from "./Framm.t.sol";

contract UniswapV3Test is FrammTest {
    address public v3Factory;

    function setUp() public override {}
}
