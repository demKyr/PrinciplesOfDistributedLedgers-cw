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
    // address public owner = makeAddr("owner");
    address public owner;
    address public primaryMarketAddress;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    // create a new account with 100 ether
    // address alice = address(new Account(100 ether));
    // add funds to Alice's account
    // payable(alice).transfer(100 ether);

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
        assertEq(purchaseToken.balanceOf(alice), 0);
    }

}