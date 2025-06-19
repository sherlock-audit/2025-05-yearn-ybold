// SPDX-License-Identifier: GNU AGPLv3
pragma solidity >=0.8.18;

import {Auction, ERC20} from "@periphery/Auctions/Auction.sol";

/// @title DoSResistantAuction
/// @notice A contract that allows users to bid on tokens in a DoS resistant auction.
/// @dev This contract is a modified version of the original Auction contract.
///      It includes a `kick` function that can only be called by the governance address.
///      The `kick` function is responsible for starting the auction and making funds available for bidding.
///      The contract is designed to be resistant to denial-of-service attacks.
contract DoSResistantAuction is Auction {

    /// @inheritdoc Auction
    function kick(
        address _from
    ) external override onlyGovernance nonReentrant returns (uint256 _available) {
        require(auctions[_from].scaler != 0, "not enabled");
        require(block.timestamp > auctions[_from].kicked + auctionLength, "too soon");

        // Just use current balance.
        _available = ERC20(_from).balanceOf(address(this));

        require(_available != 0, "nothing to kick");

        // Update the auctions status.
        auctions[_from].kicked = uint64(block.timestamp);
        auctions[_from].initialAvailable = uint128(_available);

        emit AuctionKicked(_from, _available);
    }

}
