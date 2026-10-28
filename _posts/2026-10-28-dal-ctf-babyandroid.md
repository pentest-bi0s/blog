---
layout: post
title: "BabyAndroid - DalCTF Writeup"
date: 2026-10-28 00:10:00 +0530
description: "Walkthrough for the BabyAndroid Android reverse engineering challenge from DalCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

# Challenge Info

| Field | Details |
| --- | --- |
| CTF | DalCTF |
| Challenge | BabyAndroid |
| Category | Android / Reverse Engineering |

# Description
--------------------------------------

```text
Written by: Nir2602

Welcome to Android Debugging. Can you find the flag in this application?

```

# Solution
--------------------------------------

We can start by decompiling the APK in jadx.This is the decompiled code of MainActivity :   

```
public final class MainActivity extends ComponentActivity {
    public static final int $stable = 8;
    private final String flag1 = "dalctf{4ndr0id";

    @Override // androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable$default(this, null, null, 3, null);
        ComponentActivityKt.setContent$default(this, null, ComposableSingletons$MainActivityKt.INSTANCE.m7653getLambda$168778512$app(), 1, null);
    }
}
```
## Part 1

We already see the part 1 of the flag stored in the variable `flag1 = dalctf{4ndr0id`         
Since, the variable is named `flag1` we can use the global search function (`ctrl + SHIFT + F `) of jadx and search for `flag2`, `flag3` etc ..

## Part 2

The part 2 of the flag was hidden in `strings.xml`
```
<string name="flag2">_d3bugg1ng_</string>
```
Now, we can search for `flag3`.

## Part 3

Part 3 of the flag was hidden in the class `ColorKt`, here is the snippet of the decompiled code : 
```
public final class ColorKt {
    private static final long Purple80 = androidx.compose.ui.graphics.ColorKt.Color(4291869951L);
    private static final long PurpleGrey80 = androidx.compose.ui.graphics.ColorKt.Color(4291609308L);
    private static final long Pink80 = androidx.compose.ui.graphics.ColorKt.Color(4293900488L);
    private static final long Purple40 = androidx.compose.ui.graphics.ColorKt.Color(4284895396L);
    private static final long PurpleGrey40 = androidx.compose.ui.graphics.ColorKt.Color(4284636017L);
    private static final long Pink40 = androidx.compose.ui.graphics.ColorKt.Color(4286403168L);
    private static final String flag3 = "_1s_e4sy}";

```
Finally, we have all the three parts , We can combine them to get the flag.

# Flag
---------------------------------------------------

```
dalctf{4ndr0id_d3bugg1ng__1s_e4sy} 
```