// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {StrategyFactory} from "../src/StrategyFactory.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/DeployStrategies.s.sol:DeployStrategies --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract DeployStrategies is Script {

    address public constant ASSET = 0x6440f144b7e50D6a8439336510312d2F54beB01D; // BOLD

    StrategyFactory public constant STRATEGY_FACTORY = StrategyFactory(0x73dfCc4fB90E6e252E5D41f6588534a8043dBa58);

    function run() external {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        address _wethAddressesRegistry = address(0x20F7C9ad66983F6523a0881d0f82406541417526); // WETH Address Registry
        address _wethStrategy =
            STRATEGY_FACTORY.newStrategy(_wethAddressesRegistry, ASSET, "Liquity V2 WETH Stability Pool");

        address _wstethAddressesRegistry = address(0x8d733F7ea7c23Cbea7C613B6eBd845d46d3aAc54); // wstETH Address Registry
        address _wstethStrategy =
            STRATEGY_FACTORY.newStrategy(_wstethAddressesRegistry, ASSET, "Liquity V2 wstETH Stability Pool");

        address _rethAddressesRegistry = address(0x6106046F031a22713697e04C08B330dDaf3e8789); // rETH Address Registry
        address _rethStrategy =
            STRATEGY_FACTORY.newStrategy(_rethAddressesRegistry, ASSET, "Liquity V2 rETH Stability Pool");

        vm.stopBroadcast();

        console.log("-----------------------------");
        console.log("WETH Strategy deployed at: ", _wethStrategy);
        console.log("wstETH Strategy deployed at: ", _wstethStrategy);
        console.log("rETH Strategy deployed at: ", _rethStrategy);
        console.log("-----------------------------");
    }

}
