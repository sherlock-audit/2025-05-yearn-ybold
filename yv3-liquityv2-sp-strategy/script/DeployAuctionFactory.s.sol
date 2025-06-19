// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {AuctionFactory} from "../src/periphery/AuctionFactory.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/DeployAuctionFactory.s.sol:DeployAuctionFactory --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract DeployAuctionFactory is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        AuctionFactory _factory = new AuctionFactory();

        console.log("-----------------------------");
        console.log("factory deployed at: ", address(_factory));
        console.log("-----------------------------");

        vm.stopBroadcast();
    }

}
