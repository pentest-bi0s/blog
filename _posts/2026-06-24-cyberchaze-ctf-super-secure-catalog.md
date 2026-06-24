---
layout: post
title: "Super Secure Catalog - Cyberchaze CTF Writeup"
date: 2026-06-24 00:06:00 +0530
description: "Walkthrough for the Super Secure Catalog Android reverse engineering challenge from Cyberchaze CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Cyberchaze CTF |
| Challenge | Super Secure Catalog |
| Category | Android / Reverse Engineering |

## Solution

![alt text](/assets/img/posts/cyberchaze-ctf-super-secure-catalog/image.png)

The app on opening, asks for a username and a password
We can move on to inspecting in it Jadx

![alt text](/assets/img/posts/cyberchaze-ctf-super-secure-catalog/image-1.png)

The entered username and password is being verified in another class names `Cryto`
Now,we can inspect the Crypto class

![alt text](/assets/img/posts/cyberchaze-ctf-super-secure-catalog/image-2.png)

A part of the flag was hardcoded,
`cyberchaze{th3_encRYpt3d_STR1ng_in_3nc6yPtE6_`
There was also the use of Native Libraries, we can inspect it in:

![alt text](/assets/img/posts/cyberchaze-ctf-super-secure-catalog/image-3.png)

The function was a string encoded in hexa, we can convert it to string value

![alt text](/assets/img/posts/cyberchaze-ctf-super-secure-catalog/image-4.png)

1. hexa : 666921457d
2. ASCII : fi!E}

If we join them together we get the flag
flag : `cyberchaze{th3_encRYpt3d_STR1ng_in_3nc6yPtE6_fi!e} `
