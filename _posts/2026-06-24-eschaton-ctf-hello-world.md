---
layout: post
title: "Hello World - Eschaton CTF Writeup"
date: 2026-06-24 00:09:00 +0530
description: "Walkthrough for the Hello World Android reverse engineering challenge from Eschaton CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Eschaton CTF |
| Challenge | Hello World |
| Category | Android / Reverse Engineering |

## Description

> Hello World

## Solution

For this challenge, we are given an encrypted Android Backup

![alt text](/assets/img/posts/eschaton-ctf-hello-world/image-1.png)

To extract the file we would need a password, for that im using the tool - `john`
The steps to use it :

1. `androidbackup2john helloworld.dat > helloworld.txt` -> this is to identIfy all the parameters required for decryption
2. `john --wordlist=/usr/share/dict/rockyou.txt helloworld.txt` -> brute forcing the encryption with `rockyou.txt` which has about 14 million common passwords

![alt text](/assets/img/posts/eschaton-ctf-hello-world/image-2.png)

The password of the file is `hello world`, now we can use android backup extractor to extract it  \
`android-backup-unpack -p "hello world" -t ~/Downloads ~/Downloads/helloworld.dat`
We can inspect the `/apps/com.mcsc.helloworld/a/base.APK` in Jadx

![alt text](/assets/img/posts/eschaton-ctf-hello-world/image-3.png)

We see that it app imports `sqlcipher` and a particulartly interesting string `1s_th1s_th3_fl4g?` and also a hidden database is mentioned `.notinhere.db`
We can navigate to `/apps/com.mcsc.helloworld/db` and do `ls -al`

![alt text](/assets/img/posts/eschaton-ctf-hello-world/image-4.png)

We can access `.notinhere.db` using `sqlcipher` and try the pragma key as `1s_th1s_th3_fl4g?`

![alt text](/assets/img/posts/eschaton-ctf-hello-world/image-5.png)

The flag is inside the table `notes` \

## Flag

```text
FLAG:esch{he1!0o0o0o0o0_w0r!d}
```
