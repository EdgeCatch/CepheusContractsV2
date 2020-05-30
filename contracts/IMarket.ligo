type subscription_type is record
    price : nat;
    fee : nat;
end

type account_type is record
    public_key : key;
    balance : nat;
    subscription: nat;
    subscribed_until: timestamp;
    refunds_count: nat;
    deals_count: nat;
end

type item is record
    seller_id : address;
    price : nat;
    ipfs: string;
end

type order is record
    seller_id : address;
    buyer_id : address;
    ipfs: string;
    total_price: nat;
    status: nat;
    items_list: map(nat, nat);
    valid_until: timestamp;
end

type refund is record
    order_id : nat;
    decoded_traking_number : string;
    status: nat;
end

type market_storage is record
  token: address;
  owner : address;
  subscriptions : big_map(nat, subscription_type);
  cashback: nat;
  fee_pool: nat;
  items_db: string;
  orders_db: string;
  accounts: big_map(address, account_type);
  items: big_map(nat, item);
  orders: big_map(nat, order);
  refunds: big_map(nat, refund);
end

type market_action is
| SetSettings of (big_map(nat, subscription_type) * nat * string * string)
| WithdrawFee of (address * nat)
| Register of (nat * key)
| ChangeSubscription of (nat)
| MakeOrder of (string * map(nat, nat))
| AcceptOrder of (nat)
| CancelOrder of (nat)
| ConfirmReceiving of (nat)
| Withdraw of (address * nat)
| AddItem of (string * nat)
| DeleteItem of (nat)
| RequestRefund of (nat)
| AcceptRefund of (nat)
