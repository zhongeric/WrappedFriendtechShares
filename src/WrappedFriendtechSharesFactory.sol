// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";
import {IWrappedFriendtechSharesFactory} from "./interfaces/IWrappedFriendtechSharesFactory.sol";
import {IFriendTechSharesV1} from "./external/IFriendTechSharesV1.sol";

/// @title ERC1155 Token Issuer built ontop of friends.tech
/// @author Eric Zhong
/// Holds an internal balance and mints / burns tokens
/// @dev No owner, no permissioned functions
/// @notice No fee on transfer but minting / burning are subject to fees set in friendTechSharesV1 contract
contract WrappedFriendtechSharesFactory is IWrappedFriendtechSharesFactory, ERC1155 {
    using SafeTransferLib for address;

    address public friendtechSharesV1;
    uint256 public lastId = 0;
    bool public locked;

    IFriendTechSharesV1 FTS;

    event ShareSubjectCreated(address indexed sharesSubject, uint256 indexed tokenId);
    event URIChanged(uint256 indexed id, string uri);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Storage copied from IFriendTechSharesV1
    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;
    // WrappedFriendtechSharesFactory storage
    mapping(address => uint256) public subjectToTokenId;
    mapping(uint256 => address) public tokenIdToSubject;
    mapping(uint256 => string) public tokenURIs;

    constructor(address _friendtechSharesV1) {
        friendtechSharesV1 = _friendtechSharesV1;
        FTS = IFriendTechSharesV1(friendtechSharesV1);
    }

    modifier reentrancyLock() {
        require(!locked, "WrappedFriendtechSharesFactory: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    /// @notice Creates a new token id for a shares subject
    /// @param sharesSubject The address of the shares subject
    /// @return id The token id corresponding to the shares subject
    function createToken(address sharesSubject) external returns (uint256 id) {
        require(subjectToTokenId[sharesSubject] == 0, "WrappedFriendtechSharesFactory: token already exists");
        lastId += 1;
        subjectToTokenId[sharesSubject] = lastId;
        tokenIdToSubject[lastId] = sharesSubject;
        emit ShareSubjectCreated(sharesSubject, lastId);
        return lastId;
    }

    /// @notice Buy shares in sharesSubject on friendsTech
    /// @notice this is subject to the set fee in the friendTechSharesV1 contract
    /// @dev You must send msg.value greater than the getBuyPriceAfterFee
    /// @param sharesSubject The address of the shares subject
    /// @param amount The amount of shares to buy
    function buyShares(address sharesSubject, uint256 amount) external payable reentrancyLock {
        require(subjectToTokenId[sharesSubject] != 0, "WrappedFriendtechSharesFactory: token not created");
        require(
            msg.value >= FTS.getBuyPriceAfterFee(sharesSubject, amount),
            "WrappedFriendtechSharesFactory: not enough for buy"
        );
        FTS.buyShares{value: msg.value}(sharesSubject, amount);
        _mint(msg.sender, subjectToTokenId[sharesSubject], amount, "");
        sharesSupply[sharesSubject] += amount;
    }

    /// @notice Sell shares in sharesSubject on friendsTech
    /// @notice this is subject to the set fee in the friendTechSharesV1 contract
    /// @param sharesSubject The address of the shares subject
    /// @param amount The amount of shares to sell
    function sellShares(address sharesSubject, uint256 amount) external reentrancyLock {
        require(subjectToTokenId[sharesSubject] != 0, "WrappedFriendtechSharesFactory: token not created");
        require(amount <= sharesSupply[sharesSubject], "WrappedFriendtechSharesFactory: not enough shares");
        require(
            balanceOf[msg.sender][subjectToTokenId[sharesSubject]] >= amount,
            "WrappedFriendtechSharesFactory: not enough tokens"
        );

        sharesSupply[sharesSubject] -= amount;
        uint256 amountOwed = FTS.getSellPriceAfterFee(sharesSubject, amount);
        FTS.sellShares(sharesSubject, amount);
        _burn(msg.sender, subjectToTokenId[sharesSubject], amount);
        msg.sender.safeTransferETH(amountOwed);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return tokenURIs[id];
    }

    function setURI(uint256 id, string memory _uri) public {
        require(msg.sender == tokenIdToSubject[id], "WrappedFriendtechSharesFactory: not shares subject of token");
        tokenURIs[id] = _uri;
        emit URIChanged(id, tokenURIs[id]);
    }

    receive() external payable {}
}
