---
layout: post
title: "baby-android-1 - ByuCTF Writeup"
date: 2026-06-24 00:00:00 +0530
description: "Walkthrough for the baby-android-1 Android reverse engineering challenge from ByuCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | ByuCTF |
| Challenge | baby-android-1 |
| Category | Android / Reverse Engineering |

## Solution

We can begin by inspecting the Manifest file

![alt text](/assets/img/posts/byuctf-baby-android-1/image.png)

Nothing much in the manifest, only one activity

![alt text](/assets/img/posts/byuctf-baby-android-1/image-1.png)

The Main activity does nothing but call the Utils.cleanUp() method
And if we inspect Utils Class

![alt text](/assets/img/posts/byuctf-baby-android-1/image-2.png)

Same as the name, Utils.cleanUp() cleans the text in the textviews and sets it to nothing
If we search the `flagpart*` in the resources file,

1. Inside strings.xml theres nothing there
2. But in `layout/activity_main.xml` file, we see:

![alt text](/assets/img/posts/byuctf-baby-android-1/image-3.png)

Every text view has one char in it has a text
If we assemble it by order we get,
`b{e4_if_e_efcopukd0inrdccyat}` but this does not make any sense
Every textview has a definite position in the layout, So we can just copy paste the textviews to our POC app to see how it will look

![alt text](/assets/img/posts/byuctf-baby-android-1/image-4.png)

Even though, it is distorted we can read it to :

## Flag

```text
Flag : byuctf{android_piece_0f_c4ke}
```
