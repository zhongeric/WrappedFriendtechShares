// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IWrappedFTS {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burnFrom(address from, uint256 id, uint256 amount) external;

    function burn(uint256 id, uint256 amount) external;
}
