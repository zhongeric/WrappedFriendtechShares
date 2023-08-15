// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {WrappedFTS} from "./WrappedFTS.sol";
import {IWrappedFTS} from "./interfaces/IWrappedFTS.sol";
import {IFriendTechSharesV1} from "./external/IFriendTechSharesV1.sol";

/// ERC1155 Token Issuer built ontop of friends.tech
contract Framm {
    using SafeTransferLib for address;

    address public friendtechSharesV1;
    bool public locked;

    WrappedFTS public wFTS;
    IFriendTechSharesV1 FTS;

    uint256 public numSubjects = 0;

    event ShareSubjectCreated(
        address indexed sharesSubject,
        uint256 indexed tokenId
    );

    // Storage copied from IFriendTechSharesV1
    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;
    // Framm storage
    mapping(address => uint256) public sharesSubjectToTokenId;
    mapping(uint256 => address) public tokenIdtoSharesSubject;

    constructor(address _friendtechSharesV1) {
        friendtechSharesV1 = _friendtechSharesV1;
        FTS = IFriendTechSharesV1(friendtechSharesV1);
        wFTS = new WrappedFTS();
    }

    modifier onlyInitializedSharesSubject() {
        require(
            sharesSubjectToTokenId[msg.sender] != 0,
            "Framm: not shares subject"
        );
        _;
    }

    modifier reentrancyLock() {
        require(!locked, "WrappedFTS: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function createToken(address sharesSubject) external returns (uint256 id) {
        require(
            sharesSubjectToTokenId[sharesSubject] == 0,
            "Framm: token already exists"
        );
        numSubjects += 1;
        sharesSubjectToTokenId[sharesSubject] = numSubjects;
        tokenIdtoSharesSubject[numSubjects] = sharesSubject;
        emit ShareSubjectCreated(sharesSubject, numSubjects);
        return numSubjects;
    }

    function buyShares(
        address sharesSubject,
        uint256 amount
    ) external payable reentrancyLock {
        require(
            sharesSubjectToTokenId[sharesSubject] != 0,
            "Framm: token not created"
        );
        require(
            msg.value > FTS.getBuyPrice(sharesSubject, amount),
            "Framm: not enough for buy"
        );
        FTS.buyShares{value: msg.value}(sharesSubject, amount);
        wFTS.mint(
            msg.sender,
            sharesSubjectToTokenId[sharesSubject],
            amount,
            ""
        );
        sharesSupply[sharesSubject] += amount;
    }

    function sellShares(
        address sharesSubject,
        uint256 amount
    ) external reentrancyLock {
        require(
            sharesSubjectToTokenId[sharesSubject] != 0,
            "Framm: token not created"
        );
        require(
            amount <= sharesSupply[sharesSubject],
            "Framm: not enough shares"
        );
        require(
            wFTS.balanceOf(msg.sender, sharesSubjectToTokenId[sharesSubject]) >=
                amount,
            "Framm: not enough tokens"
        );

        sharesSupply[sharesSubject] -= amount;
        uint256 amountOwed = FTS.getSellPriceAfterFee(sharesSubject, amount);
        FTS.sellShares(sharesSubject, amount);
        wFTS.burnFrom(
            msg.sender,
            sharesSubjectToTokenId[sharesSubject],
            amount
        );
        msg.sender.safeTransferETH(amountOwed);
    }

    receive() external payable {}
}
