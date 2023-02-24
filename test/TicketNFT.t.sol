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

// TESTS FOR SUCCESS

    function testMint() public {
        assertEq(ticketNFT.balanceOf(alice), 0);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
    }

    function testTransfer() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, 1);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
    }

    function testApprovedTransfer() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        assertEq(ticketNFT.getApproved(1), bob);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, charlie, 1);
        ticketNFT.transferFrom(alice, charlie, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(charlie), 1);
    }

    function testUpdateHolderName() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.holderNameOf(1), "Alice");
        vm.prank(alice);
        ticketNFT.updateHolderName(1, "Bob");
        assertEq(ticketNFT.holderNameOf(1), "Bob");
    }

    function testUpdateHolderAfterSelfTransferingTicketWithApproval() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, 1);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.holderOf(1), bob);
        vm.prank(bob);
        ticketNFT.updateHolderName(1, "Bob");
        assertEq(ticketNFT.holderNameOf(1), "Bob");
    }

    function testSetTicketToUsed() public{
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.isExpiredOrUsed(1), false);
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
    } 

// TESTS FOR FAILURES

    function testUpdateHolderNameAsNonHolder() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(bob);
        vm.expectRevert("You are not the holder of this ticket");
        ticketNFT.updateHolderName(1, "Bob");
    }

    // function testInvalidTicketIDandAddresses() public {
    //     vm.expectEmit(true, true, false, true);
    //     emit Transfer(address(0), alice, 1);
    //     ticketNFT.mint(alice, "Alice");
    //     vm.prank(alice);
    //     vm.expectRevert("Ticket ID is invalid");
    //     ticketNFT.updateHolderName(2, "Bob");
    //     vm.prank(bob);
    //     vm.expectRevert("You are not the holder of this ticket");
    //     ticketNFT.updateHolderName(1, "Bob");
    // }



}
