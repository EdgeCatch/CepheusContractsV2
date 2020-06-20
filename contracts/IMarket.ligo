type subscription_type is record
    name : string;
    price : nat;
    fee : nat;
end

type account_type is record
    public_key : string;
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
    item: string;
    count: nat;
    valid_until: timestamp;
end

type market_storage is record
  token: address;
  owner : address;
  subscriptions : big_map(nat, subscription_type);
  cashback: nat;
  fee_pool: nat;
  items_db: string;
  accounts: big_map(address, account_type);
  items: big_map(string, item_type);
  seller_orders: big_map(address, set(string));
  buyer_orders: big_map(address, set(string));
  orders: big_map(string, order_type);
  refunds: big_map(string, string);
end

type refund_action is
| SellerRefund
| BuyerRefund

type market_action is
| SetSettings of (big_map(nat, subscription_type) * nat * string)
| WithdrawFee of (address * nat)
| Register of (nat * string)
| ChangeSubscription of (nat)
| MakeOrder of (string * string * nat)
| AcceptOrder of (string)
| CancelOrder of (string)
| ConfirmReceiving of (string)
| Withdraw of (address * nat)
| AddItem of (string * nat)
| DeleteItem of (string)
| RequestRefund of (string * string)
| AcceptRefund of (string * refund_action)
