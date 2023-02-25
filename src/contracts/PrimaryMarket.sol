// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";


contract PrimaryMarket is IPrimaryMarket {
    event Log(string message, address value);
    
    address public primaryMarket;
    uint256 public ticketPrice;
    uint256 public issuedTicketNFTs;
    // TicketNFT public ticketNFTContract;
    // PurchaseToken public purchaseTokenContract;
    ITicketNFT public ticketNFTContract;
    IERC20 public purchaseTokenContract;

    // constructor(PurchaseToken _purchaseTokenContract) {
    constructor(address purchaseTokenContractAddress) {
        purchaseTokenContract = IERC20(purchaseTokenContractAddress);
        // ticketNFTContract = new TicketNFT();
        // purchaseTokenContract = _purchaseTokenContract;
        // purchaseTokenContract = PurchaseToken(purchaseTokenContractAddress);
        ticketNFTContract = new TicketNFT();
        primaryMarket = msg.sender;
        ticketPrice = 100e18;
        issuedTicketNFTs = 0;
    }

    function admin() external view override returns (address) {
        return primaryMarket;
    }

    function purchase(string memory holderName) external override {
        emit Log("address(this)", address(this));
        emit Log("msg.sender", msg.sender);
        emit Log("primaryMarket", primaryMarket);
        emit Log("purchaseTokenContract", address(purchaseTokenContract));
        emit Log("ticketNFTContract", address(ticketNFTContract));
        // check if msg.sender has enough purchaseToken
        require(purchaseTokenContract.balanceOf(msg.sender) >= ticketPrice, "You do not have enough purchaseToken to purchase a ticket");
        // check if msg.sender has approved primaryMarket to spend purchaseToken
        // require(purchaseTokenContract.allowance(msg.sender, primaryMarket) >= ticketPrice, "You have not approved primaryMarket to spend your purchaseToken");
        require(purchaseTokenContract.allowance(msg.sender, address(this)) >= ticketPrice, "You have not approved primaryMarket to spend your purchaseToken");
        // check total number of issued tickets to be less than 1000
        require(issuedTicketNFTs < 1000, "All tickets have been sold");
        // transfers funds to owner from 
        purchaseTokenContract.transferFrom(msg.sender, primaryMarket, ticketPrice);
        issuedTicketNFTs++;
        // mints ticketNFT to msg.sender
        ticketNFTContract.mint(msg.sender, holderName);
        emit Purchase(msg.sender, holderName);
    }

    function returnMsgsender() external view returns (address) {
        return msg.sender;
    }
    // costs ticketPrice
    // 





}
