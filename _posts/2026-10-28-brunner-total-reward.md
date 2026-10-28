---
layout: post
title: "Total-Reward - BrunnerCTF Writeup"
date: 2026-10-28 00:00:00 +0530
description: "Walkthrough for the Total-Reward Android reverse engineering challenge from BrunnerCTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

# Challenge Info

| Field | Details |
| --- | --- |
| CTF | BrunnerCTF |
| Challenge | Total-Reward |
| Category | Android / Reverse Engineering |

# Solution
--------------

We can start by decompiling the APK in jadx.

```
public final class MainActivity extends ReactActivity {
    @Override // com.facebook.react.ReactActivity
    protected String getMainComponentName() {
        return "TotalReward";
    }

    @Override // com.facebook.react.ReactActivity
    protected ReactActivityDelegate createReactActivityDelegate() {
        return new DefaultReactActivityDelegate(this, getMainComponentName(), DefaultNewArchitectureEntryPoint.getFabricEnabled());
    }
}
```

This is the MainActivity of the APK, it is clear that the APK was developed in ReactNative, which we can confirm as the `index.android.bundle.` is present in `/assets` dir.
We can export the `index.android.bundle.` file from jadx, to identify the file type.

```
[muahahaha... ⚜️ ]  ❯ file index.android.bundle                                                                          
index.android.bundle: Hermes JavaScript bytecode, version 98
[muahahaha... ⚜️ ]  ❯
```

We can use hermes decompiler to decompile the hermes bytecode to a readable js file.     
link: https://github.com/P1sec/hermes-dec        
`hbc-decompiler assets/index.android.bundle /tmp/my_output_file.js` to get the output js file.
The `js` file has nearly 200,000 lines of code, We can either use grep or `ctrl+f` in any text editor to find relevant code associated with the flag.


```
 StoreToEnvironment(env_register=1, slot_index=3, value_register=4);
        r2 = {'ALPHABET': '23456789ABCDEFGHJKLMNPQRSTUVWXYZ', 'PREFIX': 'BB', 'GROUPS': 3, 'GROUP_LEN': 4, 'PAYLOAD_LEN': 12, 'CHAIN_SUM': null, 'MODULUS': 32, 'FREE_POSITIONS': null, 'BAND_POSITIONS': null, 'BAND_RADIX': 32, 'CHECKSUM_MODULUS': 251, 'CHECKSUM_TARGET': 118, 'BANDS': null, 'SEAL_SALT': 'totalreward', 'SEAL_ITERATIONS': 10000, 'SEAL_KEY_BYTES': 32, 'valueOf': null, 'payloadOf': null, 'chainOk': null, 'checksumOk': null, 'bandOf': null, 'validate': null};
        r2[5] = r7;
        r2[7] = r6;
        r2[8] = r5;
        r2[12] = r4;
```

This code snippet has the details about the encrpytion like `'SEAL_SALT': 'totalreward'`, `SEAL_ITERATIONS': 10000,` etc..           
Nearby to it , we can see functions like `openSealed()` and `deriveKeys()`

Here, is an abstract idea of what the APK is doing :
```Reward Code
    |
    v
validate
    |
    +-------------------+
    |                   |
    v                   v
 chainOk            checksumOk
    |                   |
    +---------+---------+
              |
              v
            bandOf
              |
              v
       Band 4 / 5 / 6 / 9
              |
              v
 Select encryptedRecords[band]
              |
              v
          openSealed
              |
              v
          deriveKeys
              |
              v
         PBKDF2-SHA256
         Salt: totalreward
         Iterations: 10000
              |
        +-----+-----+
        |           |
        v           v
      encKey      macKey
        |           |
        v           v
   AES-256 CTR  HMAC-SHA256
        ^           ^
        |           |
        +-----+-----+
              |
              v
        Decrypted JSON
              |
              v
       Entitlements / Note
```

The reward code is provided in the challenge description :      
`Your current code is: BB-YG27-PM2J-CY63 `

There are 4 encryptions text or bands in the js file.       

1. Band 4: '/0TM+3Zu/jUoxlBl02yKEcm+wlYCmGouQf3t7mp5VoqHFuE8lqqP4a3bajNp37l5eg/Qxpoggdnf7n2fJ/mJ94YBG6T+1tHuNsbZRYOk8OoiMVVBh40Q5aw04pk49sXq1+ypDZtupAHgOZhUdSHKkQHA5tCMx5/idV8zyS+Y6ogMbqt0LIHp8/kexlh1WuZXOuvoIGHrvR6Aia8frZTTauEBNQDI33RiCQ=='          

2. Band 5: 'ddrrpl2jQZiIoOyCdcee17EiC32r+0PTYTpCAWfDETtuZUS0Neb+6vk//nMEc0H+21L0g/MDgriXpPItuCe8A6Uiw1nI0gJGYH7inAAPbfsJTJZI68dn3IVoH/XCHzjqpSkuxmpX2nerTDKhBT06i/CHMlh5VdDrYWau0bq7NiTNSRx4sMVgtirfKbZWrSX/9P/LG2ponwiT/YNlTcjHoKxSkcuYlmpDUouiwCf6fUG3aGm6Y+BitnIVxckTCZHlo4cxNj2Gu+ooCqJo'          

3. Band 6: 'tsmmYMdty1BSP1jwuFilwqSv5fFTHsNYh2NzwN5CK2aWGlWCjDRrAkCnKdYMNeE3pLHQ+fwkhTFxJBEj3BthzatvaUYouXDja+99I7kXqWLWIfmqcSYT5Wf1LYdNw8Wo9srDUxreeOB9QSs1F/Bz9BqKwWNtLHcK3The8aOEVR76mgBqWGOfYI+vgs2wdLbHGX8lp9lkJKLXSIA3T4S11IgC078XW3mZVHxpe404yCMdt/qETuA/s1zUPsLUR0kRk6k4PxnSrZLze8zAdS6hv2/SX2sule01hRw='         

4. Band 9: 'nbbYsurcNj9ZOyCx+opexT8Z8FCdRQL2iTTDu+iXz0Vg9SLqhiOGA9BqeF+CpAEpuGy6WnVMo4x7NyzZIPx6amhEkb6CsSozpx8xfAQ81KNw6IVC+bYvm3NH0sCgpwGT+4UXF4bgXIdCjSJ676/TXS45jOXIDmYDL3jTVznAbbI5u99ueee6056aqd3EzPAG1vpXZzeHoBtKsgSlMoWGmNxKjYIrl26040G8evNNHE0YfbUlXelnB6Y/As11cHv2gVIAwnotsbTMWkRaMiZ9dJuRIc2bGW4MCqBxQJ3dkBUkK05JVql9wWZnHg7CQH23t+GLx+SgKPtcz+FuP6m+X0266Lxdm6DpimfdWBMdCIrAtTp0M0u3QmHHNRhOjz3c7c3z5iZlvEI5+pBgWNN1ry7HtpDFGuvPFdwngJqQlBHguxrGFypLbC2sW8REc82iuSJ57uvuohOxpVHuf8+gwIBmbuQNVILpBGPDxEP+DfBTWBa9c3K+hF3Y/n65nfzV9965+s+4CMYv7yDI6DI3wuLblZsjCXU+PRhFBXGpykJ4Qibb2o4QuJRSQq4iG30tWWp/aVfj8XLRPvfP       

The flow of decryption is :  

```Band 4/5/6/9 Encrypted Base64
          |
          v
     Base64 Decode
          |
     +----+----------------+
     |                     |
     v                     v
Extract Nonce        Extract Ciphertext
First 16 bytes       Exclude last 32 bytes
     |                     |
     |                     |
     |          Reward Code: BB-FZ2N-8423-THBJ
     |                     |
     |                     v
     |               PBKDF2-SHA256
     |               Salt: totalreward
     |               Iterations: 10000
     |                     |
     |                     v
     |                Derived Key
     |                     |
     |                     v
     |                 HMAC-SHA256
     |               totalreward-enc
     |                     |
     |                     v
     |               Encryption Key
     |                     |
     v                     v
     +----------> AES-256 ECB
                  Encrypt Counter
                       |
                       v
                    Keystream
                       |
                       v
                      XOR <---------- Ciphertext
                       |
                       v
                   Decrypted
```
We can write a python script with the above functionality and check for all the bands.

```
import base64, hashlib, hmac
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

code = "BB-FZ2N-8423-THBJ"

data = base64.b64decode("""<encrypted text(band 4/5/6/9)>""")

dk = hashlib.pbkdf2_hmac("sha256", code.encode(), b"totalreward", 10000, 32)
key = hmac.new(dk, b"totalreward-enc", hashlib.sha256).digest()

nonce = data[:16]
ciphertext = data[16:-32]

counter = bytearray(nonce)
aes = Cipher(algorithms.AES(key), modes.ECB()).encryptor()
out = bytearray()

for i in range(0, len(ciphertext), 16):
    stream = aes.update(bytes(counter))
    out += bytes(a ^ b for a, b in zip(ciphertext[i:i+16], stream))

    for j in range(15, -1, -1):
        counter[j] = (counter[j] + 1) & 255
        if counter[j]:
            break

print(out.decode())
```

We just need to change the band and check all of them.When we decrypt band 9 , we get :

```
{"band":"Board","entitlements":["Annual leave: not tracked","Pension: 22% employer contribution, uncapped","Long-term incentive: see schedule B","Discretionary bonus pool: 40–120% of base","Car allowance, Copenhagen parking, driver on request"],"note":"Schedule B is not circulated below board band and is not printed on reward statements.
brunner{th3_3nt1tl3m3nt_ch3ck_r0d3_4l0ng_1n_th3_4pp}"}

```

# Flag
------
```text
Flag : brunner{th3_3nt1tl3m3nt_ch3ck_r0d3_4l0ng_1n_th3_4pp}
```