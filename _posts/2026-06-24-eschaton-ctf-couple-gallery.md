---
layout: post
title: "Couple Gallery - Eschaton CTF Writeup"
date: 2026-06-24 00:07:00 +0530
description: "Walkthrough for the Couple Gallery Android reverse engineering challenge from Eschaton CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Eschaton CTF |
| Challenge | Couple Gallery |
| Category | Android / Reverse Engineering |

## Description

> So my girlfriend, she stored all our private images on a "Secure App". As expected, she forget the passcode and now all our memories are lost! Can you help us recovering them? 🙂. Just remember that the passcode is a '6 DIGIT NUMBER'.

## Solution

We can start by installing and open the APK in our emulator

![alt text](/assets/img/posts/eschaton-ctf-couple-gallery/image-1.png)

We need a six digit pincode to unlock the app, we can proceed to inspect it in Jadx

![alt text](/assets/img/posts/eschaton-ctf-couple-gallery/image-2.png)

While inspecting it we can see that the app is written in `React Native`, So to actually decompile the APK we would need a `React Native` like - `Hermes Decompiler`
Source: https://github.com/P1sec/hermes-dec
We can clone the repo and follow the steps given

1. `7z x com.mcsc.couplegallery.APK -o./out`
2. `cd out`
3. `hbc-file-parser assets/index.android.bundle`
4. `hbc-decompiler assets/index.android.bundle ./my_output_file.js`

Now using `grep` we can search for any hardcoded 6 digits inside the `my_output_file.js` file \
`cat my_output_file.js | grep -nE "r[0-9]+ = '[0-9]{6}'"`

![alt text](/assets/img/posts/eschaton-ctf-couple-gallery/image-3.png)

We get a code `369963`, we can try to input that in the APK

![alt text](/assets/img/posts/eschaton-ctf-couple-gallery/image-4.png)

In the APK we find a image which contains the second part of the flag \
`_1s_s3cure?_k3y_w4s_369963`
We can guess and use grep to get the first part of the flag from `my_output_file.js`.

![alt text](/assets/img/posts/eschaton-ctf-couple-gallery/image-5.png)

## Flag

```text
FLAG: esch{wh0_s3aid_r3act_n4t1v3_1s_s3cure?_k3y_w4s_369963}
```
