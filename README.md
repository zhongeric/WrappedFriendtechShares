## WrappedFriendtechShares
A simple ERC1155 wrapper around shares of friend.tech.

Now you can transfer shares to friends, use them in lending pools as collateral, and more. Also allows for the shares subject to customize the URI of their wrapped ERC1155 so they can self host where their metadata is stored.

PRs welcome!

### Deploy on base

```shell
$ forge script script/WrappedFriendtechSharesFactory.s.sol:WrappedFriendtechSharesFactoryScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### License
GPL-3.0-or-later

### Disclaimer
Code is provided as is, without any warranty or support. These contracts have not been audited for use in production. Use at your own risk.

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/WrappedFriendtechSharesFactory.s.sol:WrappedFriendtechSharesFactoryScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
