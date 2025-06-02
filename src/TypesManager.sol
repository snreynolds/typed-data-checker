// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "forge-std/Vm.sol";

struct Struct {
    string structName;
    string[] fields;
    string[] types;
}

contract TypesManager {
    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    mapping(string => Struct) internal types;
    string[] internal allTypes;

    function createStruct(string memory name) public pure returns (Struct memory s) {
        s = Struct({structName: name, fields: new string[](0), types: new string[](0)});
    }

    function register(Struct memory s) public {
        allTypes.push(s.structName);
        types[s.structName] = s;
    }

    function writeTypes() public {
        string memory json = "";
        for (uint256 i = 0; i < allTypes.length; i++) {
            if (i > 0) json = string(abi.encodePacked(json, ","));
            string memory typeName = allTypes[i];
            Struct memory typeDef = types[typeName];
            string memory typeJson = "";
            for (uint256 j = 0; j < typeDef.fields.length; j++) {
                if (j > 0) typeJson = string(abi.encodePacked(typeJson, ","));
                typeJson = string(
                    abi.encodePacked(typeJson, '{"name":"', typeDef.fields[j], '","type":"', typeDef.types[j], '"}')
                );
            }
            json = string(abi.encodePacked(json, '"', typeName, '":[', typeJson, "]"));
        }

        json = string(abi.encodePacked("{", json, "}"));

        vm.createDir("test/json", true);
        vm.writeFile("test/json/types.json", json);
    }
}

library TypesManagerLib {
    function with(Struct memory def, string memory _field, string memory _type) public pure returns (Struct memory) {
        string[] memory newFields = new string[](def.fields.length + 1);
        string[] memory newTypes = new string[](def.types.length + 1);

        for (uint256 i = 0; i < def.fields.length; i++) {
            newFields[i] = def.fields[i];
            newTypes[i] = def.types[i];
        }

        newFields[def.fields.length] = _field;
        newTypes[def.types.length] = _type;

        def.fields = newFields;
        def.types = newTypes;

        return def;
    }
}
