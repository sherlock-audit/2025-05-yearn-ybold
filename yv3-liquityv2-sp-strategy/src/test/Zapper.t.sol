pragma solidity ^0.8.18;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import "forge-std/console2.sol";
import {ERC20, Setup} from "./utils/Setup.sol";

import {Zapper} from "../periphery/Zapper.sol";

contract ZapperTest is Setup {

    Zapper public zapper;

    function setUp() public override {
        super.setUp();

        zapper = new Zapper();
    }

    function test_zapIn(uint256 _amount, address _receiver) public returns (uint256 _shares) {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_receiver != address(0));

        IERC4626 _staker = zapper.STAKED_YEARN_BOLD();

        airdrop(asset, user, _amount);

        vm.startPrank(user);

        // Approve BOLD to the zapper
        asset.approve(address(zapper), _amount);

        uint256 _expectedSharesOut = zapper.previewDeposit(_amount);

        // Zap in
        _shares = zapper.zapIn(_amount, _receiver);

        // Check balances
        assertEq(asset.balanceOf(user), 0);
        assertEq(asset.balanceOf(address(zapper)), 0);
        assertEq(_staker.balanceOf(address(zapper)), 0);
        assertEq(_shares, _expectedSharesOut);
        assertEq(_staker.balanceOf(_receiver), _shares);

        // Check allowances
        assertEq(asset.allowance(address(zapper), address(zapper.YEARN_BOLD())), type(uint256).max);
        assertEq(zapper.YEARN_BOLD().allowance(address(zapper), address(zapper.STAKED_YEARN_BOLD())), type(uint256).max);

        vm.stopPrank();
    }

    function test_zapOut(uint256 _amount, address _receiver, address _secondReceiver) public {
        vm.assume(_secondReceiver != address(0));

        uint256 _shares = test_zapIn(_amount, _receiver);

        vm.startPrank(_receiver);

        IERC4626 _staker = zapper.STAKED_YEARN_BOLD();

        // Approve zapper to spend st-yBOLD
        _staker.approve(address(zapper), _shares);

        uint256 _expectedAssetsOut = zapper.previewRedeem(_shares);

        // Zap out
        uint256 _assets = zapper.zapOut(_shares, _secondReceiver, 0);

        // Check balances
        assertEq(asset.balanceOf(_secondReceiver), _assets);
        assertEq(asset.balanceOf(address(zapper)), 0);
        assertEq(asset.balanceOf(_receiver), 0);
        assertEq(_staker.balanceOf(address(zapper)), 0);
        assertEq(_assets, _expectedAssetsOut);
        assertEq(_staker.balanceOf(_receiver), 0);

        vm.stopPrank();
    }

    function test_sweep(uint256 _amount, address _receiver, address _notSMS) external {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_receiver != address(0) && _notSMS != zapper.SMS());

        ERC20 _asset = ERC20(tokenAddrs["YFI"]);
        airdrop(_asset, address(zapper), _amount);

        uint256 _balanceBefore = _asset.balanceOf(_receiver);

        vm.startPrank(zapper.SMS());
        zapper.sweep(_asset, _receiver);
        vm.stopPrank();

        assertEq(_asset.balanceOf(_receiver), _balanceBefore + _amount);
        assertEq(_asset.balanceOf(address(zapper)), 0);

        vm.startPrank(zapper.SMS());
        vm.expectRevert("!receiver");
        zapper.sweep(_asset, address(0));
        vm.expectRevert("!balance");
        zapper.sweep(_asset, _receiver);
        vm.stopPrank();

        vm.expectRevert(); // "!SMS"
        vm.prank(_notSMS);
        zapper.sweep(_asset, _receiver);
    }

}
