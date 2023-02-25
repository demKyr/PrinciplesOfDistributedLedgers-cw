// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";
import "./PrimaryMarket.sol";

contract SecondaryMarket is ISecondaryMarket {

    mapping(uint256 => address) private ticketListOriginator;
    mapping(uint256 => uint256) private ticketListPrice;
    mapping(uint256 => bool) private ticketListListed;

    IPrimaryMarket public primaryMarketContract;
    IERC20 public purchaseTokenContract;
    ITicketNFT public ticketNFTContract;

    constructor(address _purchaseTokenAddress, address _primaryMarketAddress, address _ticketNFTAddress) {
        purchaseTokenContract = IERC20(_purchaseTokenAddress);
        ticketNFTContract = ITicketNFT(_ticketNFTAddress);
        primaryMarketContract = IPrimaryMarket(_primaryMarketAddress);
    }

    function listTicket(uint256 _ticketId, uint256 _price) external override {
        require(ticketNFTContract.holderOf(_ticketId) == msg.sender, "You do not own this ticket");
        require(ticketNFTContract.isExpiredOrUsed(_ticketId) == false, "Ticket is expired or used");
        // Transfer ticketNFT to this contract
        ticketNFTContract.transferFrom(msg.sender, address(this), _ticketId);
        // List ticketNFT
        ticketListOriginator[_ticketId] = msg.sender;
        ticketListPrice[_ticketId] = _price;
        ticketListListed[_ticketId] = true;
        // emit event
        emit Listing(_ticketId, msg.sender, _price);
    }

    function purchase(uint256 _ticketID, string calldata _name) external override {
        require(ticketListListed[_ticketID] == true, "Ticket is not listed");
        require(ticketNFTContract.isExpiredOrUsed(_ticketID) == false, "Ticket is expired or used");
        require(purchaseTokenContract.allowance(msg.sender, address(this)) >= ticketListPrice[_ticketID], "You have not approved primaryMarket to spend your purchaseToken");

        // Transfer 5% of ERC20 tokens from buyer to the PrimaryMarket owner
        purchaseTokenContract.transferFrom(msg.sender, primaryMarketContract.admin(), ticketListPrice[_ticketID] * 5 / 100);

        // Transfer 95% of ERC20 tokens from buyer to originator
        purchaseTokenContract.transferFrom(msg.sender, ticketListOriginator[_ticketID], ticketListPrice[_ticketID] * 95 / 100);

        // Change name on ticketNFT and transfer it to buyer
        ticketNFTContract.updateHolderName(_ticketID, _name);
        ticketNFTContract.transferFrom(address(this), msg.sender, _ticketID);

        // emit event
        emit Purchase(msg.sender, _ticketID, ticketListPrice[_ticketID],  _name);
        
        // Delist ticketNFT
        ticketListListed[_ticketID] = false;
        ticketListPrice[_ticketID] = 0;
        ticketListOriginator[_ticketID] = address(0);


    }

    function delistTicket(uint256 _ticketId) external override {
        require(ticketListListed[_ticketId] == true, "Ticket is not listed");
        require(ticketListOriginator[_ticketId] == msg.sender, "You do not own this ticket");

        // Transfer ticketNFT back to originator
        ticketNFTContract.transferFrom(address(this), msg.sender, _ticketId);

        // Delist ticketNFT
        ticketListListed[_ticketId] = false;
        ticketListPrice[_ticketId] = 0;
        ticketListOriginator[_ticketId] = address(0);

        // emit event
        emit Delisting(_ticketId);

    }


}
