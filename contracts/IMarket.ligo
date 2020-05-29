type subscription is record
    price : nat;
    fee : nat;
end

type settings_type is record
    owner : address;
    subscriptions : big_map(nat, subscription);
    cashback: nat;
    fee_pool: nat;
    refunds_count: nat;
    deals_count: nat;
    items_db: string;
    orders_db: string;
end

type account is record
    public_key : key;
    balance : nat;
    subscription_type: nat;
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
    items_list: list(nat);
    valid_until: timestamp;
end

type refund is record
    order_id : nat;
    decoded_traking_number : string;
    status: nat;
end

type market_storage is record
  payment: address;
  settings: settings_type;
  accounts: big_map(address, account);
  items: big_map(nat, item);
  orders: big_map(nat, order);
  refunds: big_map(nat, refund);
end

// type marketAction is
// | Transfer of (address * address * amt)
// | Approve of (address * amt)
// | GetAllowance of (address * address * contract(amt))
// | GetBalance of (address * contract(amt))
// | GetTotalSupply of (unit * contract(amt))


function main (const p : unit ; const s : market_storage) :
  (list(operation) * market_storage) is ((nil : list(operation)), s)
