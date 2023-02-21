// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    uint256 public ticketID;
    mapping(uint256 => address) public holderOfTicket;
    mapping(uint256 => uint256) public expiryTimestamp;
    mapping(uint256 => bool) public ticketUsed;
    mapping(uint256 => address) public approvedOperator;
    mapping(address => string) public nameOfHolder;
    mapping(address => uint256) public balanceOfHolder;


    address public primaryMarket;

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
        nameOfHolder[holder] = holderName;
        // NAME OF HOLDER SHOULD BE STORED ON TICKET OR ON ADDRESS
        expiryTimestamp[ticketID] = block.timestamp + 10 * 86400;
        ticketUsed[ticketID] = false;
        approvedOperator[ticketID] = address(0x0);
        balanceOfHolder[holder]++;
        emit Transfer(address(0), holder, ticketID);
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        return balanceOfHolder[holder];
    }

    function holderOf(uint256 ticketID) external view override returns (address holder) {
        require(holderOfTicket[ticketID] != address(0x0), "Invalid ticketID");
        return holderOfTicket[ticketID];
    }

    function transferFrom(address from, address to, uint256 ticketID)
        external
        override
    {
        require(from != address(0x0), "Invalid 'from' address");
        require(to != address(0x0), "Invalid 'to' address");
        require(holderOfTicket[ticketID] == from || approvedOperator[ticketID] == from, "You are not the holder of this ticket and you are not authorised to transfer it");
        
        holderOfTicket[ticketID] = to;
        balanceOfHolder[from]--;
        balanceOfHolder[to]++;
        approvedOperator[ticketID] = address(0x0);
        emit Transfer(from, to, ticketID);
    }

    function approve(address to, uint256 ticketID) external override {
        require(holderOfTicket[ticketID] != address(0x0), "Invalid ticketID");
        require(holderOfTicket[ticketID] == msg.sender, "You are not the holder of this ticket");
        approvedOperator[ticketID] = to;
        emit Approval(msg.sender, to, ticketID);
    }

    // getApproved

    function holderNameOf(uint256 ticketID) external view override returns (address operator) {
        require(holderOfTicket[ticketID] != address(0x0), "Invalid ticketID");
        return nameOfHolder[holderOfTicket[ticketID]];
    }

    // updateHolderName
    // setUsed
    // isExpiredOrUsed


}