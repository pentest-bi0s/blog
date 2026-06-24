---
layout: post
title: "No Matter What You See - Mobile Hacking Community CTF Writeup"
date: 2026-06-24 00:17:00 +0530
description: "Walkthrough for the No Matter What You See Android reverse engineering challenge from Mobile Hacking Community CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Mobile Hacking Community CTF |
| Challenge | No Matter What You See |
| Category | Android / Reverse Engineering |

## Descriptiom

```
This app mistakenly exposes a sensitive Activity. Can you leverage this exported component to uncover the hidden flag?
```

## Solution

Since the description metions about `exported component`, we can begin with inspecting the Manifest file in Jadx

![alt text](/assets/img/posts/mobile-hacking-community-ctf-no-matter-what-you-see/image-1.png)

We see an `HiddenActivity` with the attribute `android:exported="true"` i.e this activity is exposed and can we direclty accessed via intent targeted towards this activity
In our ADB shell,
`am start -n com.just.mobile.sec.challenge2/.HiddenActivity`

![alt text](/assets/img/posts/mobile-hacking-community-ctf-no-matter-what-you-see/image-2.png)

## Flag

```text
FLAG:MHC={6xejitv015ldpw7f4hgndb7u}
```
