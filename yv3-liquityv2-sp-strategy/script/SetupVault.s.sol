// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {IVault} from "@yearn-vaults/interfaces/IVault.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/SetupVault.s.sol:SetupVault --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract SetupVault is Script {

    address[] private strategies = [
        0x2048A730f564246411415f719198d6f7c10A7961, // WETH Strategy
        0x46af61661B1e15DA5bFE40756495b7881F426214, // wstETH Strategy
        0x2351E217269A4a53a392bffE8195Efa1c502A1D2 // rETH Strategy
    ];

    address private constant MANAGEMENT = 0x285E3b1E82f74A99D07D2aD25e159E75382bB43B; // deployer
    address private constant KEEPER = 0x604e586F17cE106B64185A7a0d2c1Da5bAce711E; // yHaaS mainnet
    address public constant ROLE_MANAGER = 0xb3bd6B2E61753C311EFbCF0111f75D29706D9a41;
    address private constant ACCOUNTANT = 0x53acEBB9470Cfc9D231075154f5dcF1586A4c6fa; // yBOLD Accountant

    IVault public constant VAULT = IVault(0x9F4330700a36B29952869fac9b33f45EEdd8A3d8); // yBOLD

    function run() external {
        uint256 _privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(_privateKey);

        address _deployer = vm.addr(_privateKey);
        require(_deployer == MANAGEMENT, "!deployer");

        VAULT.set_role(MANAGEMENT, 16383); // ADD_STRATEGY_MANAGER/DEPOSIT_LIMIT_MANAGER/MAX_DEBT_MANAGER/DEBT_MANAGER
        VAULT.set_role(KEEPER, 32); // REPORTING_MANAGER
        VAULT.set_deposit_limit(100_000_000_000 ether); // 100 billion
        VAULT.set_accountant(ACCOUNTANT);
        for (uint256 i = 0; i < strategies.length; i++) {
            VAULT.add_strategy(strategies[i]);
            VAULT.update_max_debt_for_strategy(strategies[i], 10_000_000_000 ether); // 10 billion
        }
        VAULT.transfer_role_manager(ROLE_MANAGER);

        vm.stopBroadcast();
    }

}
