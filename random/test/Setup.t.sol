// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Setup} from "../src/Setup.sol";
import {Random} from "../src/Random.sol";

contract SetupTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Setup internal setup;

    function setUp() public {
        setup = new Setup();
    }

    function testExample() public {
        Random random = setup.random();
        random.solve(4);
        assertTrue(random.solved());
    }
}
