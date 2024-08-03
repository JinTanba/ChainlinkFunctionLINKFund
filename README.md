Functions in contracts using chainlinkFunctions needed to be onlyOwner. This is because the LINK required for function execution is paid from the LINK that the registrant has already paid to the subscription. Without onlyOwner, there would be a free-rider problem with LINK.
Here, we propose a mechanism to enable flexible payment of LINK. In other words, we will collect the LINK necessary for executing Functions from the executor.

1. Method of paying LINK to the Subscription
The method of paying LINK to the subscription is as follows:
Send LINK to the Router contract via transferAndCall implemented in the LINK contract.

👇LINK(ERC677+ERC20)
```solidity
  function transferAndCall(address to, uint amount, bytes memory data) public returns (bool success) {
    super.transfer(to, amount);
    emit Transfer(msg.sender, to, amount, data);
    if (to.isContract()) {
      IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data);
    }
    return true;
  }
```

👇FunctionsRouter > FunctionsSubscriptions(IERC677Receiver)
```solidity
  function onTokenTransfer(address /* sender */, uint256 amount, bytes calldata data) external override {
    _whenNotPaused();
    if (msg.sender != address(i_linkToken)) {
      revert OnlyCallableFromLink();
    }
    if (data.length != 32) {
      revert InvalidCalldata();
    }
    uint64 subscriptionId = abi.decode(data, (uint64));
    if (s_subscriptions[subscriptionId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // We do not check that the msg.sender is the subscription owner,
    // anyone can fund a subscription.
    uint256 oldBalance = s_subscriptions[subscriptionId].balance;
    s_subscriptions[subscriptionId].balance += uint96(amount);
    s_totalLinkBalance += uint96(amount);
    emit SubscriptionFunded(subscriptionId, oldBalance, oldBalance + amount);
  }
```


2. By introducing a mechanism to check the LINK balance of the Subscription before and after function execution, and transfer the difference to the Subscription, it is possible to collect the LINK required for execution.
```solidity
    function send(uint256 amount, uint64 subId) external  {
        require(linkDeposit[msg.sender][subId] >= amount, "insufficient LINK");
        linkDeposit[msg.sender][subId] -= amount;
        IERC677(link).transferAndCall(router, amount, abi.encode(subId));
    }

```

Base Sepolia: 0xa530D009FaB25c716Dbb2d1186C71a23fcB1ca32
