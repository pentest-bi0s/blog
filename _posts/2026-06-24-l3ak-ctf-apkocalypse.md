---
layout: post
title: "Apkocalypse - l3ak CTF Writeup"
date: 2026-06-24 00:13:00 +0530
description: "Walkthrough for the Apkocalypse Android reverse engineering challenge from l3ak CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | l3ak CTF |
| Challenge | Apkocalypse |
| Category | Android / Reverse Engineering |

## Description

> Just grab the flag from this simple file storage app.

## Solution

We can start by installing and opening the APK in our emulator

![alt text](/assets/img/posts/l3ak-ctf-apkocalypse/image-1.png)

We cannot enter the app, it crashes immediately and a toast is displayed
`Root access detected, some features may be disabled.`
Now, we can proceed to inspect it in Jadx

![alt text](/assets/img/posts/l3ak-ctf-apkocalypse/image-2.png)

We see that a class `RootDetection` has a method `isDeviceRooted()` which if returned true, the app is terminated
We can use Frida to bypass the check and open the open

```js
Java.perform(() => {
    var Interceptor = Java.use("ctf.l3akctf.filestorage.RootDetection");
    Interceptor.isDeviceRooted.implementation = function(){
        return 0
    }

})
```

![alt text](/assets/img/posts/l3ak-ctf-apkocalypse/image-3.png)

We can access the app now,
From the decompiled code, the app is using a native lib `libstoreftw.so` \
We can inspect that in Ghidra

```
          __s_00 = fopen((char *)__filename,"w");
          if (__s_00 != (FILE *)0x0) {
                    /* try { // try from 001624d8 to 001624e9 has its CatchHandler @ 001625c8 */
            uVar19 = __strlen_chk(pvVar6,0xffffffffffffffff);
            if (5 < uVar19) {
              fwrite("L3AK{",1,5,__s_00);
              fwrite((void *)((long)pvVar6 + 5),1,uVar19 - 5,__s_00);
            }
            fclose(__s_00);
          }
          unlink((char *)__filename);
          operator.delete[](pvVar6);
          if (bVar12 != 0) {
            operator.delete(pbVar7);
          }
          goto LAB_0016255b;
        }
      }
      operator.delete[](pvVar6);
    }
```

This function opens a file writes something starting with `L3AK{` but the file is immediately deleted, We can hook the `fwrite` function and log the argument

```
Interceptor.attach(Module.findExportByName("libc.so", "fwrite"), {
        onEnter: function(args) {
            var size =args[1].toInt32()*args[2].toInt32();
            var flag = Memory.readUtf8String(args[0],size);
            console.log(flag)
        }
    });
```

But, when we click the `Store Flag` method, the app immediately crashes

```

  local_38 = *(long *)(in_FS_OFFSET + 0x28);
  iVar4 = (**(code **)(*param_1 + 0x6d8))(param_1,&DAT_001d79c0);
  if (iVar4 != 0) {
    _DAT_001d79c0 = 0;
  }
  DAT_001d79c8 = (**(code **)(*param_1 + 0xa8))(param_1);
  iVar4 = pthread_create(&DAT_001d79d0,(pthread_attr_t *)0x0,FUN_001627d0,(void *)0x0);
  if (iVar4 == 0) {
    pthread_detach(DAT_001d79d0);
    _DAT_001d79d8 = 1;
  }
```

At the starting of the native method, it starts a thread in which the function `FUN_001627d0` will be running
`FUN_001627d0` is a anti Frida function which does various checking and terminates the app is Frida is found
The bypass of this kind which specifically disables the thread making is available in github \
Source: https://github.com/apkunpacker/AntiFrida_Bypass/blob/main/AntiAntiFrida3.js
So, our finally our Frida script should:

1. Bypass the Java root detection
2. Disable the Frida detection (hook the function what creates the thread)
3. Hook `fwrite` and log its argument

```
// 1. Bypass the Java root detection
Java.perform(() => {
    var Interceptor0 = Java.use("ctf.l3akctf.filestorage.RootDetection");
    Interceptor0.isDeviceRooted.implementation = function(){
        return 0
    }
})

// 2. Disable the frida detection (hook the function what creates the thread)
Java.performNow(function() {
    try {
        let AlertDialog = Java.use("android.app.AlertDialog");
        AlertDialog.show.implementation = function() {
            console.warn("Hooked AlertDialog.show()");
            //stacktrace()
            this.show();
            this.setCancelable(true);
            this.setCanceledOnTouchOutside(true);
        }
    } catch (error) {
        console.error("Error :", error);
    }
})
function stacktrace() {
    Java.perform(function() {
        let AndroidLog = Java.use("android.util.Log");
        let ExceptionClass = Java.use("java.lang.Exception");
        console.warn(AndroidLog.getStackTraceString(ExceptionClass.$new()));
    });
}
try {
    var p_pthread_create = Module.findExportByName("libc.so", "pthread_create");
    var pthread_create = new NativeFunction(p_pthread_create, "int", ["pointer", "pointer", "pointer", "pointer"]);
    Interceptor.replace(p_pthread_create, new NativeCallback(function(ptr0, ptr1, ptr2, ptr3) {
        if (ptr1.isNull() && ptr3.isNull()) {
            console.log("Possible thread creation for checking. Disabling it");
            return -1;
        } else {
            return pthread_create(ptr0, ptr1, ptr2, ptr3);
        }
    }, "int", ["pointer", "pointer", "pointer", "pointer"]));
} catch (error) {
    console.log("Error", error)
}

// 3. Hook `fwrite` and log its argument
Interceptor.attach(Module.findExportByName("libc.so", "fwrite"), {
        onEnter: function(args) {
            var size = args[1].toInt32() * args[2].toInt32();
            var flag = Memory.readUtf8String(args[0], size);
            console.log(content)
        }
    });
```

We can load this script and click on the `store flag` button
- `FLAGL3AK{2fca62dde10486253541959b40635826}`
