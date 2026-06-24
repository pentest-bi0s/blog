---
layout: post
title: "Path Finder - Payatu Hiring CTF Writeup"
date: 2026-06-24 00:24:00 +0530
description: "Walkthrough for the Path Finder Android reverse engineering challenge from Payatu Hiring CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Payatu Hiring CTF |
| Challenge | Path Finder |
| Category | Android / Reverse Engineering |

## Solution

We can start by inspecting the APK in Jadx, since this is a webview-XSS challenge

![alt text](/assets/img/posts/payatu-hiring-ctf-path-finder/image-1.png)

The Main Activity itself has intent filers for a deeplink, from this we get an idea on how our link should be i.e `ctf://payatu/web`
Now, we can proceed to MainActivity to check how the web view is loaded and url is handled
From strings.xml,

1. R.sting.host = payatu.com
2. R.string.url_param = url

![alt text](/assets/img/posts/payatu-hiring-ctf-path-finder/image-4.png)

The flow of checking is:

1. `data` stores the value of data of the intent and the path of the data should not be null and path should match `/web`
2. `urlToLoad` stores whatever input we give as a parameter of `url`
3. It checks that `urlToLoad` contains `"payatu.com"`
4. Parallely this file `"file:///android_asset/WebViewRedirect.html;`  is loaded in the webview
5. The `urlToLoad` is passed to `redirect()`(this is a function inside WebViewRedirect.html)

We can inspect `WebViewRedirect.html`,

![alt text](/assets/img/posts/payatu-hiring-ctf-path-finder/image-2.png)

This file contains  `showflag()`, which we should call
So, deeplink should bypass all this checks and call the `showflag()` function
We, can use `ctf://payatu/web?url=javascript:AndroidFunction.showFlag()//payatu.com` to get the flag.
This link follows

1. The scheme,host and path specified in the manifest
2. javascript code is passed as an parameter of `url`
3. The javascript code contains `AndroidFunction.showFlag()`, which calls the functons we want
4. The link contains `payatu.com` which is commented out so it does not interfere with the code execution

We can pass with through ADB `am start -a android.intent.action.VIEW -d tf://payatu/web?url=javascript:AndroidFunction.showFlag()//payatu.com`

![alt text](/assets/img/posts/payatu-hiring-ctf-path-finder/image-3.png)

## Flag

```text
FLAG:PAYATU{Th1s_i5_th3_w4y}
```
