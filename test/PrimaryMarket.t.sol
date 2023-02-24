// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";

contract PrimaryMarketTest is Test {
    event Purchase(address indexed holder, string indexed holderName);

    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    TicketNFT public ticketNFT;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    // create a new account with 100 ether
    // address alice = address(new Account(100 ether));
    // add funds to Alice's account
    // payable(alice).transfer(100 ether);

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(address(purchaseToken));
        ticketNFT = new TicketNFT();
    }

    function testAdmin() public {
        assertEq(primaryMarket.admin(), address(this));
    }

    function testPurchase() public {
        // assertEq(primaryMarket.issuedTicketNFTs(), 0);
        assertEq(purchaseToken.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(purchaseToken.balanceOf(address(primaryMarket)), 0);

        purchaseToken.mint{value: 10 ether}();
        // assertGe(purchaseToken.balanceOf(alice), 1 ether);
        // assertGe(purchaseToken.balanceOf(address(primaryMarket)), 1 ether);
        assertEq(purchaseToken.balanceOf(address(this)), 1000e18 );
        vm.prank(alice);
        purchaseToken.mint{value: 10 ether}();
        assertEq(purchaseToken.balanceOf(alice), 1000e18);

        // assertEq(purchaseToken.balanceOf(alice), 10 ether);
        // assertEq(purchaseToken.balanceOf(address(primaryMarket)), 10 ether);

        // purchaseToken.approve(address(primaryMarket), 100e18);

        // vm.expectEmit(true, true, false, true);
        // emit Purchase(alice, "Alice");
        // primaryMarket.purchase("Alice");
        // // assertEq(primaryMarket.issuedTicketNFTs(), 1);
        // assertEq(ticketNFT.balanceOf(alice), 1);
        // // assertEq(purchaseToken.balanceOf(alice), 0);
        // assertEq(purchaseToken.balanceOf(address(primaryMarket)), 100e18);
    }

}