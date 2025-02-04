// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import {Constants} from "../src/Constants.sol";
import {Test} from "../src/Test.sol";

contract ConstantsTest is Test {
    function testVm() public view {
        assertEq(Constants.VM.getBlockNumber(), 1);
    }

    function testVmDerivation() public pure {
        assertEq(address(Constants.VM), address(uint160(uint256(keccak256("hevm cheat code")))));
    }

    function testConsoleDerivation() public pure {
        assertEq(Constants.CONSOLE, address(uint160(uint88(bytes11("console.log")))));
    }

    function testDefaultSender() public view {
        assertEq(Constants.DEFAULT_SENDER, msg.sender);
    }

    function testDefaultSenderDerivation() public pure {
        assertEq(Constants.DEFAULT_SENDER, address(uint160(uint256(keccak256("foundry default caller")))));
    }

    function testDefaultTestContract() public {
        assertEq(Constants.DEFAULT_TEST_CONTRACT, address(new Dummy()));
    }

    function testDefaultTestContractDerivation() public view {
        assertEq(address(this), Constants.VM.computeCreateAddress(Constants.DEFAULT_SENDER, 1));
        assertEq(Constants.DEFAULT_TEST_CONTRACT, Constants.VM.computeCreateAddress(address(this), 1));
    }
}

contract Dummy {}
