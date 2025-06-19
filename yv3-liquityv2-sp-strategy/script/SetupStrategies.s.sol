// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {IStrategyInterface} from "../src/interfaces/IStrategyInterface.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/SetupStrategies.s.sol:SetupStrategies --verify --legacy --rpc-url $RPC_URL --broadcast

contract SetupStrategies is Script {

    address[] private strategies = [
        0x2048A730f564246411415f719198d6f7c10A7961, // WETH Strategy
        0x46af61661B1e15DA5bFE40756495b7881F426214, // wstETH Strategy
        0x2351E217269A4a53a392bffE8195Efa1c502A1D2 // rETH Strategy
    ];

    address private constant VAULT = 0x9F4330700a36B29952869fac9b33f45EEdd8A3d8; // yBOLD

    function run() external {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategyInterface strategy = IStrategyInterface(strategies[i]);
            strategy.acceptManagement();
            strategy.setPerformanceFee(0);
            strategy.setProfitMaxUnlockTime(0);
            strategy.setAllowed(VAULT);
        }

        vm.stopBroadcast();
    }

}
