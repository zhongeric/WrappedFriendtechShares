// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IUserToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function changeNameSymbol(
        string memory _name,
        string memory _symbol
    ) external;
}
