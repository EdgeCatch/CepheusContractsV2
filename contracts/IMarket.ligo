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

type item_type is record
    seller_id : address;
    price : nat;
end

type order_type is record
    seller_id : address;
    buyer_id : address;
    total_price: nat;
    status: nat;
    items_list: map(string, nat);
    valid_until: timestamp;
end

type refund_type is record
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
  items: big_map(string, item_type);
  orders: big_map(string, order_type);
  refunds: big_map(string, refund_type);
end

type market_action is
| SetSettings of (big_map(nat, subscription_type) * nat * string * string)
| WithdrawFee of (address * nat)
| Register of (nat * key)
| ChangeSubscription of (nat)
| MakeOrder of (string * map(string, nat))
| AcceptOrder of (nat)
| CancelOrder of (nat)
| ConfirmReceiving of (nat)
| Withdraw of (address * nat)
| AddItem of (string * nat)
| DeleteItem of (nat)
| RequestRefund of (nat)
| AcceptRefund of (nat)
