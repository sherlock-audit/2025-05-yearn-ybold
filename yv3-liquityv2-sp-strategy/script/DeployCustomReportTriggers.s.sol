// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {VaultFixedReportTrigger} from "../src/periphery/VaultFixedReportTrigger.sol";
import {StrategyFixedReportTrigger} from "../src/periphery/StrategyFixedReportTrigger.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/DeployCustomReportTriggers.s.sol:DeployCustomReportTriggers --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract DeployCustomReportTriggers is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        VaultFixedReportTrigger _vaultReportTrigger = new VaultFixedReportTrigger();
        StrategyFixedReportTrigger _strategyReportTrigger = new StrategyFixedReportTrigger();

        console.log("-----------------------------");
        console.log("vaultReportTrigger:", address(_vaultReportTrigger));
        console.log("strategyReportTrigger:", address(_strategyReportTrigger));
        console.log("-----------------------------");

        vm.stopBroadcast();
    }

}
