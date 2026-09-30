//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    //////////////**ERRORS**//////////////
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    ///////////////**STATE VARIABLES**//////////////
    IEntryPoint private immutable i_entryPiont;

    /////////////**MODIFIERS**/////////////

    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPiont)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    // modifier requireFromEntryPointOrOwner() {
    //     if (msg.sender != address(i_entryPiont) && msg.sender != owner()) {
    //         revert MinimalAccount__NotFromEntryPointOrOwner();
    //     }
    //     _;
    // }

    ///////////////**FUNCTIONS**///////////////

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPiont = IEntryPoint(entryPoint);
    }

    ////////////**EXTERNAL FUNCTIONS**/////////////

    function receieve() external payable {}

    function execute(address dest, uint256 value, bytes calldata functionData) external {
        if (msg.sender != address(i_entryPiont) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        } else {
            (bool success, bytes memory result) = dest.call{value: value}(functionData);
            if (!success) {
                revert MinimalAccount__CallFailed(result);
            }
        }
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        payPreFund(missingAccountFunds);
    }

    /////////////*INTERNAL FUNCTIONS*////////////

    function _validateSignature(PackedUserOperation calldata userOps, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOps.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function payPreFund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    //////////////////*GETTERS*////////////////

    function getEntryPoint() external view returns (address) {
        return address(i_entryPiont);
    }
}
