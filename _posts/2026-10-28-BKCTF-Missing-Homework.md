---
layout: post
title: "Missing Homework - BKCTF Writeup"
date: 2026-10-28 00:10:00 +0530
description: "Walkthrough for the Missing HomeWork Android reverse engineering challenge from BKCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | BKCTF |
| Challenge | Missing Homework |
| Category | Android / Reverse Engineering |

## Description

```text
Jono I dug up this homework assignment from my "stegnography" class when that was the coolest thing on the internet. However, I lost the code I used to do it with.

Can you help me figure out what I hid in this file?
```

## Solution

We can start by opening the APK the in jadx.
This APK has only one Activity - MainActivity, We get the decompiled code of MainActivity from jadx,

### MainActivity

```
public final class MainActivity extends AppCompatActivity {
    private ActivityMainBinding binding;

    public final native String stringFromJNI();

    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ActivityMainBinding activityMainBindingInflate = ActivityMainBinding.inflate(getLayoutInflater());
        Intrinsics.checkNotNullExpressionValue(activityMainBindingInflate, "inflate(...)");
        this.binding = activityMainBindingInflate;
        ActivityMainBinding activityMainBinding = this.binding;
        ActivityMainBinding activityMainBinding2 = null;
        if (activityMainBinding == null) {
            Intrinsics.throwUninitializedPropertyAccessException("binding");
            activityMainBinding = null;
        }
        setContentView(activityMainBinding.getRoot());
        ActivityMainBinding activityMainBinding3 = this.binding;
        if (activityMainBinding3 == null) {
            Intrinsics.throwUninitializedPropertyAccessException("binding");
        } else {
            activityMainBinding2 = activityMainBinding3;
        }
        activityMainBinding2.sampleText.setText(stringFromJNI());
    }

    static {
        System.loadLibrary("helloworld");
    }
}
```

As, we look through it we find nothing interesting or anything related to the flag.
The challenge had one more python script along it :

### sus Python Script

```
import struct
import zipfile
import os
import sys
from base64 import b64encode

FLAG     = ''
APK_File = "hiddenfile.apk"

def inject_into_androidmanifest(apk_file, string_to_inject):
    # Sequentially put the base64 encoded string character by character into the AndroidManifest file
    # https://android.googlesource.com/platform/frameworks/base/+/56a2301/include/androidfw/ResourceTypes.h
    characters = list(string_to_inject)
    output_file =  "hiddenfile.apk"

    ### TODO: YOUR CODE HERE
    pass

apk_file = sys.argv[1]
string_to_inject = b64encode(FLAG.encode()).decode()
print(string_to_inject)

if not os.path.exists(apk_file):
    print(f"[!] Error: File not found: {apk_file}")
    sys.exit(1)

try:
    inject_into_androidmanifest(apk_file, string_to_inject)
except Exception as e:
    print(f"\n[!] Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
```
As we see, this script has a function inject_into_androidmanifest which takes in two parameters - apk file and the string to inject

It encodes in string in base64 and injects it into AndroidManifest.xml file.
This python script hints us on where the flag could be, that is this script encodes the flag in base64 and injects it char by char into AndroidManifest.xml

This blog explains how the string was "injected" into AndroidManifest.xml      \
link:https://medium.com/@zahidaz/you-can-hide-an-elephant-in-androidmanifest-xml-8a1a8d0ef206

### Elephant hiding in AndroidMainfest.xml

It is stored in a binary format that Google never officially named, though it gets called binary XML, compiled XML, or, most often in the community, AXML (Android XML).

So, basically the base64 encoded flag is in the string pool of AndroidManifest.xml file, which is not visible in jadx.

To view the string pool of AndroidManifest.xml we need to use a tool, im using 101 Editor, which was available in yay repo
After installing it , we can open that and we need to install AndroidManifest.bt from the Template Respository.
After installing the Template, we need to excute it and view it by enabling the template result window.
In the Template Result Window, we can expand StringOffset attribute, after scrolling down a bit we see single char values, we can combine all the individual char to get YmtjdGZ7dGgzX3czMXJkM3N0X2IxbjRyeV94bTFfZjBybTR0X2wwbGx9

We can decode the encoded value in terminal,        \
`echo "YmtjdGZ7dGgzX3czMXJkM3N0X2IxbjRyeV94bTFfZjBybTR0X2wwbGx9" | base64 -d`

## Flag
`bkctf{th3_w31rd3st_b1n4ry_xm1_f0rm4t_l0ll}`
