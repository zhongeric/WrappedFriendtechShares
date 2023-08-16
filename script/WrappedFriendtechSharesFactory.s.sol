// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WrappedFriendtechSharesFactory} from "../src/WrappedFriendtechSharesFactory.sol";
import {Script, console2} from "forge-std/Script.sol";

contract WrappedFriendtechSharesFactoryScript is Script {
    address constant friendtechSharesV1 = 0xCF205808Ed36593aa40a44F10c7f7C2F67d4A4d4;

    function setUp() public {}

    function run() public returns (WrappedFriendtechSharesFactory factory) {
        vm.startBroadcast();
        factory = new WrappedFriendtechSharesFactory{salt: 0x00}(
            friendtechSharesV1
        );
        console2.log("Factory", address(factory));
        vm.stopBroadcast();
    }
}
