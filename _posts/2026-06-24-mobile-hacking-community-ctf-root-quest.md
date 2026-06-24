---
layout: post
title: "Root Quest - Mobile Hacking Community CTF Writeup"
date: 2026-06-24 00:19:00 +0530
description: "Walkthrough for the Root Quest Android reverse engineering challenge from Mobile Hacking Community CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Mobile Hacking Community CTF |
| Challenge | Root Quest |
| Category | Android / Reverse Engineering |

## Description

> An application implements checks to detect rooted devices and emulators, preventing normal usage. Can you bypass these protections?

## Solution

We can start by installing and opening the APK,

![alt text](/assets/img/posts/mobile-hacking-community-ctf-root-quest/image-1.png)

As expected, we cant enter the app as we are running it on a rooted emulator
Now, we can inspect it in Jadx to understand how we should craft the bypass

![alt text](/assets/img/posts/mobile-hacking-community-ctf-root-quest/image-2.png)

It just calls two static methods `isRunningOnEmulator()` and `isDeviceRooted` from the classes `EmulationUtil` and `RootUtil` respectively.
We can use Frida to force the return values of both the methods to `0`(false)

```js
Java.perform(() => {
    var Interceptor = Java.use("com.just.mobile.sec.challenge3.EmulationUtil");
    var Interceptor1 = Java.use("com.just.mobile.sec.challenge3.RootUtil");
    Interceptor.isRunningOnEmulator.implementation = function(){
        return 0;
    }
    Interceptor1.isDeviceRooted.implementation = function(){
        return 0
    }

})
```

We just need to load this script,

![alt text](/assets/img/posts/mobile-hacking-community-ctf-root-quest/image-3.png)

## Flag

```text
FLAG:MHC{j1qwqc01kbi1a08wamce3}
```
