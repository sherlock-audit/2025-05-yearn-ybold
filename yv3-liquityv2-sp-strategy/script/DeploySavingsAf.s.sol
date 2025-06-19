// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {IVault} from "@yearn-vaults/interfaces/IVault.sol";
import {IVaultFactory} from "@yearn-vaults/interfaces/IVaultFactory.sol";

import {IStrategyInterface} from "../src/interfaces/IStrategyInterface.sol";

import {StrategyFactory} from "../src/StrategyFactory.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/DeploySavingsAf.s.sol:DeploySavingsAf --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract DeploySavingsAf is Script {

    address[] public strategies;

    string private constant NAME = "Savings USDaf";
    string private constant SYMBOL = "sUSDaf";

    address private constant ASSET = 0x85E30b8b263bC64d94b827ed450F2EdFEE8579dA; // USDaf
    address private constant DEPLOYER = 0x285E3b1E82f74A99D07D2aD25e159E75382bB43B; // deployer
    address private constant SMS = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7; // sms mainnet
    address private constant KEEPER = 0x604e586F17cE106B64185A7a0d2c1Da5bAce711E; // yHaaS mainnet
    address private constant ROLE_MANAGER = 0xb3bd6B2E61753C311EFbCF0111f75D29706D9a41;

    StrategyFactory private constant STRATEGY_FACTORY = StrategyFactory(0x73dfCc4fB90E6e252E5D41f6588534a8043dBa58);
    IVaultFactory private constant VAULT_FACTORY = IVaultFactory(0x770D0d1Fb036483Ed4AbB6d53c1C88fb277D812F); // 3.0.4 Vault Factory

    function run() external {
        uint256 _privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(_privateKey);

        address _deployer = vm.addr(_privateKey);
        require(_deployer == DEPLOYER, "!deployer");

        address _scrvUSDStrategy = STRATEGY_FACTORY.newStrategy(
            address(0x16B8111A999A9bDC3181192620A8F7b2439837Dd), // scrvUSD Address Registry
            ASSET,
            "USDaf scrvUSD Stability Pool"
        );
        strategies.push(_scrvUSDStrategy);

        address _sDAIStrategy = STRATEGY_FACTORY.newStrategy(
            address(0x65799d1368Ed24125179dd6Bf5e9b845797Ca1Ba), // sDAI Address Registry
            ASSET,
            "USDaf sDAI Stability Pool"
        );
        strategies.push(_sDAIStrategy);

        address _sUSDSStrategy = STRATEGY_FACTORY.newStrategy(
            address(0x7f32320669e22380d00b28492E4479b93872d568), // sUSDS Address Registry
            ASSET,
            "USDaf sUSDS Stability Pool"
        );
        strategies.push(_sUSDSStrategy);

        address _sfrxUSDStrategy = STRATEGY_FACTORY.newStrategy(
            address(0x4B3eb2b1bBb0134D5ED5DAA35FeA78424B9481cd), // sfrxUSD Address Registry
            ASSET,
            "USDaf sfrxUSD Stability Pool"
        );
        strategies.push(_sfrxUSDStrategy);

        address _sUSDeStrategy = STRATEGY_FACTORY.newStrategy(
            address(0x20E3630D9ce22c7f3A4aee735fa007C06f4709dF), // sUSDe Address Registry
            ASSET,
            "USDaf sUSDe Stability Pool"
        );
        strategies.push(_sUSDeStrategy);

        address _tBTCStrategy = STRATEGY_FACTORY.newStrategy(
            address(0xc693C91c855f4B51957f8ea221534538232F0f98), // tBTC Address Registry
            ASSET,
            "USDaf tBTC Stability Pool"
        );
        strategies.push(_tBTCStrategy);

        address _WBTC18Strategy = STRATEGY_FACTORY.newStrategy(
            address(0x2AFF30744843aF04F68286Fa4818d44e93b80561), // WBTC18 Address Registry
            ASSET,
            "USDaf WBTC18 Stability Pool"
        );
        strategies.push(_WBTC18Strategy);

        address _cbBTC18Strategy = STRATEGY_FACTORY.newStrategy(
            address(0x0F7Eb92d20e9624601D7dD92122AEd80Efa8ec6a), // cbBTC18 Address Registry
            ASSET,
            "USDaf cbBTC18 Stability Pool"
        );
        strategies.push(_cbBTC18Strategy);

        IVault _vault = IVault(VAULT_FACTORY.deploy_new_vault(ASSET, NAME, SYMBOL, DEPLOYER, 3 days));
        _vault.set_role(DEPLOYER, 16383); // ADD_STRATEGY_MANAGER/DEPOSIT_LIMIT_MANAGER/MAX_DEBT_MANAGER/DEBT_MANAGER
        _vault.set_role(KEEPER, 32); // REPORTING_MANAGER
        _vault.set_deposit_limit(100_000_000_000 ether); // 100 billion
        for (uint256 i = 0; i < strategies.length; i++) {
            _vault.add_strategy(strategies[i]);
            _vault.update_max_debt_for_strategy(strategies[i], 10_000_000_000 ether); // 10 billion
        }
        _vault.transfer_role_manager(ROLE_MANAGER);
        _vault.set_role(DEPLOYER, 0);

        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategyInterface strategy = IStrategyInterface(strategies[i]);
            strategy.acceptManagement();
            strategy.setProfitMaxUnlockTime(3 days);
            strategy.setAllowed(address(_vault));
            strategy.setPendingManagement(SMS);
            require(strategy.performanceFee() == 1000, "!fee");
        }

        vm.stopBroadcast();

        console.log("-----------------------------");
        console.log("scrvUSD Strategy deployed at: ", _scrvUSDStrategy);
        console.log("sDAI Strategy deployed at: ", _sDAIStrategy);
        console.log("sUSDS Strategy deployed at: ", _sUSDSStrategy);
        console.log("sfrxUSD Strategy deployed at: ", _sfrxUSDStrategy);
        console.log("sUSDe Strategy deployed at: ", _sUSDeStrategy);
        console.log("tBTC Strategy deployed at: ", _tBTCStrategy);
        console.log("WBTC18 Strategy deployed at: ", _WBTC18Strategy);
        console.log("cbBTC18 Strategy deployed at: ", _cbBTC18Strategy);
        console.log("sUSDaf deployed at: ", address(_vault));
        console.log("-----------------------------");
    }

}
