// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";

contract PrimaryMarketTest is Test {
    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    TicketNFT public ticketNFT;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(address(purchaseToken));
        ticketNFT = new TicketNFT();
    }

    function testAdmin() public {
        assertEq(primaryMarket.admin(), address(this));
    }

}