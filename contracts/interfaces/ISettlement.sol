// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity =0.8.17;

interface IAuthenticator {
    function isSolver(address) external view returns (bool);
}

interface ISettlement {
    function authenticator() external view returns (IAuthenticator);
}
