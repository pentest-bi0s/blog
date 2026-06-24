---
layout: post
title: "baby-android-2 - ByuCTF Writeup"
date: 2026-06-24 00:01:00 +0530
description: "Walkthrough for the baby-android-2 Android reverse engineering challenge from ByuCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | ByuCTF |
| Challenge | baby-android-2 |
| Category | Android / Reverse Engineering |

## Description

> If you've never reverse engineered an Android application, now is the time!! Get to it, already!! Learn more about how they work!!

## Solution

We can start by installing and opening the app in our emulator

![alt text](/assets/img/posts/byuctf-baby-android-2/image-1.png)

The app has a textview and button for a `flag sanity` check, we can enter the flag and check if its correct
We can open the APK in Jadx,

![alt text](/assets/img/posts/byuctf-baby-android-2/image-2.png)

![alt text](/assets/img/posts/byuctf-baby-android-2/image-3.png)

We see that the `MainActivity` calls a method `check()` from `FlagChecker` and the class `FlagChecker` loads a native library and has a native method `check`
We can proceed to inspect the native library in Ghidra

![alt text](/assets/img/posts/byuctf-baby-android-2/image-4.png)

Our input is being checked against an encrypted string `bycnu)_aacGly~}tt+?=<_ML?f^i_vETkG+b{nDJrVp6=)=`, the encryption is very basic and we can use python to reverse it.

```
print(''.join('bycnu)_aacGly~}tt+?=<_ML?f^i_vETkG+b{nDJrVp6=)='[(i*i)%47] for i in range(23)))
```

We can run this script to get the flag, \

![alt text](/assets/img/posts/byuctf-baby-android-2/image-5.png) \

## Flag

```text
FLAG:byuctf{c++_in_an_apk??}
```
