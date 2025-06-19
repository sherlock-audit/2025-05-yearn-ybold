// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

interface ICommonReportTrigger {

    /**
     * @notice The default trigger logic for a strategy.
     * @dev This is kept in a separate function so it can still
     * be used by custom triggers even if extra checks are needed
     * first or after.
     *
     * This will also check if a custom acceptable base fee has been set
     * by the strategies management.
     *
     * In order for the default flow to return true the strategy must:
     *
     *   1. Not be shutdown.
     *   2. Have funds.
     *   3. The current network base fee be below the `acceptableBaseFee`.
     *   4. The time since the last report be > the strategies `profitMaxUnlockTime`.
     *
     * @param _strategy The address of the strategy to check the trigger for.
     * @return . Bool representing if the strategy is ready to report.
     * @return . Bytes with either the calldata or reason why False.
     */
    function defaultStrategyReportTrigger(
        address _strategy
    ) external view returns (bool, bytes memory);

    /**
     * @notice The default trigger logic for a vault.
     * @dev This is kept in a separate function so it can still
     * be used by custom triggers even if extra checks are needed
     * before or after.
     *
     * This will also check if a custom acceptable base fee has been set
     * by the vault management for the `_strategy`.
     *
     * In order for the default flow to return true:
     *
     *   1. The vault must not be shutdown.
     *   2. The strategy must be active and have debt allocated.
     *   3. The current network base fee be below the `acceptableBaseFee`.
     *   4. The time since the strategies last report be > the vaults `profitMaxUnlockTime`.
     *
     * @param _vault The address of the vault.
     * @param _strategy The address of the strategy to report.
     * @return . Bool if the strategy should report to the vault.
     * @return . Bytes with either the calldata or reason why False.
     */
    function defaultVaultReportTrigger(address _vault, address _strategy) external view returns (bool, bytes memory);

}
