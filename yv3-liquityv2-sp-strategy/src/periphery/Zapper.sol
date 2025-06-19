// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategy} from "@tokenized-strategy/interfaces/IStrategy.sol";

contract Zapper {

    using SafeERC20 for IERC20;
    using SafeERC20 for IStrategy;

    // ===============================================================
    // Constants
    // ===============================================================

    /// @notice SMS on mainnet
    address public constant SMS = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;

    /// @notice BOLD token address
    IERC20 public constant BOLD = IERC20(0x6440f144b7e50D6a8439336510312d2F54beB01D);

    /// @notice yBOLD token address
    IStrategy public constant YEARN_BOLD = IStrategy(0x9F4330700a36B29952869fac9b33f45EEdd8A3d8);

    /// @notice st-yBOLD token address
    IStrategy public constant STAKED_YEARN_BOLD = IStrategy(0x23346B04a7f55b8760E5860AA5A77383D63491cD);

    // ===============================================================
    // Constructor
    // ===============================================================

    constructor() {
        BOLD.forceApprove(address(YEARN_BOLD), type(uint256).max);
        YEARN_BOLD.forceApprove(address(STAKED_YEARN_BOLD), type(uint256).max);
    }

    // ===============================================================
    // View functions
    // ===============================================================

    /// @notice Allows an on-chain or off-chain user to simulate
    ///         the effects of their deposit at the current block, given
    ///         current on-chain conditions
    /// @dev This will round down
    /// @param _assets The amount of BOLD to deposit
    /// @return Expected st-yBOLD shares that would be issued
    function previewDeposit(
        uint256 _assets
    ) external view returns (uint256) {
        return STAKED_YEARN_BOLD.previewDeposit(YEARN_BOLD.previewDeposit(_assets));
    }

    /// @notice Allows an on-chain or off-chain user to simulate
    ///         the effects of their redemption at the current block,
    ///         given current on-chain conditions
    /// @dev This will round down
    /// @param _shares The amount of st-yBOLD that would be redeemed
    /// @return The amount of BOLD that would be returned
    function previewRedeem(
        uint256 _shares
    ) external view returns (uint256) {
        return YEARN_BOLD.previewRedeem(STAKED_YEARN_BOLD.previewRedeem(_shares));
    }

    // ===============================================================
    // Mutated functions
    // ===============================================================

    /// @notice Zap from BOLD to st-yBOLD
    /// @param _assets The amount of BOLD to zap in
    /// @param _receiver The address to receive the st-yBOLD
    /// @return The amount of st-yBOLD received
    function zapIn(uint256 _assets, address _receiver) external returns (uint256) {
        // Pull BOLD
        BOLD.safeTransferFrom(msg.sender, address(this), _assets);

        // BOLD --> yBOLD
        uint256 _shares = YEARN_BOLD.deposit(_assets, address(this));

        // yBOLD --> st-yBOLD
        return STAKED_YEARN_BOLD.deposit(_shares, _receiver);
    }

    /// @notice Zap from st-yBOLD to BOLD
    /// @param _shares The amount of st-yBOLD to zap out
    /// @param _receiver The address to receive the BOLD
    /// @param _maxLoss The maximum loss allowed during the zap out
    /// @return The amount of BOLD received
    function zapOut(uint256 _shares, address _receiver, uint256 _maxLoss) external returns (uint256) {
        // Redeem st-yBOLD to yBOLD on behalf of the caller
        _shares = STAKED_YEARN_BOLD.redeem(_shares, address(this), msg.sender, _maxLoss);

        // Withdraw yBOLD to BOLD and send to the receiver
        return YEARN_BOLD.redeem(_shares, _receiver, address(this), _maxLoss);
    }

    // ===============================================================
    // SMS functions
    // ===============================================================

    /// @notice Sweep any ERC20 token from the contract
    /// @dev Only callable by the SMS
    /// @param _token The ERC20 token to sweep
    /// @param _receiver The address to receive the swept tokens
    function sweep(IERC20 _token, address _receiver) external {
        require(msg.sender == SMS, "!SMS");
        require(_receiver != address(0), "!receiver");
        uint256 _balance = _token.balanceOf(address(this));
        require(_balance > 0, "!balance");
        _token.safeTransfer(_receiver, _balance);
    }

}
