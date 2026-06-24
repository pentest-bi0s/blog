---
layout: post
title: "Shadow Vault - Pearl CTF Writeup"
date: 2026-06-24 00:27:00 +0530
description: "Walkthrough for the Shadow Vault Android reverse engineering challenge from Pearl CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Pearl CTF |
| Challenge | Shadow Vault |
| Category | Android / Reverse Engineering |

##  Description

```
A mysterious app called ShadowVault has surfaced, rumored to hide secrets within its code. Can you unravel its mystery?
```

## Solution

We can start by installing and opening the app in our emulator

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-1.png)

The launcher activity is a login screen, when we entry to enter the app it shows a toast `Wrong details provided`
We can find the logic that handles the login screen by doing a global search of `Wrong details provided`

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-2.png)

The credentials are hardcoded in the app itself, we can use those to enter into the app

1. username : `Player118`
2. Password : `Gv8@kz#1qP$Xy!tM`

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-3.png)

It has a `Get Flag` and when we click it shows a toast `OOPS, You must travel to moon🌚 for the flag!`

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-4.png)

Looking further in Jadx we can find a Retrofit Client class and a hardcoded link `https://pearlctf.pythonanywhere.com/`, When we click the `Get Flag` button the app sends a https request
We can capture the request via `BurpSuite` and check the passed parameters, to bypass the ssl pinning we can use `android-unpinner` \
`android-unpinner all app-debug.APK`  \
Source: https://github.com/mitmproxy/android-unpinner

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-5.png)

We have successfully captured the `POST` request, it is sending two parameters

1. latitude
2. longitude

We can perform a global search for these in Jadx, to find more about it

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-6.png)

The values of `desiredLatitude` and `desiredLongitude` is hardcoded, \

1. `desiredLatitude = 100 `
2. `desiredLongitude = 200`

We just need to modify the captured request and send it again to get the flag

![alt text](/assets/img/posts/pearl-ctf-shadow-vault/image-7.png)
