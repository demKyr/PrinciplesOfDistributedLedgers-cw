// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/interfaces/ITicketNFT.sol";

contract PrimaryMarketTest is Test {
    event Purchase(address indexed holder, string indexed holderName);

    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    TicketNFT public ticketNFT;
    address public owner;
    address public primaryMarketAddress;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        owner = address(this);
        // Deploy the PurchaseToken contract
        purchaseToken = new PurchaseToken();
        // Deploy the PrimaryMarket contract using the already deployed PurchaseToken contract address
        primaryMarket = new PrimaryMarket(address(purchaseToken));
        // Store the Ticket NFT contract that was deployed by the constructor of PrimaryMarket contract
        ticketNFT = TicketNFT(address(primaryMarket.ticketNFTContract()));
        // Save the address of the PrimaryMarket contract (different from the owner/Primary Market)
        primaryMarketAddress = address(primaryMarket);
    }

// TESTS FOR SUCCESS

    function testAdmin() public {
        assertEq(primaryMarket.admin(), owner);
    }

    function testPurchase() public {
        // Check that Alice has no ERC20 tokens and no NFTs
        assertEq(purchaseToken.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(alice), 0);
        // Alice mints her own ERC20 tokens
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        // Check Alice's balance in ERC20 tokens
        assertEq(purchaseToken.balanceOf(alice), 1*100e18);
        // Alice approves the PrimaryMarket contract to spend her ERC20 tokens
        assertEq(purchaseToken.allowance(alice, primaryMarketAddress), 0);
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        assertEq(purchaseToken.allowance(alice, primaryMarketAddress), 100e18);
        // Alice purchases a ticket
        vm.expectEmit(true, true, false, true);
        emit Purchase(alice, "Alice");
        vm.prank(alice);
        primaryMarket.purchase("Alice");
        // Check that Alice has 1 NFT and 0 ERC20 tokens
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(purchaseToken.balanceOf(alice), 0);
    }

// TESTS FOR FAILURES

    function testPurchaseWithoutSufficientFunds() public{
        // Alice tries to buy a ticketNFT with insufficient funds
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 0.5 ether}();
        vm.prank(alice);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(alice);
        vm.expectRevert("You do not have enough purchaseToken to purchase a ticket");
        primaryMarket.purchase("Alice");
    }

    function testPurchaseWithoutApproval() public{
        // Alice tries to buy a ticketNFT without approval
        vm.deal(alice,1 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(alice);
        vm.expectRevert("You have not approved primaryMarket to spend your purchaseToken");
        primaryMarket.purchase("Alice");
    }

    function testPurchaseAfterSoldout() public{
        // Alice buys a ticketNFT
        vm.deal(alice,1000 ether);
        vm.prank(alice);
        purchaseToken.mint{value: 1000 ether}();
        for(uint i = 0; i < 1000; i++){
            vm.prank(alice);
            purchaseToken.approve(primaryMarketAddress, 100e18);
            vm.prank(alice);
            primaryMarket.purchase("Alice");
        }
        assertEq(ticketNFT.balanceOf(alice), 1000);
        // Bob tries to buy a ticketNFT after the sale is sold out
        vm.deal(bob,1 ether);
        vm.prank(bob);
        purchaseToken.mint{value: 1 ether}();
        vm.prank(bob);
        purchaseToken.approve(primaryMarketAddress, 100e18);
        vm.prank(bob);
        vm.expectRevert("All tickets have been sold");
        primaryMarket.purchase("Bob");
    }

}