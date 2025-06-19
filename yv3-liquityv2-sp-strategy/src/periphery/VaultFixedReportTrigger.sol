// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {CustomVaultTriggerBase} from "@periphery/ReportTrigger/CustomVaultTriggerBase.sol";
import {IVault} from "@yearn-vaults/interfaces/IVault.sol";

import {ICommonReportTrigger} from "../interfaces/ICommonReportTrigger.sol";

contract VaultFixedReportTrigger is CustomVaultTriggerBase {

    // ===============================================================
    // Storage
    // ===============================================================

    /// @notice Minimum delay between reports
    uint256 public minReportDelay;

    // ===============================================================
    // Constants
    // ===============================================================

    /// @notice SMS on mainnet
    address public constant SMS = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;

    /// @notice Common trigger contract
    ICommonReportTrigger public constant COMMON_REPORT_TRIGGER =
        ICommonReportTrigger(0xA045D4dAeA28BA7Bfe234c96eAa03daFae85A147);

    // ===============================================================
    // Constructor
    // ===============================================================

    constructor() {
        minReportDelay = 3 days;
    }

    // ===============================================================
    // View functions
    // ===============================================================

    /// @inheritdoc CustomVaultTriggerBase
    function reportTrigger(address _vault, address _strategy) external view override returns (bool, bytes memory) {
        IVault.StrategyParams memory _params = IVault(_vault).strategies(_strategy);
        return block.timestamp - _params.last_report > minReportDelay
            ? COMMON_REPORT_TRIGGER.defaultVaultReportTrigger(_vault, _strategy)
            : (false, bytes("!delay"));
    }

    // ===============================================================
    // Governance functions
    // ===============================================================

    /// @notice Set the minimum report delay
    /// @dev Can only be called by the SMS
    /// @param _minReportDelay The new minimum report delay in seconds
    function setMinReportDelay(
        uint256 _minReportDelay
    ) external {
        require(msg.sender == SMS, "!SMS");
        require(_minReportDelay != 0, "!minReportDelay");
        minReportDelay = _minReportDelay;
    }

}
