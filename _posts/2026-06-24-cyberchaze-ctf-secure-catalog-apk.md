---
layout: post
title: "Secure Catalog APK - Cyberchaze CTF Writeup"
date: 2026-06-24 00:04:00 +0530
description: "Walkthrough for the Secure Catalog APK Android reverse engineering challenge from Cyberchaze CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Cyberchaze CTF |
| Challenge | Secure Catalog APK |
| Category | Android / Reverse Engineering |

## Solution

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image.png)

The app when launched first asks for email ID and a password
If we dig through the `strings.xml` file in Jadx, we would find the email ID and the password required to login in

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image-4.png)

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image-5.png)

1. email : admin@catalog.com
2. password : password

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image-1.png)

When we login we see a potential flag, but its encrypted with shift cipher(key=3) and if we decrypt it,

1. ciphertext: Cixd{qefp_fp_klq_qeb_obxi_cixd_illh_xolrka}
2. plaintext: Flag{this_is_not_the_real_flag_look_around}

After we login we can inspect the app with ADB
We can see two databases in the /databases dir

1. product_part1.db
2. product_part2.db

We cannot directly access the database, it is protected by SQLCipher, so we need to find the key to access it

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image-2.png)

Further, if we inspect the Manifest..we see the DBUtil activity and if we inspect that

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image-3.png)

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image-6.png)

We can see a base64 encoded value which is used while executing the SQL query

1. base64 encoded: `cGFzczEyMw==`
2. decoded: `pass123`

Potentially `pass123` could be the key to access the database
We pull both the databases to our system using ADB
and then use `sqlcipher product_part1.db` and enter

```
PRAGMA key = 'pass123';
.tables
```

![alt text](/assets/img/posts/cyberchaze-ctf-secure-catalog-apk/image.webp)

We see a table `secret` and if the run `SELECT * FROM SECRET;` we get the flag

## Flag

```text
flag: cyberchaze{h4rdcoded_pa$s_y0u_g0t_th3_fl@g}
```
