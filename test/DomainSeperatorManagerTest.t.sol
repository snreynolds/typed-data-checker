// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DomainSeparatorManager} from "../src/DomainSeparatorManager.sol";
import "forge-std/StdJson.sol";

contract DomainSeparatorManagerTest is Test {
    using stdJson for string;

    DomainSeparatorManager public dsm;

    function setUp() public {
        dsm = new DomainSeparatorManager();
    }

    function test_register() public {
        dsm.register("Counter", "1", 1, address(this), bytes32(0));
        string memory json = vm.readFile("test/json/domain.json");
        string memory name = json.readString("$.name");
        string memory version = json.readString("$.version");
        uint256 chainId = json.readUint("$.chainId");
        address verifyingContract = json.readAddress("$.verifyingContract");
        bytes32 salt = json.readBytes32("$.salt");

        assertEq(name, "Counter");
        assertEq(version, "1");
        assertEq(chainId, 1);
        assertEq(verifyingContract, address(this));
        assertEq(salt, bytes32(0));
    }
}
