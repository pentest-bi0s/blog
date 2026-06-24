---
layout: post
title: "Freeda Native Hook - HeroCTF Writeup"
date: 2026-06-24 00:10:00 +0530
description: "Walkthrough for the Freeda Native Hook Android reverse engineering challenge from HeroCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | HeroCTF |
| Challenge | Freeda Native Hook |
| Category | Android / Reverse Engineering |

## Description

```
Try to find the password to open this vault!

I was told that it was dangerous to let my application install on a rooted machine. I fixed the problem!
I was also told that it was safer to move sensitive functions from my code to a native library, so that's what I did!

Don't waste too much time statically analyzing the application; there are much faster ways.
```

## Solution

We can start by installing and opening the app in our emulator

![alt text](/assets/img/posts/heroctf-freeda-native-hook/image-1.png)

Same as before, the app terminates because we are on a rooted device
We can proceed to inspect in further in Jadx,

![alt text](/assets/img/posts/heroctf-freeda-native-hook/image-2.png)

This time, the APK has two native libs

1. `libtoolChecker.so`
2. `libv3.so`

`libtoolChecker.so` is same as before - the root beer library, For that we can use the same script we used before

![alt text](/assets/img/posts/heroctf-freeda-native-hook/image-3.png)

Also, this time the flag is hidden behind the native lib - `libv3.so`
We can inspect `libv3.so` in Ghidra, to get an idea about the Frida script we have to write

![alt text](/assets/img/posts/heroctf-freeda-native-hook/image-4.png)

The native library, has another function `get_flag` which probably is the one hiding the flag
We see that this `get_flag()` calls a second `check_root()` function before proceeding,

![alt text](/assets/img/posts/heroctf-freeda-native-hook/image-5.png)

This function `check_root()` also follows some method for detecting rooted device, and if it detects it the flag will remain hidden
Fortunately, this is a `boolean` function i.e we can use Frida to alter its return value regardless of the state of the device
Upon closer inspection, the function `check_root()` is pretty pointless here because `&DAT_001054c0` is returned before calling `check_root()` and `&DAT_001054c0` is a memory location of (probably) the flag.
So, our Frida script should:

1. bypass the rootbeer library's check
2. Read the content at `&DAT_001054c0`

```js
// aftr rootbees's bypass
const NativeMethod = Process.getModuleByName('libv3.so');
const f = NativeMethod.getExportByName('get_flag');
Interceptor.attach(f, {
  onEnter(args) {
    },
    onLeave(retval){
      console.log(retval.readCString());
    }
  });
```

Now, we just have to run this script,

![alt text](/assets/img/posts/heroctf-freeda-native-hook/image-6.png)

## Flag

```text
FLAG:Hero{F1NAL_57EP_Y0U_KN0W_H0W_TO_R3V3R53_4NDR01D}
```
