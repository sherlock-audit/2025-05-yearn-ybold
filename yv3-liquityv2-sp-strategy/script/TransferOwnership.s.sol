// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {IVault} from "@yearn-vaults/interfaces/IVault.sol";
import {IStrategyInterface} from "../src/interfaces/IStrategyInterface.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/TransferOwnership.s.sol:TransferOwnership --verify --legacy --rpc-url $RPC_URL --broadcast

contract TransferOwnership is Script {

    address private constant OLD_MANAGEMENT = 0x285E3b1E82f74A99D07D2aD25e159E75382bB43B; // deployer
    address private constant NEW_MANAGEMENT = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7; // sms mainnet

    IVault public constant VAULT = IVault(0x9F4330700a36B29952869fac9b33f45EEdd8A3d8); // yBOLD
    IStrategyInterface public constant STAKER = IStrategyInterface(0x23346B04a7f55b8760E5860AA5A77383D63491cD); // st-yBOLD

    // on yBOLD/st-yBOLD
    function run() external {
        uint256 _privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(_privateKey);

        address _deployer = vm.addr(_privateKey);
        require(_deployer == OLD_MANAGEMENT, "!deployer");

        VAULT.set_role(OLD_MANAGEMENT, 0);

        STAKER.acceptManagement();
        STAKER.setPendingManagement(NEW_MANAGEMENT);

        vm.stopBroadcast();
    }

}

// // @todo -- factories etc

// bold -- ybold -- stybold - 4626 router -- https://github.com/yearn/Yearn-ERC4626-Router/tree/master/src

// cant go out?

// use this ? -- https://github.com/Bearn-Sucks/yBGT/blob/master/src/periphery/YBeraZapper.sol
