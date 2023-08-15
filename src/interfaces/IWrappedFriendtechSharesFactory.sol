// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

interface IWrappedFriendtechSharesFactory {
    function createToken(address sharesSubject) external returns (uint256 id);

    function buyShares(address sharesSubject, uint256 amount) external payable;

    function sellShares(address sharesSubject, uint256 amount) external;
}
