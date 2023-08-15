// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {UniswapV3Factory} from "./utils/Constants.sol";
import {Test} from "forge-std/Test.sol";

abstract contract DeployUniswapV3 is Test {
    IUniswapV3Factory public factory;

    function setUp() public virtual {
        bytes memory creationCode = UniswapV3Factory;
        address factoryAddress;
        assembly {
            factoryAddress := create(0, add(creationCode, 32), mload(creationCode))

            if iszero(factoryAddress) { revert(0, 0) }
        }
        factory = IUniswapV3Factory(factoryAddress);
    }
}
