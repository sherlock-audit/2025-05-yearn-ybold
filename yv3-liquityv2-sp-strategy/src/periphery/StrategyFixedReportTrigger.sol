// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {CustomStrategyTriggerBase} from "@periphery/ReportTrigger/CustomStrategyTriggerBase.sol";
import {ITokenizedStrategy} from "@tokenized-strategy/interfaces/ITokenizedStrategy.sol";

import {ICommonReportTrigger} from "../interfaces/ICommonReportTrigger.sol";

contract StrategyFixedReportTrigger is CustomStrategyTriggerBase {

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

    /// @inheritdoc CustomStrategyTriggerBase
    function reportTrigger(
        address _strategy
    ) external view override returns (bool, bytes memory) {
        return block.timestamp - ITokenizedStrategy(_strategy).lastReport() > minReportDelay
            ? COMMON_REPORT_TRIGGER.defaultStrategyReportTrigger(_strategy)
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
