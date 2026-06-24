---
layout: post
title: "Prints - Mobile Hacking Community CTF Writeup"
date: 2026-06-24 00:18:00 +0530
description: "Walkthrough for the Prints Android reverse engineering challenge from Mobile Hacking Community CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Mobile Hacking Community CTF |
| Challenge | Prints |
| Category | Android / Reverse Engineering |

## Solution

We can start by installing and opening the app in our emulator

![alt text](/assets/img/posts/mobile-hacking-community-ctf-prints/image-1.png)

It is a login screen and it says that we need biometrics to login but of course we cannot do that since we are running it in an emulator
We must use a biometric bypass Frida script to login
For that, I used ` Universal Android Biometric Bypass` \
Source: https://codeshare.Frida.re/@ax/universal-android-biometric-bypass/
We can load this script and try to login,

![alt text](/assets/img/posts/mobile-hacking-community-ctf-prints/image-2.png)

We do see the flag after login, /

## Flag

```text
FLAG:MHC{by3_by3_f1ng3r_b4nk}
```
