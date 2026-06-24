---
layout: post
title: "Gate Keeper - Payatu Hiring CTF Writeup"
date: 2026-06-24 00:23:00 +0530
description: "Walkthrough for the Gate Keeper Android reverse engineering challenge from Payatu Hiring CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Payatu Hiring CTF |
| Challenge | Gate Keeper |
| Category | Android / Reverse Engineering |

## Solution

We can by opening the app in our emulator

![alt text](/assets/img/posts/payatu-hiring-ctf-gate-keeper/image-1.png)

The app shows a hint `🔐There is a phrase I expect, only the right people can C`, and if we input anything random it shows `"Wrong key. Try again."`
Now, we can proceed to inspect it in Jadx to understand the logic it implements

![alt text](/assets/img/posts/payatu-hiring-ctf-gate-keeper/image-2.png)

A native library `libnative-lib.so` is loaded, our input is passed to a native function `sumbitKey` and if we enter the correct key, the flag is returned and displayed in the textview
We can inspect `libnative-lib.so` in Ghidra, to understand what the KEY could be

![alt text](/assets/img/posts/payatu-hiring-ctf-gate-keeper/image-3.png)

Our input is checked using `strcmp()` against `"undefined"`, and if it matches the flag is returned
So, now can we submit `undefined` in the app to get the flag

![alt text](/assets/img/posts/payatu-hiring-ctf-gate-keeper/image-4.png)

## Flag

```text
FLAG:PATATU{NOW_U_C_M3}
```
