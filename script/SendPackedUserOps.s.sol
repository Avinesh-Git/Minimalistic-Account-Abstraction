//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";

contract SendPackedUserOps is Script {
    function run() public {
        // HelperConfig helperConfig = new HelperConfig();
        // address dest = address(0xghfgiu65465t7gui6ifd64); // arbitrum mainnet USDC address
        // uint256 value = 0;
        // bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector,,1e18);
        // bytes memory executionCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        // PackedUserOperation memory userOp = generateSignedUserOperation(executeCallData,helperConfig.getConfig(),addr(deployed minimal account));
        // PackedUserOperation [] memory ops = new PackedUserOperation [](1);
        // ops[0] = userOp;

        // vm.startBroadCast();
        // IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable (helperConfig.getConfig().account));
        // vm.stopBroadCast();
    }

    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        //1. generate the unsigned data -> _generateUnsignedUserOperation()
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);

        //2.get the userOp hash.
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        //3. sign it and return
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); //note the order of encoding
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 1678888;
        uint128 maxPriorityFeePerGas = 256;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }

    // function getUnsignedData(bytes memory callData, address sender, uint256 nonce)
    //     public
    //     returns (PackedUserOperation memory)
    // {
    //     PackedUserOperation memory unsignedOperationData =
    //         SendPackedUserOps._generateUnsignedUserOperation(callData, sender, nonce);
    //     return unsignedOperationData;
    // }
}
