---
layout: post
title: "A Strange Door - Payatu Hiring CTF Writeup"
date: 2026-06-24 00:22:00 +0530
description: "Walkthrough for the A Strange Door Android reverse engineering challenge from Payatu Hiring CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Payatu Hiring CTF |
| Challenge | A Strange Door |
| Category | Android / Reverse Engineering |

## Solution

We can start by inspecting the APK in Jadx,

![alt text](/assets/img/posts/payatu-hiring-ctf-a-strange-door/image-1.png)

We have to input a pincode, which is passed to a native function `checkPasscode` and then if its correct the other activity is launched also another native function `decryptflag()` is called and passed along as an intent extra.

![alt text](/assets/img/posts/payatu-hiring-ctf-a-strange-door/image-2.png)

The second Activity(launched if the passcode is correct) gets the flag from the intent and displays it in a textview
One way of solving this, is to hook the `checkPasscode()` and modify the return value to `1`, so that no matter what we input..`checkPasscode()` will return `true` and `decryptflag()` will be called and the flag will be displayed in the following activity screen

```js
const NativeMethod = Process.getModuleByName('libctf.so');
const f = NativeMethod.getExportByName('Java_com_payatu_astragedoor_LoginActivity_checkPasscode');
Interceptor.attach(f, {
  onEnter(args) {
    console.log(' inside the native')
    },
    onLeave(retval){
      retval.replace(1);
    }
  });
```

We can load this Frida script,

![alt text](/assets/img/posts/payatu-hiring-ctf-a-strange-door/image-3.png)

## Flag

```text
FLAG:PAYATU{ASDS73V3NS7R@NG3P0P}
```
