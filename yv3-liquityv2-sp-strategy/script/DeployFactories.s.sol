// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {AccountantFactory} from "../src/periphery/AccountantFactory.sol";

import {StrategyFactory} from "../src/StrategyFactory.sol";
import {StakerFactory} from "../src/StakerFactory.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/DeployFactories.s.sol:DeployFactories --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract DeployFactories is Script {

    address private constant MANAGEMENT = 0x285E3b1E82f74A99D07D2aD25e159E75382bB43B; // deployer
    address private constant KEEPER = 0x604e586F17cE106B64185A7a0d2c1Da5bAce711E; // yHaaS mainnet
    address private constant EMERGENCY_ADMIN = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7; // SMS mainnet
    address private constant PERFORMANCE_FEE_RECIPIENT = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7; // SMS mainnet
    address private constant AUCTION_FACTORY = 0xa3A3702d81Fd317FA1B8735227e29dc756C976C5; // DoS resistant auction factory

    function run() external {
        uint256 _privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(_privateKey);

        address _deployer = vm.addr(_privateKey);
        require(_deployer == MANAGEMENT, "!deployer");

        AccountantFactory _accountantFactory = new AccountantFactory();
        StakerFactory _stakerFactory = new StakerFactory(MANAGEMENT, PERFORMANCE_FEE_RECIPIENT, KEEPER, EMERGENCY_ADMIN);
        StrategyFactory _strategyFactory =
            new StrategyFactory(MANAGEMENT, PERFORMANCE_FEE_RECIPIENT, KEEPER, EMERGENCY_ADMIN, AUCTION_FACTORY);

        console.log("-----------------------------");
        console.log("Deployer: ", _deployer);
        console.log("AccountantFactory deployed at: ", address(_accountantFactory));
        console.log("StakerFactory deployed at: ", address(_stakerFactory));
        console.log("StrategyFactory deployed at: ", address(_strategyFactory));
        console.log("-----------------------------");

        vm.stopBroadcast();
    }

}
