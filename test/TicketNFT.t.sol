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
        ticketNFT = new TicketNFT();
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

    function testMintAsNonOwner() public {
        vm.prank(bob);
        vm.expectRevert("Only primary market can mint");
        ticketNFT.mint(alice, "Alice");
    }

    function testHolderOfInvalidTicket() public {
        vm.expectRevert("Invalid ticketID");
        ticketNFT.holderOf(1);
    }

    function testTransferWithInvalidAdresses() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(alice);
        vm.expectRevert("Invalid 'from' address");
        ticketNFT.transferFrom(address(0x0), bob, 1);
        vm.prank(alice);
        vm.expectRevert("Invalid 'to' address");
        ticketNFT.transferFrom(alice, address(0x0), 1);
    }

    function testTransferWithoutApproval() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(bob);
        vm.expectRevert("You are not the holder of this ticket and you are not authorised to transfer it");
        ticketNFT.transferFrom(alice, bob, 1);
    }

    function testApproveAsNonHolder() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(bob);
        vm.expectRevert("You are not the holder of this ticket");
        ticketNFT.approve(bob, 1);
    }

    function testUpdateHolderNameAsNonHolder() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(bob);
        vm.expectRevert("You are not the holder of this ticket");
        ticketNFT.updateHolderName(1, "Bob");
    }

    function testSetTicketAsUsedAsNonPrimaryMarket() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.prank(bob);
        vm.expectRevert("Only primary market can set ticket as used");
        ticketNFT.setUsed(1);
    }

    function testSetTicketAsUsedForUsedTicket() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        ticketNFT.setUsed(1);
        vm.expectRevert("Ticket already used");
        ticketNFT.setUsed(1);
    }

    function testSetTicketAsUsedForExpiredTicket() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.warp(1977361197);
        vm.expectRevert("Ticket expired");
        ticketNFT.setUsed(1);
    }




}
