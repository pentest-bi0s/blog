---
layout: post
title: "Snorlax - Payatu Hiring CTF Writeup"
date: 2026-06-24 00:25:00 +0530
description: "Walkthrough for the Snorlax Android reverse engineering challenge from Payatu Hiring CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Payatu Hiring CTF |
| Challenge | Snorlax |
| Category | Android / Reverse Engineering |

## Solution

We can install the APK in our emulator,But when we try to open it

![alt text](/assets/img/posts/payatu-hiring-ctf-snorlax/image-1.png)

We cannot enter the APP, it is doing somekind of checking - probably root/emulator detection which is not allowing us to open the app.
We can inspect it in Jadx to get more idea

![alt text](/assets/img/posts/payatu-hiring-ctf-snorlax/image-2.png)

There isn't much in Main Activity, we just need  to open the app and click on the image to get the flag which is loaded from a native lib
If we check the `lib` folder we see,

![alt text](/assets/img/posts/payatu-hiring-ctf-snorlax/image-3.png)

There are two native libs

1. libnative-lib.so --> from where the flag is loaded
2. libtoolcheck.so --> the root detector

We can further inspect `libtoolcheck.so` to get more idea about it

![alt text](/assets/img/posts/payatu-hiring-ctf-snorlax/image-4.png)

It is indeed a root check which checks if a particular root binaries are present or not for root detection
We just need to bypass this to get the flag
I used a [Frida root detection bypass script from github](https://gist.github.com/pich4ya/0b2a8592d3c8d5df9c34b8d185d2ea35)
And loaded this bypass  script, to get the flag

![alt text](/assets/img/posts/payatu-hiring-ctf-snorlax/image-5.png)

## Flag

```text
FLAG:PAYATU{SN0RL3X15BL0CKNGXYZUIQP13J4}
```
