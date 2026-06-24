---
layout: post
title: "nowyouseeme - Shakti CTF Writeup"
date: 2026-06-24 00:31:00 +0530
description: "Walkthrough for the nowyouseeme Android reverse engineering challenge from Shakti CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Shakti CTF |
| Challenge | nowyouseeme |
| Category | Android / Reverse Engineering |

## Description

> Some secrets don’t like the spotlight. They prefer memory.

## Solution

We can  start by installing the APK and opening it in our emulator.

![alt text](/assets/img/posts/shakti-ctf-nowyouseeme/image-1.png)

It displays the message in reverse, which we can read to

```
This is not a part of the module, making it too hard
```

Now, we can proceed to inspect it in Jadx,

![alt text](/assets/img/posts/shakti-ctf-nowyouseeme/image-2.png)

The Main Activity hasn't much in it, but wee see another class `FlagEngine` and calls a native method `getFlag(str)` but one thing is confusing,

```java
static {
        System.loadLibrary("flagengine");
    }
}
```

The APK does not have `libflagengine.so`, the native lib bundles with it is `libnowyouseeme.so`, that means the native library is never loaded
If we tried to hook the `getFLag(str)` method using Frida, we always get error:

```
Spawned `com.shaktictf.nowyouseeme`. Resuming main thread!
Error: unable to find module 'libnowyouseeme.so'
    at value (frida/runtime/core.js:381)
    at <eval> (/home/notRain/Downloads/script.js:27)
```

So, we would have to rely on Ghidra to get the flag,

![alt text](/assets/img/posts/shakti-ctf-nowyouseeme/image-3.png)

We see that this function takes in our input and compares it with `mysecretkey` and if it matches it does a xor encryption with the encrypted bytes stored in the memory `&DAT_001006b0`
If we click on `&DAT_001006b0` we can view the raw bytes and extract it

```
        001006b0 00              ??         00h
        001006b1 00              ??         00h
        001006b2 21              ??         21h    !
        001006b3 00              ??         00h
        001006b4 00              ??         00h
        001006b5 00              ??         00h
        001006b6 00              ??         00h
        001006b7 20              ??         20h
        001006b8 20              ??         20h
        001006b9 24              ??         24h    $
        001006ba 48              ??         48h    H
        001006bb 03              ??         03h
        001006bc 46              ??         46h    F
        001006bd 68              ??         68h    h
        001006be 35              ??         35h    5
        001006bf 58              ??         58h    X
        001006c0 35              ??         35h    5
        001006c1 05              ??         05h
        001006c2 10              ??         10h
        001006c3 36              ??         36h    6
        001006c4 2e              ??         2Eh    .
        001006c5 47              ??         47h    G
        001006c6 39              ??         39h    9
        001006c7 3d              ??         3Dh    =
        001006c8 02              ??         02h
        001006c9 5b              ??         5Bh    [
        001006ca 5a              ??         5Ah    Z
        001006cb 59              ??         59h    Y
        001006cc 37              ??         37h    7
        001006cd 37              ??         37h    7
        001006ce 34              ??         34h    4
        001006cf 03              ??         03h
        001006d0 47              ??         47h    G
        001006d1 36              ??         36h    6
        001006d2 72              ??         72h    r
        001006d3 18              ??         18h
        001006d4 0a              ??         0Ah
        001006d5 2a              ??         2Ah    *
        001006d6 42              ??         42h    B
        001006d7 5a              ??         5Ah    Z
        001006d8 03              ??         03h
        001006d9 59              ??         59h    Y
        001006da 0c              ??         0Ch
        001006db 58              ??         58h    X
        001006dc 26              ??         26h    &
        001006dd 34              ??         34h    4
        001006de 17              ??         17h
        001006df 59              ??         59h    Y
        001006e0 27              ??         27h    '
        001006e1 47              ??         47h    G
        001006e2 39              ??         39h    9
        001006e3 6a              ??         6Ah    j
        001006e4 01              ??         01h
        001006e5 06              ??         06h
        001006e6 03              ??         03h
```

There are 56 bytes, we can write a python program to xor these bytes with `myscretkey`

```py
data = [
    0x00,0x00,0x21,0x00,0x00,0x00,0x00,0x20,
    0x20,0x24,0x48,0x03,0x46,0x68,0x35,0x58,
    0x35,0x05,0x10,0x36,0x2e,0x47,0x39,0x3d,
    0x02,0x5b,0x5a,0x59,0x37,0x37,0x34,0x03,
    0x47,0x36,0x72,0x18,0x0a,0x2a,0x42,0x5a,
    0x03,0x59,0x0c,0x58,0x26,0x34,0x17,0x59,
    0x27,0x47,0x39,0x6a,0x01,0x06,0x03
]

key = "mysecretkey"

for i in range(len(data)):
    print(chr(data[i] ^ ord(key[i % len(key)])), end="")
```

If we run the program we get garbage value, `myRecreTKA1n?;Gd]K>TDq>9+RC_f>[koI0?w2i!KMd<D5\jcz`
This happened probably because the key is not `mysecretkey`, Upon closer inspection in Jadx,

![alt text](/assets/img/posts/shakti-ctf-nowyouseeme/image-4.png)

This class has a static method `getKey` which opens zipped file `assets/resources.dat` and then does something but returns a string back
We can use Frida to call this method and see if it returns the actual key

```java
Java.perform(() => {
    var ActivityThread = Java.use('android.app.ActivityThread');
    var context = ActivityThread.currentApplication().getApplicationContext();
    var Interceptor = Java.use("com.shaktictf.nowyouseeme.DataBridge");
    console.log(Interceptor.getKey(context))

})
```

We use `Java.use('android.app.ActivityThread');` and `ActivityThread.currentApplication().getApplicationContext();` since the argument passed has to be `context`
If we load this script,

![alt text](/assets/img/posts/shakti-ctf-nowyouseeme/image-5.png)

It returns the string `Sh@ktiCtf_1337` we can try this as the key to decrypt the raw bytes we found

```py
data = [
    0x00,0x00,0x21,0x00,0x00,0x00,0x00,0x20,
    0x20,0x24,0x48,0x03,0x46,0x68,0x35,0x58,
    0x35,0x05,0x10,0x36,0x2e,0x47,0x39,0x3d,
    0x02,0x5b,0x5a,0x59,0x37,0x37,0x34,0x03,
    0x47,0x36,0x72,0x18,0x0a,0x2a,0x42,0x5a,
    0x03,0x59,0x0c,0x58,0x26,0x34,0x17,0x59,
    0x27,0x47,0x39,0x6a,0x01,0x06,0x03
]

key = "Sh@ktiCtf_1337"

for i in range(len(data)):
    print(chr(data[i] ^ ord(key[i % len(key)])), end="")
```

We get the flag:`shakticTF{y0u_F0und_M3_b3hinD_th3_illusi0n_0f_c0D3_5050}`
