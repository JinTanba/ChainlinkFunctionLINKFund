chainlinkFunctionsを使用するコントラクトの関数は、onlyOwnerである必要があった。関数の実行に必要なLINKは、登録者があらかじめsubscriptionに対して支払ったLINKが使用されるため、onlyOwnerを付与しない限り、LINKのフリーライダー問題に直面するためだ。
ここでは、LINKの柔軟な支払いを可能にするための仕組みを提案する。つまり、Functionsの実行に必要なLINKを実行者から徴収するのだ。

1. LINKをSubscriptionに対して支払う方法
LINKをsubscriptionに対して支払う方法は、以下の通りである。
LINKのコントラクトに実装されたtransferAndCallを経由して、RouterコントラクトにLINKを送金する。

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


2. 関数の実行前と、実行後にSubscriptionのLINK残高を確認し、差分をSubscriptionに送金する仕組みを導入すれば、実行に要したLINKを徴収することが可能である。
```solidity
    function send(uint256 amount, uint64 subId) external  {
        require(linkDeposit[msg.sender][subId] >= amount, "insufficient LINK");
        linkDeposit[msg.sender][subId] -= amount;
        IERC677(link).transferAndCall(router, amount, abi.encode(subId));
    }

```

Base Sepolia: 0x6574670C5a7F831022160F94CeC26d6b4012b668