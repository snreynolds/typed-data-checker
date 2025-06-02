// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "forge-std/Vm.sol";

contract DomainSeparatorManager {
    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function register(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract,
        bytes32 salt
    ) public {
        string memory json = string(
            abi.encodePacked(
                "{",
                '"name":"',
                name,
                '",',
                '"version":"',
                version,
                '",',
                '"chainId":',
                vm.toString(chainId),
                ",",
                '"verifyingContract":"',
                vm.toString(verifyingContract),
                '",',
                '"salt":"',
                vm.toString(salt),
                '"',
                "}"
            )
        );

        // Create the directory if it doesn't exist
        vm.createDir("test/json", true);
        vm.writeFile("test/json/domain.json", json);
    }
}
