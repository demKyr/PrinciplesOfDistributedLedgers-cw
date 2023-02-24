// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";

contract PrimaryMarket is IPrimaryMarket {
    address public primaryMarket;
    uint256 public ticketPrice;
    uint256 public issuedTicketNFTs;
    ITicketNFT public ticketNFTContract;
    IERC20 public purchaseTokenContract;

    constructor(address purchaseTokenContractAddress) {
        purchaseTokenContract = IERC20(purchaseTokenContractAddress);
        ticketNFTContract = new TicketNFT();
        primaryMarket = msg.sender;
        ticketPrice = 100e18;
        issuedTicketNFTs = 0;
    }

    function admin() external view override returns (address) {
        return primaryMarket;
    }

    function purchase(string memory holderName) external override {
        // check if msg.sender has enough purchaseToken
        require(purchaseTokenContract.balanceOf(msg.sender) >= ticketPrice, "You do not have enough purchaseToken to purchase a ticket");
        // check if msg.sender has approved primaryMarket to spend purchaseToken
        require(purchaseTokenContract.allowance(msg.sender, primaryMarket) >= ticketPrice, "You have not approved primaryMarket to spend your purchaseToken");
        // require(purchaseTokenContract.allowance(msg.sender, address(this)) >= ticketPrice, "You have not approved primaryMarket to spend your purchaseToken"
        // check total number of issued tickets to be less than 1000
        require(issuedTicketNFTs < 1000, "All tickets have been sold");
        // transfers funds to owner from 
        purchaseTokenContract.transferFrom(msg.sender, primaryMarket, ticketPrice);
        issuedTicketNFTs++;
        // mints ticketNFT to msg.sender
        ticketNFTContract.mint(msg.sender, holderName);
        emit Purchase(msg.sender, holderName);
    }
    // costs ticketPrice
    // 





}
