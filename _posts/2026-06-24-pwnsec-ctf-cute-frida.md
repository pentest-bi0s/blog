---
layout: post
title: "Cute Frida - Pwnsec CTF Writeup"
date: 2026-06-24 00:28:00 +0530
description: "Walkthrough for the Cute Frida Android reverse engineering challenge from Pwnsec CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Pwnsec CTF |
| Challenge | Cute Frida |
| Category | Android / Reverse Engineering |

## Description

> This app is so cute yet so susy, isn't it?

## Solution

We can start by inspecting it in Frida, the APK itself is pretty useless

![alt text](/assets/img/posts/pwnsec-ctf-cute-frida/image-1.png)

In the Main Activity, we can see a sus string `What_do_you_mean_by_encrypted_flag` which has a value returned by `Deobfuscator$app$Release.getString(-548601664941L)`
So we can try to hook the `Deobfuscator$app$Release.getString()` and log its output
In the MainActivity, that method is called 5 times with different long values
So, we need to log all those 5 outputs:

```js
Java.perform(function() {
    var f =Java.use("com.joom.paranoid.Deobfuscator$app$Release");
    var longs =[-548601664941, -3140818349, -28910622125, -308083496365, -338148267437];
    for (var i = 0; i < longs.length; i++) {
        var result = f.getString(longs[i]);
        console.log(result);
    }
});
```

![alt text](/assets/img/posts/pwnsec-ctf-cute-frida/image-2.png)

## Flag

```text
flag{7he_developer_is_S0_p4r4n01d_1t_th1nk5_Fr1d4_1s_3v3rywh3r3}
```
