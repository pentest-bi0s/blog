---
layout: post
title: "Knight - P3RF3CTR00T CTF Writeup"
date: 2026-06-24 00:21:00 +0530
description: "Walkthrough for the Knight Android reverse engineering challenge from P3RF3CTR00T CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | P3RF3CTR00T CTF |
| Challenge | Knight |
| Category | Android / Reverse Engineering |

## Description

> Uncover the secrets of the Dark knight to get the flag

## Solution

We can start by installing the APK and opening it in our emulator

![alt text](/assets/img/posts/p3rf3ctr00t-ctf-knight/image-1.png)

The activity says that input the flag to proceed and if we input anything random it says `Incorrect Flag.Try Harder`
We can inspect the APK in Jadx,

![alt text](/assets/img/posts/p3rf3ctr00t-ctf-knight/image-2.png)

The Main Activity does not have anything related to the checking logic, But we know the it displays `Incorrect Flag.Try Harder` for wrong input
So, we can do a global search for `Incorrect Flag.Try Harder` to identify the class implementing the logic

![alt text](/assets/img/posts/p3rf3ctr00t-ctf-knight/image-3.png)

The actual logic is being implemented in the class `ei` and see that a base64 encoded AES encrypted cipher text is being decrypted to which our input is compared.
So, we just need to decrypt the ciphertext and the `IV` and `KEY` are hardcoded in other class `jv`
Rather than the traditional approach of getting the `IV` and `KEY` and then decrypting it ourselves, I wanted to try out a Frida script i found, which hooks all the cryptographic function in a APK and logs its output \
Source: https://codeshare.Frida.re/@L0WK3Y-IAAN/crypto-detection/
We just need to load this script and click the button once,

![alt text](/assets/img/posts/p3rf3ctr00t-ctf-knight/image-4.png)

We should confirm the flag,

![alt text](/assets/img/posts/p3rf3ctr00t-ctf-knight/image-5.png)

## Flag

```text
FLAG:k0t_r3v3rs3_kn1ght_n1nj4_07a51b8
```
