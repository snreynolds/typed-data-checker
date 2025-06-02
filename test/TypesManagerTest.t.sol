// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TypesManager, TypesManagerLib, Struct} from "../src/TypesManager.sol";
import "forge-std/StdJson.sol";

contract TypesManagerTest is Test {
    using TypesManagerLib for Struct;

    TypesManager public typesManager;

    struct Outside {
        Inside inside;
        uint256 number;
    }

    struct Inside {
        bytes32 salt;
    }

    function setUp() public {
        typesManager = new TypesManager();
        Struct memory outside = typesManager.createStruct("Outside").with("inside", "Inside").with("number", "uint256");
        Struct memory inside = typesManager.createStruct("Inside").with("salt", "bytes32");

        typesManager.register(outside);
        typesManager.register(inside);
    }

    function test_createStruct() public {
        typesManager.writeTypes();
    }
}
