// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    uint256 private ticketID;
    mapping(uint256 => address) private holderOfTicket;
    mapping(uint256 => uint256) private expiryTimestamp;
    mapping(uint256 => bool) private ticketUsed;
    mapping(uint256 => address) private approvedOperator;
    mapping(uint256 => string) private nameOfHolder;
    mapping(address => uint256) private balanceOfHolder;
    address private primaryMarket;

    constructor() {
        primaryMarket = msg.sender;
        ticketID = 0;
    }

    function mint(address holder, string memory holderName)
        external
        override
    {
        require(msg.sender == primaryMarket, "Only primary market can mint");
        ticketID++;
        holderOfTicket[ticketID] = holder;
        nameOfHolder[ticketID] = holderName;
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

    function holderOf(uint256 _ticketID) external view override returns (address holder) {
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        return holderOfTicket[_ticketID];
    }

    function transferFrom(address from, address to, uint256 _ticketID)
        external
        override
    {
        require(from != address(0x0), "Invalid 'from' address");
        require(to != address(0x0), "Invalid 'to' address");
        require(holderOfTicket[_ticketID] == msg.sender || approvedOperator[_ticketID] == msg.sender, "You are not the holder of this ticket and you are not authorised to transfer it");
        
        holderOfTicket[_ticketID] = to;
        balanceOfHolder[from]--;
        balanceOfHolder[to]++;
        approvedOperator[_ticketID] = address(0x0);
        emit Transfer(from, to, _ticketID);
    }

    function approve(address to, uint256 _ticketID) external override {
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        require(holderOfTicket[_ticketID] == msg.sender, "You are not the holder of this ticket");
        approvedOperator[_ticketID] = to;
        emit Approval(msg.sender, to, _ticketID);
    }

    function getApproved(uint256 _ticketID) external view override returns (address operator) {
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        return approvedOperator[_ticketID];
    }


    function holderNameOf(uint256 _ticketID) external view override returns (string memory holderName) {
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        return nameOfHolder[_ticketID];
    }

    function updateHolderName(uint256 _ticketID, string calldata newName) external override{
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        require(holderOfTicket[_ticketID] == msg.sender, "You are not the holder of this ticket");
        nameOfHolder[_ticketID] = newName;
    }

    function setUsed(uint256 _ticketID) external override{
        require(msg.sender == primaryMarket, "Only primary market can set ticket as used");
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        require(ticketUsed[_ticketID] == false,"Ticket already used");
        require(block.timestamp <= expiryTimestamp[_ticketID],"Ticket expired");
        ticketUsed[_ticketID] = true;
    }
    
    function isExpiredOrUsed(uint256 _ticketID) external view returns (bool){
        require(holderOfTicket[_ticketID] != address(0x0), "Invalid ticketID");
        return(block.timestamp > expiryTimestamp[_ticketID] || ticketUsed[_ticketID] == true);
    }

}