// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct SignedPersonalData {
    Person me;
    Person[] friends;
}

struct Person {
    string name;
    uint256 id;
}

contract TestSignerAccount is EIP712 {
    using ECDSA for bytes32;

    // Type hashes for the structs
    bytes32 public constant SIGNED_PERSONAL_DATA_TYPEHASH =
        keccak256("SignedPersonalData(Person me,Person[] friends)Person(string name,uint256 id)");
    bytes32 public constant PERSON_TYPEHASH = keccak256("Person(string name,uint256 id)");

    constructor() EIP712("TestSignerAccount", "1") {}

    function hashPerson(Person memory person) public pure returns (bytes32) {
        return keccak256(abi.encode(PERSON_TYPEHASH, keccak256(bytes(person.name)), person.id));
    }

    function hashSignedPersonalData(SignedPersonalData memory data) public pure returns (bytes32) {
        bytes32[] memory friendHashes = new bytes32[](data.friends.length);
        for (uint256 i = 0; i < data.friends.length; i++) {
            friendHashes[i] = hashPerson(data.friends[i]);
        }

        return keccak256(
            abi.encode(SIGNED_PERSONAL_DATA_TYPEHASH, hashPerson(data.me), keccak256(abi.encodePacked(friendHashes)))
        );
    }

    function hashTypedData(SignedPersonalData memory data) public view returns (bytes32) {
        bytes32 structHash = hashSignedPersonalData(data);
        return _hashTypedDataV4(structHash);
    }
}
