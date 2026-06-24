---
layout: post
title: "Capture Me - Cyberchaze CTF Writeup"
date: 2026-06-24 00:02:00 +0530
description: "Walkthrough for the Capture Me Android reverse engineering challenge from Cyberchaze CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Cyberchaze CTF |
| Challenge | Capture Me |
| Category | Android / Reverse Engineering |

## Description

> Join the chase in "Capture Me," where your mission is to uncover and exploit vulnerabilities in mobile apps.

## Solutuon

![alt text](/assets/img/posts/cyberchaze-ctf-capture-me/image-1.png)

The APP has one button `FLAG` and when we click on it, it displays a toast `CAPTURE ME !!`
Now, we can inspect it in Jadx,

![alt text](/assets/img/posts/cyberchaze-ctf-capture-me/image-2.png)

We can see the logic behind the button, when the button is clicked it is followed by a if-else block

1. If(true) --> it opens the another activity `MainActivity2`(likely where the flag is)
2. else --> it shows the toast

The default hardcoded value of flag is `false`, So it will always show the toast unless the we modify the value
We can inspect the Manifest file to get an idea on what to do next.

```
android:dataExtractionRules="@xml/data_extraction_rules">
        <activity
            android:name="com.example.ctf_2.MainActivity2"
            android:exported="true"/>
        <activity
            android:name="com.example.ctf_2.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
```

Since, the `MainActivity2` has `exported="true"` we can directly open it through ADB without modifying any values
`am start -n com.example.ctf_2/.MainActivity2`, we can run this command in our ADB terminal

![alt text](/assets/img/posts/cyberchaze-ctf-capture-me/image-3.png)

We can see the base64 encoded flag, to decode : `echo "Q3liZXJjaGF6ZXtwcXRGdDhaUGFtT01JS0VNWmNYOEd6ckF1emNZcGk5UEVrYlphc25qVzNwZTczM2VmMn0" | base64 -d`

## Flag

```text
FLAG:Cyberchaze{pqtFt8ZPamOMIKEMZcX8GzrAuzcYpi9PEkbZasnjW3pe733ef2}
```
