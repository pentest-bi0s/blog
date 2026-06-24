---
layout: post
title: "Specialist Beta - Cyberchaze CTF Writeup"
date: 2026-06-24 00:05:00 +0530
description: "Walkthrough for the Specialist Beta Android reverse engineering challenge from Cyberchaze CTF."
categories: [Writeups, CTF, Mobile Security]
tags: [ctf, android, reverse engineering, mobile security]
author: Narain Krishna
toc: true
---

## Challenge Info

| Field | Details |
| --- | --- |
| CTF | Cyberchaze CTF |
| Challenge | Specialist Beta |
| Category | Android / Reverse Engineering |

## Solution

When we inspect the Manifest file,we see ann activity which handles deeplinks

![alt text](/assets/img/posts/cyberchaze-ctf-specialist-beta/image.png)

Further, we can check the code of that activity

![alt text](/assets/img/posts/cyberchaze-ctf-specialist-beta/image-1.png)

Our intent should have a data uri, the length of it should be more than 14 chars but not equal to 27
And a base64 value is getting decoded, to which a substring of our data uri is being checked
We can get that value from the strings.xml file

![alt text](/assets/img/posts/cyberchaze-ctf-specialist-beta/image-2.png)

1. base64 encoded value : ZGVlcGxpbmstc2VjcmV0LWludGVudC1kYXRh
2. base64 decoded value : deeplink-secret-intent-data

`strSubstring` will contain the string from the data uri we pass but starting only from the index 14
So the first 14(index 0 - 13) characters of the uri we pass does not matter, to that we can append `deeplink-secret-intent-data`
So, our POC app:

```
 b1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent();
                intent.setAction("android.intent.action.VIEW");
                intent.setComponent(new ComponentName("beta.smartcorp.specialist","beta.smartcorp.specialist.ui.map.MapFragment"));
                Uri data = Uri.parse("11111111111111deeplink-secret-intent-data");
                intent.setData(data);
                startActivity(intent);

            }
        });
```

And then we get the flag,

![alt text](/assets/img/posts/cyberchaze-ctf-specialist-beta/image-3.png)

## Flag

```text
flag: cyberchaze{prot3ct_deeplink$_You_F0uNd_tHe_fl3g}
```
