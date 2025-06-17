#!/usr/bin/env node
import {
    privateKeyToAccount,
} from 'viem/accounts'
import {
    createWalletClient,
    http,
    type WalletClient,
    toHex,
    pad,
    decodeAbiParameters,
    Address
} from 'viem'
import { readFileSync } from 'fs';
import { resolve } from 'path';
import {TypedData } from 'ox';

export interface Input {
    privateKey: string;
    primaryType: string;
    data: `0x${string}`;
}

import types from '../../json/types.json';
import _domain from '../../json/domain.json';

type PrimaryTypeKeys = keyof typeof types;

const domain = _domain as TypedData.Domain;

// Read command line arguments
const args = process.argv.slice(2);
if (args.length < 1) {
    console.log("Usage: sign-typed-data <privateKey> <primaryType> <abiencoded data>");
    process.exit(1);
}

// Parse the JSON input
let jsonInput: Input;
if (args[0].endsWith('.json')) {
    const filePath = resolve(args[0]);
    jsonInput = JSON.parse(readFileSync(filePath, 'utf8')) as Input;
} else {
    jsonInput = JSON.parse(args[0]) as Input;
}

const { privateKey, primaryType, data } = jsonInput;


// Validate the primaryType
const validPrimaryTypes = Object.keys(types) as PrimaryTypeKeys[];
if (!validPrimaryTypes.includes(primaryType as PrimaryTypeKeys)) {
    console.error(`Invalid primaryType: ${primaryType}. Must be one of: ${validPrimaryTypes.join(', ')}`);
    process.exit(1);
}

const account = privateKeyToAccount(pad(toHex(BigInt(privateKey))));

const walletClient: WalletClient = createWalletClient({
    account,
    transport: http('http://127.0.0.1:8545')
});

// Check if a type is a Solidity primitive
function isPrimitive(type: string): boolean {
    const primitivePatterns = [
        /^uint(\d+)?$/,    // uint, uint8, uint16, ..., uint256
        /^int(\d+)?$/,     // int, int8, int16, ..., int256
        /^bytes(\d+)?$/,   // bytes, bytes1, bytes2, ..., bytes32
        /^address$/,       // address
        /^bool$/,          // bool
        /^string$/,        // string
    ];
    
    // Handle arrays - extract base type
    let baseType = type;
    if (type.includes('[')) {
        baseType = type.split('[')[0];
    }
    
    return primitivePatterns.some(pattern => pattern.test(baseType));
}

// Convert a field type to ABI format
function convertFieldType(fieldType: string, typesDefinition: typeof types): any {
    // Handle custom struct types
    if (fieldType in typesDefinition) {
        const components = convertStructFields(fieldType, typesDefinition);
        return {
            type: 'tuple',
            components: components
        };
    }
    
    // Handle dynamic arrays: Type[]
    if (fieldType.endsWith('[]')) {
        const baseType = fieldType.slice(0, -2);
        
        if (baseType in typesDefinition) {
            const components = convertStructFields(baseType, typesDefinition);
            return {
                type: 'tuple[]',
                components: components
            };
        } else if (isPrimitive(baseType)) {
            return { type: fieldType };
        } else {
            throw new Error(`Unknown base type in array: ${baseType}`);
        }
    }
    
    // Handle fixed-size arrays: Type[N]
    const fixedArrayMatch = fieldType.match(/^(.+)\[(\d+)\]$/);
    if (fixedArrayMatch) {
        const [, baseType, size] = fixedArrayMatch;
        
        if (baseType in typesDefinition) {
            const components = convertStructFields(baseType, typesDefinition);
            return {
                type: `tuple[${size}]`,
                components: components
            };
        } else if (isPrimitive(baseType)) {
            return { type: fieldType };
        } else {
            throw new Error(`Unknown base type in fixed array: ${baseType}`);
        }
    }
    
    // Handle primitive types
    if (isPrimitive(fieldType)) {
        return { type: fieldType };
    }
    
    throw new Error(`Unknown type: ${fieldType}`);
}

// Convert struct fields to ABI components
function convertStructFields(structName: string, typesDefinition: typeof types): any[] {
    const structDef = typesDefinition[structName as keyof typeof typesDefinition];
    if (!structDef) {
        throw new Error(`Struct ${structName} not found in types definition`);
    }

    return structDef.map(field => {
        const convertedType = convertFieldType(field.type, typesDefinition);
        return {
            name: field.name,
            ...convertedType
        };
    });
}

// Convert any struct to ABI format (wrapped in tuple like Solidity does)
function convertStructToAbi(structName: string, typesDefinition: typeof types): any[] {
    return [
        {
            name: 'data',
            type: 'tuple',
            components: convertStructFields(structName, typesDefinition)
        }
    ];
}

async function signTypedData(): Promise<void> {
    try {

        // Convert to ABI
        const abiParams = convertStructToAbi(primaryType, types);
        
        // Decode
        const decoded = decodeAbiParameters(abiParams, data);

        // Build domain
        const signatureDomain = {
            ...(domain.name && { name: domain.name }),
            ...(domain.version && { version: domain.version }),
            ...(domain.chainId && { chainId: domain.chainId }),
            ...(domain.verifyingContract && { verifyingContract: domain.verifyingContract as Address }),
            ...(domain.salt && { salt: domain.salt as `0x${string}` })
        };

        // Sign
        const signature = await walletClient.signTypedData({
            account,
            domain: signatureDomain,
            types,
            primaryType: primaryType as PrimaryTypeKeys,
            message:decoded[0] as any
        });
        
        process.stdout.write(signature);
        process.exit(0);
        
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

signTypedData().catch(console.error);