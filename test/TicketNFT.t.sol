// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";

contract TicketNFTTest is Test {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed ticketID
    );

    event Approval(
        address indexed holder,
        address indexed approved,
        uint256 indexed ticketID
    );

    TicketNFT public ticketNFT;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        ticketNFT = new TicketNFT(address(this));
    }

    function testMint() public {
        assertEq(ticketNFT.balanceOf(alice), 0);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
    }

    function testTransfer() public {
        ticketNFT.mint(alice, "Alice");
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
    }
}
