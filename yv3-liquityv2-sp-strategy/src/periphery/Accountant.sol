// SPDX-License-Identifier: GNU AGPLv3
pragma solidity >=0.8.18;

import {IVault} from "@yearn-vaults/interfaces/IVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Accountant.
/// @notice A simplified accountant that (1) hardcodes performance fee to 100% and (2) only takes fee if there's no loss.
/// @dev Will charge fees and run health check on any reported
///     gains or losses during a strategy's report.
contract Accountant {

    using SafeERC20 for ERC20;

    /// @notice An event emitted when a vault is added or removed.
    event VaultChanged(address indexed vault, ChangeType change);

    /// @notice An event emitted when the default fee configuration is updated.
    event UpdateDefaultFeeConfig(Fee defaultFeeConfig);

    /// @notice An event emitted when the future fee manager is set.
    event SetFutureFeeManager(address indexed futureFeeManager);

    /// @notice An event emitted when a new fee manager is accepted.
    event NewFeeManager(address indexed feeManager);

    /// @notice An event emitted when a new vault manager is set.
    event UpdateVaultManager(address indexed newVaultManager);

    /// @notice An event emitted when the fee recipient is updated.
    event UpdateFeeRecipient(address indexed oldFeeRecipient, address indexed newFeeRecipient);

    /// @notice An event emitted when a custom fee configuration is updated.
    event UpdateCustomFeeConfig(address indexed vault, Fee custom_config);

    /// @notice An event emitted when a custom fee configuration is removed.
    event RemovedCustomFeeConfig(address indexed vault);

    /// @notice An event emitted when the `maxLoss` parameter is updated.
    event UpdateMaxLoss(uint256 maxLoss);

    /// @notice An event emitted when rewards are distributed.
    event DistributeRewards(address indexed token, uint256 rewards);

    /// @notice Enum defining change types (added or removed).
    enum ChangeType {
        NULL,
        ADDED,
        REMOVED
    }

    /// @notice Struct representing fee details.
    struct Fee {
        uint16 maxGain; // Max percent gain a strategy can report.
        uint16 maxLoss; // Max percent loss a strategy can report.
        bool custom; // Flag to set for custom configs.
    }

    modifier onlyFeeManager() {
        _checkFeeManager();
        _;
    }

    modifier onlyVaultOrFeeManager() {
        _checkVaultOrFeeManager();
        _;
    }

    modifier onlyFeeManagerOrRecipient() {
        _checkFeeManagerOrRecipient();
        _;
    }

    modifier onlyAddedVaults() {
        _checkVaultIsAdded();
        _;
    }

    function _checkFeeManager() internal view virtual {
        require(msg.sender == feeManager, "!fee manager");
    }

    function _checkVaultOrFeeManager() internal view virtual {
        require(msg.sender == feeManager || msg.sender == vaultManager, "!vault manager");
    }

    function _checkFeeManagerOrRecipient() internal view virtual {
        require(msg.sender == feeRecipient || msg.sender == feeManager, "!recipient");
    }

    function _checkVaultIsAdded() internal view virtual {
        require(vaults[msg.sender], "vault not added");
    }

    /// @notice Constant defining the maximum basis points.
    uint256 internal constant MAX_BPS = 10_000;

    /// @notice The amount of max loss to use when redeeming from vaults.
    uint256 public maxLoss;

    /// @notice The address of the fee manager.
    address public feeManager;

    /// @notice The address of the fee recipient.
    address public feeRecipient;

    /// @notice An address that can add or remove vaults.
    address public vaultManager;

    /// @notice The address of the future fee manager.
    address public futureFeeManager;

    /// @notice The default fee configuration.
    Fee public defaultConfig;

    /// @notice Mapping to track added vaults.
    mapping(address => bool) public vaults;

    /// @notice Mapping vault => custom Fee config if any.
    mapping(address => Fee) public customConfig;

    /// @notice Mapping vault => strategy => flag for one time healthcheck skips.
    mapping(address => mapping(address => bool)) skipHealthCheck;

    constructor(address _feeManager, address _feeRecipient, uint16 defaultMaxGain, uint16 defaultMaxLoss) {
        require(_feeManager != address(0), "ZERO ADDRESS");
        require(_feeRecipient != address(0), "ZERO ADDRESS");

        feeManager = _feeManager;
        feeRecipient = _feeRecipient;

        _updateDefaultConfig(defaultMaxGain, defaultMaxLoss);
    }

    /**
     * @notice Called by a vault when a `strategy` is reporting.
     * @dev The msg.sender must have been added to the `vaults` mapping.
     * @param strategy Address of the strategy reporting.
     * @param gain Amount of the gain if any.
     * @param loss Amount of the loss if any.
     * @return totalFees if any to charge.
     * @return totalRefunds if any for the vault to pull.
     */
    function report(
        address strategy,
        uint256 gain,
        uint256 loss
    ) public virtual onlyAddedVaults returns (uint256 totalFees, uint256 /* totalRefunds */ ) {
        // Declare the config to use as the custom.
        Fee memory fee = customConfig[msg.sender];

        // Check if there is a custom config to use.
        if (!fee.custom) {
            // Otherwise use the default.
            fee = defaultConfig;
        }

        // Retrieve the strategy's params from the vault.
        IVault vault = IVault(msg.sender);
        IVault.StrategyParams memory strategyParams = vault.strategies(strategy);

        // Only charge performance fees if there is a gain.
        if (gain > 0) {
            // If we are skipping the healthcheck this report
            if (skipHealthCheck[msg.sender][strategy]) {
                // Make sure it is reset for the next one.
                skipHealthCheck[msg.sender][strategy] = false;

                // Setting `maxGain` to 0 will disable the healthcheck on profits.
            } else if (fee.maxGain > 0) {
                require(gain <= (strategyParams.current_debt * (fee.maxGain)) / MAX_BPS, "too much gain");
            }

            // 100% performance fee
            totalFees = gain;

            // Only take fee if there's no loss.
            uint256 supply = vault.totalSupply();
            uint256 assets = vault.totalAssets();
            if (assets < supply) {
                uint256 needed = supply - assets;
                totalFees = gain < needed ? 0 : gain - needed;
            }
        } else {
            // If we are skipping the healthcheck this report
            if (skipHealthCheck[msg.sender][strategy]) {
                // Make sure it is reset for the next one.
                skipHealthCheck[msg.sender][strategy] = false;

                // Setting `maxLoss` to 10_000 will disable the healthcheck on losses.
            } else if (fee.maxLoss < MAX_BPS) {
                require(loss <= (strategyParams.current_debt * (fee.maxLoss)) / MAX_BPS, "too much loss");
            }
        }

        return (totalFees, 0);
    }

    /**
     * @notice Function to add a new vault for this accountant to charge fees for.
     * @dev This is not used to set any of the fees for the specific vault or strategy. Each fee will be set separately.
     * @param vault The address of a vault to allow to use this accountant.
     */
    function addVault(
        address vault
    ) external virtual onlyVaultOrFeeManager {
        // Ensure the vault has not already been added.
        require(!vaults[vault], "already added");

        vaults[vault] = true;

        emit VaultChanged(vault, ChangeType.ADDED);
    }

    /**
     * @notice Function to remove a vault from this accountant's fee charging list.
     * @param vault The address of the vault to be removed from this accountant.
     */
    function removeVault(
        address vault
    ) external virtual onlyVaultOrFeeManager {
        // Ensure the vault has been previously added.
        require(vaults[vault], "not added");

        address asset = IVault(vault).asset();
        // Remove any allowances left.
        if (ERC20(asset).allowance(address(this), vault) != 0) {
            // slither-disable-next-line reentrancy-no-eth
            ERC20(asset).safeApprove(vault, 0);
        }

        vaults[vault] = false;

        emit VaultChanged(vault, ChangeType.REMOVED);
    }

    /**
     * @notice Function to update the default fee configuration used for
     *     all strategies that don't have a custom config set.
     * @param defaultMaxGain Default max percent gain a strategy can report.
     * @param defaultMaxLoss Default max percent loss a strategy can report.
     */
    function updateDefaultConfig(uint16 defaultMaxGain, uint16 defaultMaxLoss) external virtual onlyFeeManager {
        _updateDefaultConfig(defaultMaxGain, defaultMaxLoss);
    }

    /**
     * @dev Updates the Accountant's default fee config.
     *   Is used during deployment and during any future updates.
     */
    function _updateDefaultConfig(uint16 defaultMaxGain, uint16 defaultMaxLoss) internal virtual {
        // Check for threshold and limit conditions.
        require(defaultMaxLoss <= MAX_BPS, "too high");

        // Update the default fee configuration.
        defaultConfig = Fee({maxGain: defaultMaxGain, maxLoss: defaultMaxLoss, custom: false});

        emit UpdateDefaultFeeConfig(defaultConfig);
    }

    /**
     * @notice Function to set a custom fee configuration for a specific vault.
     * @param vault The vault the strategy is hooked up to.
     * @param customMaxGain Custom max percent gain a strategy can report.
     * @param customMaxLoss Custom max percent loss a strategy can report.
     */
    function setCustomConfig(
        address vault,
        uint16 customMaxGain,
        uint16 customMaxLoss
    ) external virtual onlyFeeManager {
        // Ensure the vault has been added.
        require(vaults[vault], "vault not added");
        // Check for threshold and limit conditions.
        require(customMaxLoss <= MAX_BPS, "too high");

        // Create the vault's custom config.
        Fee memory _config = Fee({maxGain: customMaxGain, maxLoss: customMaxLoss, custom: true});

        // Store the config.
        customConfig[vault] = _config;

        emit UpdateCustomFeeConfig(vault, _config);
    }

    /**
     * @notice Function to remove a previously set custom fee configuration for a vault.
     * @param vault The vault to remove custom setting for.
     */
    function removeCustomConfig(
        address vault
    ) external virtual onlyFeeManager {
        // Ensure custom fees are set for the specified vault.
        require(customConfig[vault].custom, "No custom fees set");

        // Set all the vaults's custom fees to 0.
        delete customConfig[vault];

        // Emit relevant event.
        emit RemovedCustomFeeConfig(vault);
    }

    /**
     * @notice Turn off the health check for a specific `vault` `strategy` combo.
     * @dev This will only last for one report and get automatically turned back on.
     * @param vault Address of the vault.
     * @param strategy Address of the strategy.
     */
    function turnOffHealthCheck(address vault, address strategy) external virtual onlyFeeManager {
        // Ensure the vault has been added.
        require(vaults[vault], "vault not added");

        skipHealthCheck[vault][strategy] = true;
    }

    /**
     * @notice Public getter to check for custom setting.
     * @dev We use uint256 for the flag since its cheaper so this
     *   will convert it to a bool for easy view functions.
     *
     * @param vault Address of the vault.
     * @return If a custom fee config is set.
     */
    function useCustomConfig(
        address vault
    ) external view virtual returns (bool) {
        return customConfig[vault].custom;
    }

    /**
     * @notice Get the full config used for a specific `vault`.
     * @param vault Address of the vault.
     * @return fee The config that would be used during the report.
     */
    function getVaultConfig(
        address vault
    ) external view returns (Fee memory fee) {
        fee = customConfig[vault];

        // Check if there is a custom config to use.
        if (!fee.custom) {
            // Otherwise use the default.
            fee = defaultConfig;
        }
    }

    /**
     * @notice Sets the `maxLoss` parameter to be used on redeems.
     * @param _maxLoss The amount in basis points to set as the maximum loss.
     */
    function setMaxLoss(
        uint256 _maxLoss
    ) external virtual onlyFeeManager {
        // Ensure that the provided `maxLoss` does not exceed 100% (in basis points).
        require(_maxLoss <= MAX_BPS, "higher than 100%");

        maxLoss = _maxLoss;

        // Emit an event to signal the update of the `maxLoss` parameter.
        emit UpdateMaxLoss(_maxLoss);
    }

    /**
     * @notice Function to distribute all accumulated fees to the designated recipient.
     * @param token The token to distribute.
     */
    function distribute(
        address token
    ) external virtual {
        distribute(token, ERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice Function to distribute accumulated fees to the designated recipient.
     * @param token The token to distribute.
     * @param amount amount of token to distribute.
     */
    function distribute(address token, uint256 amount) public virtual onlyFeeManagerOrRecipient {
        ERC20(token).safeTransfer(feeRecipient, amount);

        emit DistributeRewards(token, amount);
    }

    /**
     * @notice Function to set a future fee manager address.
     * @param _futureFeeManager The address to set as the future fee manager.
     */
    function setFutureFeeManager(
        address _futureFeeManager
    ) external virtual onlyFeeManager {
        // Ensure the futureFeeManager is not a zero address.
        require(_futureFeeManager != address(0), "ZERO ADDRESS");
        futureFeeManager = _futureFeeManager;

        emit SetFutureFeeManager(_futureFeeManager);
    }

    /**
     * @notice Function to accept the role change and become the new fee manager.
     * @dev This function allows the future fee manager to accept the role change and become the new fee manager.
     */
    function acceptFeeManager() external virtual {
        // Make sure the sender is the future fee manager.
        require(msg.sender == futureFeeManager, "not future fee manager");
        feeManager = futureFeeManager;
        futureFeeManager = address(0);

        emit NewFeeManager(msg.sender);
    }

    /**
     * @notice Function to set a new vault manager.
     * @param newVaultManager Address to add or remove vaults.
     */
    function setVaultManager(
        address newVaultManager
    ) external virtual onlyFeeManager {
        vaultManager = newVaultManager;

        emit UpdateVaultManager(newVaultManager);
    }

    /**
     * @notice Function to set a new address to receive distributed rewards.
     * @param newFeeRecipient Address to receive distributed fees.
     */
    function setFeeRecipient(
        address newFeeRecipient
    ) external virtual onlyFeeManager {
        // Ensure the newFeeRecipient is not a zero address.
        require(newFeeRecipient != address(0), "ZERO ADDRESS");
        address oldRecipient = feeRecipient;
        feeRecipient = newFeeRecipient;

        emit UpdateFeeRecipient(oldRecipient, newFeeRecipient);
    }

}
