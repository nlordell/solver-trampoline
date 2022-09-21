// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity =0.8.17;

import { IAuthenticator, ISettlement } from "./interfaces/ISettlement.sol";

contract SolverTrampoline {
    ISettlement public immutable settlement;
    IAuthenticator public immutable authenticator;

    uint256 public nonce;

    constructor(ISettlement _settlement) {
        settlement = _settlement;
        authenticator = _settlement.authenticator();
    }

    function settle(bytes calldata solution, bytes32 r, bytes32 s, uint8 v) external {
        ISettlement _settlement = settlement;

        bytes32 solutionDigest;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, solution.offset, solution.length)

            if iszero(
                call(
                    gas(),
                    _settlement,
                    0,
                    ptr,
                    solution.length,
                    0,
                    0
                )
            ) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            solutionDigest := keccak256(ptr, solution.length)
        }

        bytes32 message = solutionMessage(solutionDigest, nonce++);
        address solver = ecrecover(message, v, r, s);
        require(solver != address(0) && authenticator.isSolver(solver));
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"),
            block.chainid,
            address(this)
        ));
    }

    function solutionMessage(bytes memory solution) external view returns (bytes32) {
        return solutionMessage(keccak256(solution), nonce);
    }

    function solutionMessage(bytes32 solutionDigest, uint256 _nonce) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator(),
            keccak256(abi.encode(
                keccak256("Solution(bytes solution, uint256 nonce)"),
                solutionDigest,
                _nonce
            ))
        ));
    }
}
