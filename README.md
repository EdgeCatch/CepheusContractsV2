The project consists of two contracts:
- Token: the contract used as main payment method 
- Market: the contract used as a core for marketplace.
# Prerequirements

Install Ligo:
```
curl https://gitlab.com/ligolang/ligo/raw/dev/scripts/installer.sh | bash -s "next"
```
Install dependencies:
```
npm i
```

# Usage

`scripts/cli.js` is used for most of contract interactions. Use `--help` to see full documentation.

To build all contracts run:
 ```
node scripts/cli.js build
 ```

To deploy run:
 ```
node scripts/cli.js deploy Token
node scripts/cli.js deploy Market
 ```
 
 # Entrypoints
 
Token is typical FA1.2 that supports the interface described in [ZIP](https://gitlab.com/tzip/tzip/-/blob/master/proposals/tzip-7/tzip-7.md). 

Market contract has the following functions:
- `SetSettings (subscriptions_map, cashback, items_db)`: updates global market settings, can only be called by owner(it actually can be multisig of DAO to support decentralization principles).
- `WithdrawFee (receiver_address, amount)`: withdraws market fees, can only be called by owner.
- `Register (subscription_type, rsa_public_key)`: register new user account.
- `ChangeSubscription (subscription_type)`: updates user subscription plan.
- `MakeOrder (order_ipfs, item_ipfs, count)`: makes new order.
- `AcceptOrder (order_ipfs, delivery_ipfs)`: confirms order by seller.
- `CancelOrder (order_ipfs)`: cancels order by seller.
- `ConfirmReceiving of (order_ipfs)`: confirms order receiving by buyer. 
- `Withdraw (receiver_address, amount)`: withdraws user tokens from contract.
- `AddItem (item_ipfs, price)`: adds new item to global store.
- `DeleteItem (item_ipfs)`: removes item from global store.
- `RequestRefund (order_ipfs, decrypted_tracking_number)`: makes request refund by seller or buyer.
- `AcceptRefund (order_ipfs, refund_type)`: accepts refund by second actor or market owner.

# Testing
Install mocha and un:
```
./node_modules/mocha/bin/mocha
```
