// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract IpfsStorage {
    mapping (address => string) public userFiles;

    function setFile(string memory file) external {
        userFiles[msg.sender] = file;
    }
}