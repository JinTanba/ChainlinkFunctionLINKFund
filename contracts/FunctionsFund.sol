// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IERC20.sol";
import "./IERC677.sol";
import "./IRouterForGetSubscriptionBalance.sol";

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

