// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {UserToken} from "./UserToken.sol";
import {IUserToken} from "./interfaces/IUserToken.sol";
import {IFriendTechSharesV1} from "./external/IFriendTechSharesV1.sol";

// AMM built ontop of friends.tech
contract Framm {
    using SafeTransferLib for address;
    address public friendtechSharesV1;
    bool public locked;
    IFriendTechSharesV1 FTS;

    // Storage copied from IFriendTechSharesV1
    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;
    // Framm storage
    mapping(address => address) public sharesSubjectToToken;
    mapping(address => address) public tokenToSharesSubject;

    constructor(address _friendtechSharesV1) {
        friendtechSharesV1 = _friendtechSharesV1;
        FTS = IFriendTechSharesV1(friendtechSharesV1);
    }

    modifier onlyInitializedSharesSubject() {
        require(
            sharesSubjectToToken[msg.sender] != address(0),
            "Framm: not shares subject"
        );
        _;
    }

    modifier onlyInitializedToken() {
        require(
            tokenToSharesSubject[msg.sender] != address(0),
            "Framm: not token"
        );
        _;
    }

    modifier reentrancyLock() {
        require(!locked, "UserToken: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function createToken(
        address sharesSubject,
        string memory name,
        string memory symbol
    ) external returns (address token) {
        require(
            sharesSubjectToToken[sharesSubject] == address(0),
            "Framm: token already exists"
        );
        token = address(new UserToken(name, symbol));
        sharesSubjectToToken[sharesSubject] = token;
    }

    function changeNameSymbol(
        string memory name,
        string memory symbol
    ) external onlyInitializedSharesSubject {
        IUserToken(sharesSubjectToToken[msg.sender]).changeNameSymbol(
            name,
            symbol
        );
    }

    function buyShares(
        address sharesSubject,
        uint256 amount
    ) external payable reentrancyLock {
        require(
            sharesSubjectToToken[sharesSubject] != address(0),
            "Framm: token not created"
        );
        require(
            msg.value > FTS.getBuyPrice(sharesSubject, amount),
            "Framm: not enough for buy"
        );
        FTS.buyShares{value: msg.value}(sharesSubject, amount);
        IUserToken(sharesSubjectToToken[sharesSubject]).mint(
            msg.sender,
            amount
        );
        sharesSupply[sharesSubject] += amount;
    }

    function sellShares(
        address sharesSubject,
        uint256 amount
    ) external reentrancyLock {
        require(
            sharesSubjectToToken[sharesSubject] != address(0),
            "Framm: token not created"
        );
        require(
            amount <= sharesSupply[sharesSubject],
            "Framm: not enough shares"
        );
        require(
            IUserToken(sharesSubjectToToken[sharesSubject]).balanceOf(
                msg.sender
            ) >= amount,
            "Framm: not enough tokens"
        );

        sharesSupply[sharesSubject] -= amount;
        uint256 amountOwed = FTS.getSellPriceAfterFee(sharesSubject, amount);
        FTS.sellShares(sharesSubject, amount);
        IUserToken(sharesSubjectToToken[sharesSubject]).burnFrom(
            msg.sender,
            amount
        );
        msg.sender.safeTransferETH(amountOwed);
    }

    receive() external payable {}
}
