---
layout: post
title: "Based - Mobile Hacking Community CTF Writeup"
date: 2026-06-24 00:16:00 +0530
description: "Walkthrough for the Based Android reverse engineering challenge from Mobile Hacking Community CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Mobile Hacking Community CTF |
| Challenge | Based |
| Category | Android / Reverse Engineering |

## Solution

We can start by installing and opening the APK in our emulator

![alt text](/assets/img/posts/mobile-hacking-community-ctf-based/image-1.png)

Very simple launcher activity, which ask to input a code and shows a toast based on our input
Now, we can proceed to inspect it in Jadx,

![alt text](/assets/img/posts/mobile-hacking-community-ctf-based/image-2.png)

We see that our input is validated using a method `check()` of the class `Based`, To understand the checking we must inspect the `Based` class.

![alt text](/assets/img/posts/mobile-hacking-community-ctf-based/image-3.png)

So, our input is compared against the returned value of another method `getPayload()`
We can use Frida to get the return value of `getPayload()`

```js
Java.perform(() => {
    var Interceptor = Java.use("com.appknox.based.Based");
    var InterceptorObj = Interceptor.$new();
    console.log(InterceptorObj.getPayload());
})
```

We can load this script to get the flag,

## Flag

```text
FLAG:MHC{50_Y0U_T00_4R3_4_B453D_P3R50N}
```
