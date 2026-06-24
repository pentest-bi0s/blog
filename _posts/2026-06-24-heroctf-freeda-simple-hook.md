---
layout: post
title: "Freeda Simple Hook - HeroCTF Writeup"
date: 2026-06-24 00:12:00 +0530
description: "Walkthrough for the Freeda Simple Hook Android reverse engineering challenge from HeroCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | HeroCTF |
| Challenge | Freeda Simple Hook |
| Category | Android / Reverse Engineering |

## Description

```
Try to find the password to open this vault!

Don't waste too much time statically analyzing the application; there are much faster ways.
```

## Solution

We can start by installing and opening the APK in our emulator

![alt text](/assets/img/posts/heroctf-freeda-simple-hook/image-1.png)

The APP, asks for a password to open the vault and if we input a random string we get a message `Password incorrect,try again`
Now, we can inspect the APK in Jadx to understand the logic

![alt text](/assets/img/posts/heroctf-freeda-simple-hook/image-2.png)

This is cleary not the actual logic handling the password validation, but we know that it changes the textview to `Password incorrect,try again` when we enter anything random, So we should do a global search of this phrase to find the actual logic that handles it.

![alt text](/assets/img/posts/heroctf-freeda-simple-hook/image-3.png)

The logic is actually inside a class `c8`, in this we see that it calls a static method `checkflag()`, We can inspect that class now

![alt text](/assets/img/posts/heroctf-freeda-simple-hook/image-4.png)

If the passed string is not `null`, a method `get_flag` of the class `com.heroctf.freeda1.utils.Vault` is called but the returned value (probably the flag) is not logged/stored/displayed anywhere
So, we can hook the `get_flag` of the class `com.heroctf.freeda1.utils.Vault` and log the returned string.

```js
Java.perform(() => {
    var Interceptor = Java.use("com.heroctf.freeda1.utils.Vault");
    console.log(Interceptor.get_flag())

})
```

We can load this script, and in out REPL -

![alt text](/assets/img/posts/heroctf-freeda-simple-hook/image-5.png)

## Flag

```text
FLAG:Hero{1_H0P3_Y0U_D1DN'T_S7A71C_4N4LYZ3D}
```
