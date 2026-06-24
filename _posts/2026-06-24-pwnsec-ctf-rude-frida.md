---
layout: post
title: "Rude Frida - Pwnsec CTF Writeup"
date: 2026-06-24 00:30:00 +0530
description: "Walkthrough for the Rude Frida Android reverse engineering challenge from Pwnsec CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Pwnsec CTF |
| Challenge | Rude Frida |
| Category | Android / Reverse Engineering |

## Description

> Say hello to RudeFrida, it is like your toxic ex who gaslighted you for loving her. - @TK

## Solution

We can install the APK and try to open it in our emulator, but we are instantly thrown out
To know, what's happening we can inspect it in Jadx

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-1.png)

There isn't much in MainActivity, But we see a native lib `libRudeFrida.so` being loaded, we can open this native lib in Ghidra to understand what's happening

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-2.png)

The `stringfromJNI()` calls two other functions:

1. is_root_simple()
2. FridaCheck()

We can inspect both these functions to understand what they are doing-

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-3.png)

`is_root_simple()` is trying to access some root binaries in the device for root detection

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-4.png)

`FridaCheck()` checks for the default ports used by frida-server
We would have to bypass both the checks to open the app
Also, on inspecting in Ghidra we see another function `get_flag` which takes in two integer parameters

```c
if (param_1 + param_2 == 0x539) {
 uVar12 = 0xdeadbeefcafebabe;
 local_a00 = (undefined **)0xdeadbeefcafebabe;
 lVar9 = 1;
 lVar10 = 2;
 while( true )
}
```

And the sum of the passed parameters has to be equal to `0x539` which is `1337` in decimal
And if we scroll down a bit,

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-5.png)

This function does not return anything, but logs some strings which probably could be the flag
So, our Frida script must :

1. bypass root check
2. bypass Frida check
3. call `get_flag`

To bypass the root check, I'm using a script from the Frida CodeShare \
Source: https://codeshare.frida.re/@fdciabdul/frida-multiple-bypass/
This also includes `ssl-unpinning` which we do not require here, so we only need to take till line `805`
To bypass the Frida checks I'm using `phantom-frida` \
Source: https://github.com/TheQmaks/phantom-frida

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-6.png)

`phatom-Frida` bypasses all the major 16 detection techniques
To call the `get_flag` method, we should first know the exported symbol - To find that we just need to do a search in Ghidra

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-8.png)

Now, our Frida script -

```js
// after our root bypass
const NativeMethod = Process.getModuleByName('libRudefrida.so');
const f = NativeMethod.getExportByName('_Z8get_flagii');
const myNative= new NativeFunction(f,['void'],['int','int']);
myNative(1330,7);
```

> P.S: Our script will not have any anti-Frida bypass since we are using `phantom-frida`

Now, we just need to run this script and check our logs,

![alt text](/assets/img/posts/pwnsec-ctf-rude-frida/image-7.png)

## Flag

```text
FLAG:flag{w3_l4ugh3d_4t_y0ur_Fr1d4_scr1p7_but_it_st1ll_w0rk5_lol}
```
