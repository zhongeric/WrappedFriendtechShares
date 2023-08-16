// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

interface IWrappedFriendtechSharesFactory is IERC1155 {
    function subjectToTokenId(address sharesSubject) external view returns (uint256 id);

    function createToken(address sharesSubject) external returns (uint256 id);

    function buyShares(address sharesSubject, uint256 amount) external payable;

    function sellShares(address sharesSubject, uint256 amount) external;
}
