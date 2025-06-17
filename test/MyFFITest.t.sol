// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DomainSeparatorManager} from "../src/DomainSeparatorManager.sol";
import {TypesManager, TypesManagerLib, Struct} from "../src/TypesManager.sol";
import {Person, SignedPersonalData, TestSignerAccount} from "./utils/TestSignerAccount.sol";
import {SignTypedDataFFI} from "../src/SignTypedDataFFI.sol";
import "forge-std/StdJson.sol";

contract MyFFITest is SignTypedDataFFI, Test {
    using stdJson for string;
    using TypesManagerLib for Struct;

    DomainSeparatorManager public dsm;
    TypesManager public typesManager;
    TestSignerAccount public signerAccount;

    uint256 pk = 0x5a3a;
    address signer = vm.addr(pk);

    function setUp() public {
        signerAccount = new TestSignerAccount();

        dsm = new DomainSeparatorManager();
        typesManager = new TypesManager();

        // TODO: Read from the ABI directly instead of registering the structs
        Struct memory signedPersonalDataStruct =
            typesManager.createStruct("SignedPersonalData").with("me", "Person").with("friends", "Person[]");
        Struct memory personStruct = typesManager.createStruct("Person").with("name", "string").with("id", "uint256");
        typesManager.register(signedPersonalDataStruct);
        typesManager.register(personStruct);
        typesManager.writeTypes();

        dsm.register("TestSignerAccount", "1", block.chainid, address(signerAccount));
    }

    function test_sign_struct() public {
        Person memory me = Person({name: "Sara", id: 410});
        Person memory friend = Person({name: "Julia", id: 903});
        Person[] memory friends = new Person[](1);
        friends[0] = friend;
        SignedPersonalData memory data = SignedPersonalData({me: me, friends: friends});

        bytes32 hash = signerAccount.hashTypedData(data);

        // Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        bytes memory _signature = ffi_run_signedTypedData(pk, "SignedPersonalData", abi.encode(data));

        assertEq(signature, _signature);
    }
}
