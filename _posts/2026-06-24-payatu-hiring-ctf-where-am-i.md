---
layout: post
title: "Where Am I - Payatu Hiring CTF Writeup"
date: 2026-06-24 00:26:00 +0530
description: "Walkthrough for the Where Am I Android reverse engineering challenge from Payatu Hiring CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Payatu Hiring CTF |
| Challenge | Where Am I |
| Category | Android / Reverse Engineering |

## Solution

We start by installing and opening the app in our emulator

![alt text](/assets/img/posts/payatu-hiring-ctf-where-am-i/image-1.png)

It shows a text that strongly hints this challenge involves `broadcasts` also it has a `7 sec` timer after that the app is terminated
Now, we can inspect it in Jadx,

![alt text](/assets/img/posts/payatu-hiring-ctf-where-am-i/image-2.png)

As expected, it does a Broadcast Receiver which probably contains the logic behind the flag
The Main Activity does not have much in it, just the logic behind the timer and termination

![alt text](/assets/img/posts/payatu-hiring-ctf-where-am-i/image-3.png)

```java
lic void onReceive(Context context, Intent intent) {
        if (new String(Base64.decode(context.getString(R.string.code), 0)).equals(intent.getStringExtra("loc"))) {
            Intent intent2 = new Intent(context, (Class<?>) ImTheSecond.class);
            intent2.addFlags(268435456);
            context.startActivity(intent2);
        }
    }
```

The value of R.string.code is `TWpvbG5pcg==` which when decoded is `Mjolnir`
Basically, our broadcast must contain a string extra with key `loc` and value `Mjolnir`, thats it the condition will be true and it will launch the activity which displays the flag
So, in our ADB shell

1. `am start -n com.payatu.whereami/.MainActivity` --> launchs the app
2. `am broadcast -a com.payatu.whereami.MY_ACTION -n com.payatu.whereami/.BroadCastListener --es loc Mjolnir` --> To lauch the flag activity

![alt text](/assets/img/posts/payatu-hiring-ctf-where-am-i/image-4.png)

## Flag

```text
FLAG:PAYATU{WAMI-G0d0F7HUND3RONHUNT}
```
