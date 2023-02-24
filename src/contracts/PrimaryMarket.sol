// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";

contract PrimaryMarket is IPrimaryMarket {
    address public ticketNFT;
    address public owner;
    uint256 public ticketPrice;
    uint256 public ticketID;

    constructor(address _ticketNFT) {
        ticketNFT = _ticketNFT;
        owner = msg.sender;
        ticketPrice = 100e18;
    }

    function buyTicket(string memory holderName) external payable override {
        require(msg.value == ticketPrice, "You must pay the ticket price");
        ticketID++;
        ITicketNFT(ticketNFT).mint(msg.sender, holderName);
    }

    // function withdraw() external {
    //     require(msg.sender == owner, "Only owner can withdraw");
    //     payable(owner).transfer(address(this).balance);
    // }

}