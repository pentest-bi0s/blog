---
layout: post
title: "Droid Cryptor - m0leC0n CTF Writeup"
date: 2026-06-24 00:15:00 +0530
description: "Walkthrough for the Droid Cryptor Android reverse engineering challenge from m0leC0n CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | m0leC0n CTF |
| Challenge | Droid Cryptor |
| Category | Android / Reverse Engineering |

## Description

> One of my friends told me about this application that promised to keep your data safe. When I tried to encrypt the data, I found out later that there is no way to view it! Can you retrieve my message?

## Solution

We can start by installing and opening the APK

![alt text](/assets/img/posts/m0lec0n-ctf-droid-cryptor/image-1.png)

The launcher activity has two buttons :

1. Encrypt
2. Decrypt

When we click the `Encrypt` it takes us to the `EncryptFragment` and encrypts our message

![alt text](/assets/img/posts/m0lec0n-ctf-droid-cryptor/image-2.png)

From the output, it is clear that is uses `AES` encryption, but when we click on the `Decrypt` button,

![alt text](/assets/img/posts/m0lec0n-ctf-droid-cryptor/image-3.png)

Now, we can proceed to inspect the APK in the Jadx,
From the class `AesLaboratory,

![alt text](/assets/img/posts/m0lec0n-ctf-droid-cryptor/image-4.png)

We get the `SUPER_SECRET_KEY = "YWYwYjAyYjkzNmRhZjU3Yg==`, from the `.txt` provided we already have the `ciphertext` and `token (IV)`, we can use [cyberchef.io](gchq.github.io/CyberChef/) to decrypt the ciphertext

## Flag

```text
FLAG:ptm{th3nk_y0u_f0r_r3st0r1ng_mY_m3ss4g3!}
```
