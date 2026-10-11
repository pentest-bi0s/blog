---
layout: post
title: "Truster - Damn Vulnerable DeFi Writeup"
date: 2026-10-06 10:00:00 +0530
description: "Writeup for truster challenge from Damn Vulnerable DeFi"
categories: [Writeups, CTF, Web3 Security]
tags: [ctf, web3, solidity, defi, flashloan]
author: Sarayu
toc: true
---

the flashLoan() implementation in TrusterLenderPool contract:

![image.png](/assets/img/posts/truster/image.png)

target is the address of the contract/borrower which the Trustedlenderpool contract lends tokens to. The `functionCall()` allows arbitrary external calls without any restrictions. we can make a malicious contract, where, we can make the pool contract approve our attaceker contract to spend the entire pool token balance.

![image-1.png](/assets/img/posts/truster/image-1.png)

We then use `transferFrom()` to transfer the approved tokens from the pool to the target address.

![image-2.png](/assets/img/posts/truster/image-2.png)