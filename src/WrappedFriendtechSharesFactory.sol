// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";
import {IWrappedFriendtechSharesFactory} from "./interfaces/IWrappedFriendtechSharesFactory.sol";
import {IFriendTechSharesV1} from "./external/IFriendTechSharesV1.sol";

/// ERC1155 Token Issuer built ontop of friends.tech
contract WrappedFriendtechSharesFactory is IWrappedFriendtechSharesFactory, ERC1155 {
    using SafeTransferLib for address;

    string public baseURI = "";
    address public owner;
    address public friendtechSharesV1;
    bool public locked;

    IFriendTechSharesV1 FTS;

    uint256 public lastId = 0;

    event ShareSubjectCreated(
        address indexed sharesSubject,
        uint256 indexed tokenId
    );
    event BaseURIChanged(
        string indexed baseURI
    );

    // Storage copied from IFriendTechSharesV1
    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;
    // WrappedFriendtechSharesFactory storage
    mapping(address => uint256) public subjectToTokenId;
    mapping(uint256 => address) public tokenIdToSubject;

    // Only used for URI updating
    modifier onlyOwner() {
        require(msg.sender == owner, "WrappedFriendtechSharesFactory: not owner");
        _;
    }

    constructor(address _friendtechSharesV1) {
        owner = msg.sender;
        friendtechSharesV1 = _friendtechSharesV1;
        FTS = IFriendTechSharesV1(friendtechSharesV1);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenIdToSubject[id]));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURIChanged(baseURI);
    }

    modifier reentrancyLock() {
        require(!locked, "WrappedFriendtechSharesFactory: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function createToken(address sharesSubject) external returns (uint256 id) {
        require(
            subjectToTokenId[sharesSubject] == 0,
            "WrappedFriendtechSharesFactory: token already exists"
        );
        lastId += 1;
        subjectToTokenId[sharesSubject] = lastId;
        tokenIdToSubject[lastId] = sharesSubject;
        emit ShareSubjectCreated(sharesSubject, lastId);
        return lastId;
    }

    function buyShares(
        address sharesSubject,
        uint256 amount
    ) external payable reentrancyLock {
        require(
            subjectToTokenId[sharesSubject] != 0,
            "WrappedFriendtechSharesFactory: token not created"
        );
        require(
            msg.value >= FTS.getBuyPrice(sharesSubject, amount),
            "WrappedFriendtechSharesFactory: not enough for buy"
        );
        FTS.buyShares{value: msg.value}(sharesSubject, amount);
        _mint(
            msg.sender,
            subjectToTokenId[sharesSubject],
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
            subjectToTokenId[sharesSubject] != 0,
            "WrappedFriendtechSharesFactory: token not created"
        );
        require(
            amount <= sharesSupply[sharesSubject],
            "WrappedFriendtechSharesFactory: not enough shares"
        );
        require(
            balanceOf[msg.sender][subjectToTokenId[sharesSubject]] >=
                amount,
            "WrappedFriendtechSharesFactory: not enough tokens"
        );

        sharesSupply[sharesSubject] -= amount;
        uint256 amountOwed = FTS.getSellPriceAfterFee(sharesSubject, amount);
        FTS.sellShares(sharesSubject, amount);
        _burn(
            msg.sender,
            subjectToTokenId[sharesSubject],
            amount
        );
        msg.sender.safeTransferETH(amountOwed);
    }

    receive() external payable {}
}
