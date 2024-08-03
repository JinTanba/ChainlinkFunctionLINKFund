// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouterForGetSubscriptionBalance {
    struct Subscription {
        uint96 balance; // ═════════╗ Common LINK balance that is controlled by the Router to be used for all consumer requests.
        address owner; // ══════════╝ The owner can fund/withdraw/cancel the subscription.
        uint96 blockedBalance; // ══╗ LINK balance that is reserved to pay for pending consumer requests.
        address proposedOwner; // ══╝ For safely transferring sub ownership.
        address[] consumers; // ════╸ Client contracts that can use the subscription
        bytes32 flags; // ══════════╸ Per-subscription flags
    }
    function getSubscription(uint64 subscriptionId) external view returns (Subscription memory);
}
