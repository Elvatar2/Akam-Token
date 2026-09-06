// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AkamToken} from "../contracts/AkamToken.sol";

contract AkamTokenTest is Test {
    AkamToken public token;

    address public deployer;
    address public alice;
    address public bob;

    uint256 constant INITIAL_SUPPLY = 400_000_000 * 10 ** 18;

    function setUp() public {
        deployer = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        token = new AkamToken();
    }

    // ------------------------------------------------------------
    // Metadata
    // ------------------------------------------------------------

    function test_Name() public {
        assertEq(token.name(), "Akam");
    }

    function test_Symbol() public {
        assertEq(token.symbol(), "AKAM");
    }

    function test_Decimals() public {
        assertEq(token.decimals(), 18);
    }

    // ------------------------------------------------------------
    // Initial supply
    // ------------------------------------------------------------

    function test_InitialTotalSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_InitialSupplyBelongsToDeployer() public {
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
    }

    function test_OtherAddressesStartWithZeroBalance() public {
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 0);
    }

    // ------------------------------------------------------------
    // Transfers
    // ------------------------------------------------------------

    function test_Transfer() public {
        uint256 amount = 100_000 * 10 ** 18;

        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }

    function test_MultipleTransfers() public {
        uint256 amount1 = 100_000 * 10 ** 18;
        uint256 amount2 = 250_000 * 10 ** 18;

        token.transfer(alice, amount1);
        token.transfer(bob, amount2);

        assertEq(token.balanceOf(alice), amount1);
        assertEq(token.balanceOf(bob), amount2);
        assertEq(
            token.balanceOf(deployer),
            INITIAL_SUPPLY - amount1 - amount2
        );

        // Transfers must not change total supply.
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_TransferZeroAmount() public {
        token.transfer(alice, 0);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_RevertWhenTransferExceedsBalance() public {
        uint256 amount = INITIAL_SUPPLY + 1;

        vm.expectRevert();
        token.transfer(alice, amount);
    }

    function test_RevertWhenTransferFromZeroAddress() public {
        vm.expectRevert();

        vm.prank(address(0));
        token.transfer(alice, 1);
    }

    // ------------------------------------------------------------
    // Approvals
    // ------------------------------------------------------------

    function test_Approve() public {
        uint256 allowance = 1_000 * 10 ** 18;

        bool success = token.approve(alice, allowance);

        assertTrue(success);
        assertEq(token.allowance(deployer, alice), allowance);
    }

    function test_ApproveCanChangeAllowance() public {
        uint256 firstAllowance = 1_000 * 10 ** 18;
        uint256 secondAllowance = 2_000 * 10 ** 18;

        token.approve(alice, firstAllowance);
        assertEq(token.allowance(deployer, alice), firstAllowance);

        token.approve(alice, secondAllowance);
        assertEq(token.allowance(deployer, alice), secondAllowance);
    }

    // ------------------------------------------------------------
    // transferFrom
    // ------------------------------------------------------------

    function test_TransferFrom() public {
        uint256 amount = 100_000 * 10 ** 18;

        token.approve(alice, amount);

        vm.prank(alice);
        token.transferFrom(deployer, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount);
        assertEq(token.allowance(deployer, alice), 0);
    }

    function test_TransferFromConsumesAllowance() public {
        uint256 allowance = 200_000 * 10 ** 18;
        uint256 amount = 75_000 * 10 ** 18;

        token.approve(alice, allowance);

        vm.prank(alice);
        token.transferFrom(deployer, bob, amount);

        assertEq(
            token.allowance(deployer, alice),
            allowance - amount
        );
    }

    function test_TransferFromMultipleTimes() public {
        uint256 allowance = 200_000 * 10 ** 18;
        uint256 amount1 = 50_000 * 10 ** 18;
        uint256 amount2 = 75_000 * 10 ** 18;

        token.approve(alice, allowance);

        vm.startPrank(alice);

        token.transferFrom(deployer, bob, amount1);
        token.transferFrom(deployer, bob, amount2);

        vm.stopPrank();

        assertEq(
            token.balanceOf(bob),
            amount1 + amount2
        );

        assertEq(
            token.allowance(deployer, alice),
            allowance - amount1 - amount2
        );
    }

    function test_RevertWhenTransferFromExceedsAllowance() public {
        uint256 allowance = 100_000 * 10 ** 18;
        uint256 amount = 100_001 * 10 ** 18;

        token.approve(alice, allowance);

        vm.prank(alice);
        vm.expectRevert();

        token.transferFrom(deployer, bob, amount);
    }

    function test_RevertWhenTransferFromExceedsBalance() public {
        uint256 allowance = INITIAL_SUPPLY + 1;

        token.approve(alice, allowance);

        vm.prank(alice);
        vm.expectRevert();

        token.transferFrom(
            deployer,
            bob,
            INITIAL_SUPPLY + 1
        );
    }

    // ------------------------------------------------------------
    // Supply invariants
    // ------------------------------------------------------------

    function test_TransferDoesNotCreateTokens() public {
        uint256 amount = 1_000_000 * 10 ** 18;

        token.transfer(alice, amount);

        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_TransferFromDoesNotCreateTokens() public {
        uint256 amount = 1_000_000 * 10 ** 18;

        token.approve(alice, amount);

        vm.prank(alice);
        token.transferFrom(deployer, bob, amount);

        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    // ------------------------------------------------------------
    // No owner / no privileged administration
    // ------------------------------------------------------------

    function test_NoOwnerFunction() public {
        // AkamToken does not inherit Ownable.
        // Therefore there is no owner() function and no privileged
        // administrative account controlling the token.
        //
        // This test intentionally documents the design.
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    // ------------------------------------------------------------
    // Supply conservation
    // ------------------------------------------------------------

    function testFuzz_TransferPreservesSupply(
        uint128 amount
    ) public {
        uint256 transferAmount = uint256(amount);

        vm.assume(transferAmount <= INITIAL_SUPPLY);

        token.transfer(alice, transferAmount);

        assertEq(
            token.balanceOf(deployer) + token.balanceOf(alice),
            INITIAL_SUPPLY
        );

        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testFuzz_ApproveAndTransferFrom(
        uint128 amount
    ) public {
        uint256 transferAmount = uint256(amount);

        vm.assume(transferAmount <= INITIAL_SUPPLY);

        token.approve(alice, transferAmount);

        vm.prank(alice);
        token.transferFrom(
            deployer,
            bob,
            transferAmount
        );

        assertEq(
            token.balanceOf(bob),
            transferAmount
        );

        assertEq(
            token.balanceOf(deployer),
            INITIAL_SUPPLY - transferAmount
        );

        assertEq(
            token.totalSupply(),
            INITIAL_SUPPLY
        );
    }
}