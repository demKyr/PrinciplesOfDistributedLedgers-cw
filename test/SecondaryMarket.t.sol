// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/SecondaryMarket.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ISecondaryMarket.sol";
import "../src/interfaces/IPrimaryMarket.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/interfaces/IERC20.sol";

contract SecondaryMarketTest is Test {
    event Listing(uint256 indexed ticketID, address indexed holder, uint256 price);
    event Purchase(address indexed purchaser, uint256 indexed ticketID, uint256 price, string newName);
    event Delisting(uint256 indexed ticketID);

    SecondaryMarket public secondaryMarket;
    PrimaryMarket public primaryMarket;
    TicketNFT public ticketNFT;
    PurchaseToken public purchaseToken;

    address public owner;
    address public primaryMarketAddress;
    address public secondaryMarketAddress;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        owner = address(this);
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(address(purchaseToken));
        ticketNFT = TicketNFT(address(primaryMarket.ticketNFTContract()));            
        secondaryMarket = new SecondaryMarket(address(purchaseToken), address(primaryMarket), address(ticketNFT));
        primaryMarketAddress = address(primaryMarket);
        secondaryMarketAddress = address(secondaryMarket);
    }

// TESTS FOR SUCCESS

    function testListing() public {
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.expectEmit(true, true, true, true);
        emit Listing(1, alice, 10e18);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        // Alice is no longer the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), secondaryMarketAddress);
        assertEq(ticketNFT.balanceOf(alice), 0);
    }

    function testListingDelistingAndRelisting() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Listing(1, alice, 10e18);
        secondaryMarket.listTicket(1, 10e18);
        // Alice is no longer the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), secondaryMarketAddress);
        assertEq(ticketNFT.balanceOf(alice), 0);
        // Alice delists the ticketNFT
        vm.expectEmit(true, true, false, true);
        emit Delisting(1);
        vm.prank(alice);
        secondaryMarket.delistTicket(1);
        // Alice is the holder of the ticketNFT again
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.balanceOf(alice), 1);
        // Alice lists the ticketNFT again
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Listing(1, alice, 10e18);
        secondaryMarket.listTicket(1, 10e18);
        // Alice is again no longer the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), secondaryMarketAddress);
        assertEq(ticketNFT.balanceOf(alice), 0);
    }

    function testPurchase() public {
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100 * 1e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10 * 1e18);
        // Alice is no longer the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), secondaryMarketAddress);
        assertEq(ticketNFT.balanceOf(alice), 0);
        // Bob buys the ticketNFT
        vm.deal(bob, 0.1 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 0.1 ether}();
        vm.prank(bob);
        purchaseToken.approve(secondaryMarketAddress, 10 * 1e18);
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Purchase(bob, 1, 10e18, "Bob");
        secondaryMarket.purchase(1, "Bob");
        // Bob is the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), bob);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.holderNameOf(1), "Bob");
        // Balances are correct
        assertEq(purchaseToken.balanceOf(bob), 0);
        assertEq(purchaseToken.balanceOf(alice), 9.5 * 1e18);
        assertEq(purchaseToken.balanceOf(owner), 0.5 * 1e18 + 100 * 1e18);
    }

// TESTS FOR FAILURES

    function testListingSameTicketTwice() public {
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        // Alice is no longer the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), secondaryMarketAddress);
        assertEq(ticketNFT.balanceOf(alice), 0);
        // Alice tries to list the ticketNFT again
        vm.prank(alice);
        vm.expectRevert("You do not own this ticket");
        secondaryMarket.listTicket(1, 10e18);
    }

    function testListingUsedTicket() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Ticket is set as used
        vm.prank(primaryMarketAddress);
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        // Alice tries to list the ticketNFT 
        vm.prank(alice);
        vm.expectRevert("Ticket is expired or used");
        secondaryMarket.listTicket(1, 10e18);
    }

    function testListingExpiredTicket() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Ticket is set as expired
        vm.warp(1977361197);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        // Alice tries to list the ticketNFT 
        vm.prank(alice);
        vm.expectRevert("Ticket is expired or used");
        secondaryMarket.listTicket(1, 10e18);
    }

    function testDelistNonListedTicket() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice tries to delist the ticketNFT 
        vm.prank(alice);
        vm.expectRevert("Ticket is not listed");
        secondaryMarket.delistTicket(1);
    }

    function testDelistTicketAsNonHolder() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        // Alice is no longer the holder of the ticketNFT
        assertEq(ticketNFT.holderOf(1), secondaryMarketAddress);
        assertEq(ticketNFT.balanceOf(alice), 0);
        // Bob tries to delist the ticketNFT 
        vm.prank(bob);
        vm.expectRevert("You do not own this ticket");
        secondaryMarket.delistTicket(1);
    }

    function testPurchaseNonListedTicket() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Bob tries to buy the ticketNFT
        vm.deal(bob, 0.1 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 0.1 ether}();
        vm.prank(bob);
        purchaseToken.approve(secondaryMarketAddress, 10e18);
        vm.prank(bob);
        vm.expectRevert("Ticket is not listed");
        secondaryMarket.purchase(1, "Bob");
    }

    function testPurchaseUsedTicket() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        // Ticket is set as used
        vm.prank(primaryMarketAddress);
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        // Bob tries to buy the ticketNFT
        vm.deal(bob, 0.1 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 0.1 ether}();
        vm.prank(bob);
        purchaseToken.approve(secondaryMarketAddress, 10e18);
        vm.prank(bob);
        vm.expectRevert("Ticket is expired or used");
        secondaryMarket.purchase(1, "Bob");
    }

    function testPurchaseExpiredTicket() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        // Ticket is set as expired
        vm.warp(1977361197);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        // Bob tries to buy the ticketNFT
        vm.deal(bob, 0.1 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 0.1 ether}();
        vm.prank(bob);
        purchaseToken.approve(secondaryMarketAddress, 10e18);
        vm.prank(bob);
        vm.expectRevert("Ticket is expired or used");
        secondaryMarket.purchase(1, "Bob");
    }

    function testPurchaseWithoutApproval() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        // Alice lists the ticketNFT
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        // Bob tries to buy the ticketNFT
        vm.deal(bob, 0.1 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 0.1 ether}();
        vm.prank(bob);
        vm.expectRevert("You have not approved primaryMarket to spend your purchaseToken");
        secondaryMarket.purchase(1, "Bob");
    }

// FINAL TEST
    function testFinal() public{
        // Alice buys two ticketNFTs
        vm.deal(alice,2 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 2 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 200e18);
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderOf(2), alice);
        // Alice lists the ticketNFTs
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(alice);
        ticketNFT.approve(secondaryMarketAddress, 2);
        vm.prank(alice);
        secondaryMarket.listTicket(1, 10e18);
        vm.prank(alice);
        secondaryMarket.listTicket(2, 10e18);
        // Bob buys the ticketNFTs
        vm.deal(bob, 0.2 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 0.2 ether}();
        vm.prank(bob);
        purchaseToken.approve(secondaryMarketAddress, 20e18);
        vm.prank(bob);
        secondaryMarket.purchase(1, "Bob");
        vm.prank(bob);
        secondaryMarket.purchase(2, "Bob");
        assertEq(ticketNFT.holderOf(1), bob);
        assertEq(ticketNFT.holderOf(2), bob);
        // Bob lists the ticketNFTs
        vm.prank(bob);
        ticketNFT.approve(secondaryMarketAddress, 1);
        vm.prank(bob);
        ticketNFT.approve(secondaryMarketAddress, 2);
        vm.prank(bob);
        secondaryMarket.listTicket(1, 10e18);
        vm.prank(bob);
        secondaryMarket.listTicket(2, 10e18);
        // Alice buys the ticketNFTs
        vm.deal(alice, 0.2 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 0.2 ether}();
        vm.prank(alice);
        purchaseToken.approve(secondaryMarketAddress, 20e18);
        vm.prank(alice);
        secondaryMarket.purchase(1, "Alice");
        vm.prank(alice);
        secondaryMarket.purchase(2, "Alice");
        // Check that the ticketNFTs are owned by Alice
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderOf(2), alice);
        assertEq(ticketNFT.balanceOf(bob), 0);
        // Check that final balances are correct
        assertEq(purchaseToken.balanceOf(bob), 2 * 9.5 * 1e18);
        assertEq(purchaseToken.balanceOf(alice), 2 * 9.5 * 1e18);
        assertEq(purchaseToken.balanceOf(owner), 4 * 0.5 * 1e18 + 2 * 100 * 1e18);
    }

}
