// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IERC677 {
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
  /// @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
  /// @param to The address which you want to transfer to
  /// @param amount The amount of tokens to be transferred
  /// @param data bytes Additional data with no specified format, sent in call to `to`
  /// @return true unless throwing
  function transferAndCall(address to, uint256 amount, bytes memory data) external returns (bool);
}

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


contract ChainlinkFunctionsSubscriptionLinkDeposit {
    address link = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address router = 0xf9B8fc078197181C841c296C876945aaa425B278;
    mapping(address => mapping(uint64 => uint256)) public linkDeposit;
    function deposit(uint256 amount, uint64 subId) external {
        IERC20(link).transferFrom(msg.sender, address(this), amount);        
        linkDeposit[msg.sender][subId] += amount;
    }

    function send(uint256 amount, uint64 subId) external  {
        require(linkDeposit[msg.sender][subId] >= amount, "insufficient LINK");
        linkDeposit[msg.sender][subId] -= amount;
        IERC677(link).transferAndCall(router, amount, abi.encode(subId));
    }

    function getSubscriptionBalance(uint64 subId) external view returns(uint256) {
       return IRouterForGetSubscriptionBalance(router).getSubscription(subId).balance;
    }
    
}

