// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    address public primaryMarket;
    uint256 public ticketID;
    mapping(uint256 => address) public holderOfTicket;
    mapping(address => uint256) public balanceOfHolder;

    constructor(address _primaryMarket) {
        primaryMarket = _primaryMarket;
    }

    function mint(address holder, string memory holderName)
        external
        override
    {
        require(msg.sender == primaryMarket, "Only primary market can mint");
        ticketID++;
        holderOfTicket[ticketID] = holder;
        balanceOfHolder[holder]++;
        emit Transfer(address(0), holder, ticketID);
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        return balanceOfHolder[holder];
    }

    function holderOf(uint256 ticketID) external view override returns (address holder) {
        return holderOfTicket[ticketID];
    }

    function transferFrom(address from, address to, uint256 ticketID)
        external
        override
    {
        require(holderOfTicket[ticketID] == from, "You are not the holder of this ticket");
        holderOfTicket[ticketID] = to;
        balanceOfHolder[from]--;
        balanceOfHolder[to]++;
        emit Transfer(from, to, ticketID);
    }

    function approve(address approved, uint256 ticketID) external override {
        require(holderOfTicket[ticketID] == msg.sender, "You are not the holder of this ticket");
        emit Approval(msg.sender, approved, ticketID);
    }
}