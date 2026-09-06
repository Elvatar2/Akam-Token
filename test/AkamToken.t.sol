// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AkamToken} from "../contracts/AkamToken.sol";

contract AkamTokenTest is Test {
    AkamToken public token;
    address public deployer;
    address public user;

    function setUp() public {
        deployer = address(this);
        user = makeAddr("user");
        token = new AkamToken();
    }

    function test_Name() public view {
        assertEq(token.name(), "Akam");
    }

    function test_Symbol() public view {
        assertEq(token.symbol(), "AKM");
    }

    function test_Decimals() public view {
        assertEq(token.decimals(), 18);
    }

    function test_TotalSupply() public view {
        assertEq(token.totalSupply(), 400_000_000 * 10**18);
    }

    function test_DeployerBalance() public view {
        assertEq(token.balanceOf(deployer), 400_000_000 * 10**18);
    }

    function test_Transfer() public {
        uint256 amount = 100_000 * 10**18;
        token.transfer(user, amount);
        
        assertEq(token.balanceOf(user), amount);
        assertEq(token.balanceOf(deployer), 400_000_000 * 10**18 - amount);
    }

    function test_TransferFails() public {
        uint256 amount = 400_000_001 * 10**18;
        vm.expectRevert();
        token.transfer(user, amount);
    }
}