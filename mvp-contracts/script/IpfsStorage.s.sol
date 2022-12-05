// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IpfsStorage} from "src/IpfsStorage.sol";

contract IpfsStorageScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new IpfsStorage();
        vm.stopBroadcast();
    }
}