// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";

contract PrimaryMarket is IPrimaryMarket {
    address public ticketNFT;
    address public owner;
    uint256 public ticketPrice;
    uint256 public ticketID;
    ITicketNFT public ticketNFTContract;
    IERC20 public purchaseTokenContract;

    constructor(address purchaseTokenContractAddress) {
        purchaseTokenContract = IERC20(purchaseTokenContractAddress);
        ticketNFTContract = new TicketNFT();
        owner = msg.sender;
        ticketPrice = 100e18;
    }

    function admin() external view override returns (address) {
        return owner;
    }

    function purchase(string memory holderName) external override {
        ticketID++;
        ticketNFTContract.mint(msg.sender, holderName);
    }


}
