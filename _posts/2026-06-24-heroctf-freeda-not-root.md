---
layout: post
title: "Freeda Not Root - HeroCTF Writeup"
date: 2026-06-24 00:11:00 +0530
description: "Walkthrough for the Freeda Not Root Android reverse engineering challenge from HeroCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | HeroCTF |
| Challenge | Freeda Not Root |
| Category | Android / Reverse Engineering |

## Description

```
Try to find the password to open this vault!

I was told that it was dangerous to let my application install on a rooted machine. I fixed the problem!

Don't waste too much time statically analyzing the application; there are much faster ways.
```

## Solution

We can install and open the app in our emulator

![alt text](/assets/img/posts/heroctf-freeda-not-root/image-1.png)

We are instantly thrown out with a pop-up saying `Rooted Devices Detected`
Now, we can inspect the APK in Jadx,

![alt text](/assets/img/posts/heroctf-freeda-not-root/image-2.png)

We see that the APK has native library `libtoolChecker.so` which is probably a libary used for detecting rooted devices, We can open the native lib in Ghidra to understand more about it

![alt text](/assets/img/posts/heroctf-freeda-not-root/image-3.png)

As suspected, it is a standard libary `rootbeer` which is used for detection of root devices, This libary particularly checks for root binaries for that
We can use an anti-root bypass script to bypass this check, I used `antiroot` from Frida CodeShare \
Source: https://codeshare.Frida.re/@dzonerzy/Fridantiroot/
We can load this script, to bypass the check -

![alt text](/assets/img/posts/heroctf-freeda-not-root/image-4.png)

Here on now, the logic is same as the level before \
logic is somewhere else --> it calls Checkflag() --> get_flag() is to be called --> log the return value

```js
// after the bypass script
Java.perform(() => {
    var Interceptor = Java.use("com.heroctf.freeda2.utils.Vault");
    console.log(Interceptor.get_flag())

})
```

Now, we can load both the scripts

![alt text](/assets/img/posts/heroctf-freeda-not-root/image-5.png)

## Flag

```text
FLAG:HERO{D1D_Y0U_U53_0BJ3C71ON?}
```
