// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {JavascriptFfi} from "./JavascriptFFI.sol";

contract SignTypedDataFFI is JavascriptFfi {
    function ffi_run_signedTypedData(uint256 pk, string memory primaryType, bytes memory abiEncodedData)
        public
        returns (bytes memory)
    {
        string memory jsonInput = _createJsonInput(pk, primaryType, abiEncodedData);

        return runScript("sign-typed-data", jsonInput);
    }

    /// Creates JSON input for sign-typed-data.ts script
    /// Format: {"privateKey": "...", "primaryType": "...", "data": "0x..."}
    function _createJsonInput(uint256 pk, string memory primaryType, bytes memory abiEncodedData)
        internal
        pure
        returns (string memory)
    {
        // Convert private key to string (no hex prefix needed as it's converted to BigInt in TS)
        string memory pkStr = vm.toString(pk);

        // Convert abiEncodedData to hex string with 0x prefix
        string memory dataHex = vm.toString(abiEncodedData);

        // Create the JSON string
        return string(
            abi.encodePacked('{"privateKey":"', pkStr, '","primaryType":"', primaryType, '","data":"', dataHex, '"}')
        );
    }
}
