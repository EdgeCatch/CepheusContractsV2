#include "IMarket.ligo"
#include "IToken.ligo"

function setSettings (
    const subscriptions : big_map(nat, subscription_type);
    const cashback: nat;
    const items_db: string;
    const orders_db: string;
    var s: market_storage ) :  (market_storage) is
block {
    if Tezos.sender =/= s.owner then failwith("Permision denied") else skip;
    s.subscriptions := subscriptions;
    s.cashback := cashback;
    s.items_db := items_db;
    s.orders_db := orders_db;
 } with s

function withdrawFee (
    const this : address;
    const receiver : address;
    const value: nat;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    if Tezos.sender =/= s.owner then failwith("Permision denied") else skip;
    if s.fee_pool < value then failwith("Not enough funds") else skip;
    s.fee_pool := abs(s.fee_pool - value);
 } with (list transaction(Transfer(this, receiver, value), 0mutez, (get_contract(s.token): contract(token_action))); end, s)

function withdraw (
    const this : address;
    const receiver : address;
    const value: nat;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    var user : account_type := get_force(Tezos.sender, s.accounts);
    if user.balance < value then failwith("Not enough funds") else skip;
    user.balance := abs(user.balance - value);
    s.accounts[Tezos.sender] := user;
 } with (list transaction(Transfer(this, receiver, value), 0mutez, (get_contract(s.token): contract(token_action))); end, s)

function register (
    const this : address;
    const subscription: nat;
    const public_key: key;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    s.accounts[Tezos.sender] := case s.accounts[Tezos.sender] of
        | Some (user) -> (failwith ("Registered yet") : account_type)
        | None -> record
                public_key = public_key;
                balance = 0n;
                subscription = subscription;
                subscribed_until = Tezos.now + 2592000;
                refunds_count = 0n;
                deals_count = 0n;
            end 
        end;

    const subscription_info : subscription_type = get_force(subscription, s.subscriptions);
    const operations : list(operation) = if subscription_info.price =/= 0n then
        list transaction(Transfer(Tezos.sender, this, subscription_info.price), 0mutez, (get_contract(s.token): contract(token_action))); end 
        else (nil : list(operation));
    
    s.fee_pool := s.fee_pool + subscription_info.price;
 } with (operations, s)

function changeSubscription (
    const this : address;
    const subscription: nat;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    var user : account_type := get_force(Tezos.sender, s.accounts);

    const subscription_info : subscription_type = get_force(subscription, s.subscriptions);
    var operations : list(operation) := (nil : list(operation));
    if subscription_info.price = 0n then skip else block {
        if user.balance < subscription_info.price then
            operations := list transaction(Transfer(Tezos.sender, this, subscription_info.price), 0mutez, (get_contract(s.token): contract(token_action))); end;
        else 
            user.balance := abs(user.balance - subscription_info.price);
        s.fee_pool := s.fee_pool + subscription_info.price;
    };
 } with (operations, s)

function makeOrder (
    const this : address;
    const ipfs: string;
    const item_id: string;
    const count: nat;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    var user : account_type := get_force(Tezos.sender, s.accounts);
    const item : item_type = get_force(item_id, s.items);
    var price: nat := item.price * count;
    var seller_address : address := item.seller_id;

    s.orders[ipfs] := case s.orders[ipfs] of
        | Some (order) -> (failwith ("Created yet") : order_type)
        | None -> record
                seller_id = seller_address;
                buyer_id = Tezos.sender;
                total_price = price;
                status = 1n;
                item = item_id;
                count = count;
                valid_until = Tezos.now + 2592000;
            end 
        end;

    var operations : list(operation) := (nil : list(operation));
    if price = 0n then skip else block {
        if user.balance < price then
            operations := list transaction(Transfer(Tezos.sender, this, price), 0mutez, (get_contract(s.token): contract(token_action))); end;
        else 
            user.balance := abs(user.balance - price);
        s.fee_pool := s.fee_pool + price;
    };
 } with (operations, s)

function manageOrder (
    const ipfs: string;
    const accept: bool;
    var s: market_storage ) :  (market_storage) is
block { 
    case s.orders[ipfs] of
        | Some (order) -> if order.seller_id = Tezos.sender and order.status = 1n then block {
            if accept then block {
                order.status := 2n;
                s.orders[ipfs] := order;
            } else remove ipfs from map s.orders;
        } else failwith ("Not permitted")
        | None -> failwith ("Not requested")
        end;
 } with (s)

function main (const p : market_action ; const s : market_storage) :
    (list(operation) * market_storage) is case p of
    | SetSettings(n) -> ((nil : list(operation)), setSettings(n.0, n.1, n.2, n.3, s))
    | WithdrawFee(n) -> withdrawFee(self_address, n.0, n.1, s)  
    | Register(n) -> register(self_address, n.0, n.1, s)
    | ChangeSubscription(n) -> changeSubscription(self_address, n, s)
    | MakeOrder(n) -> makeOrder(self_address, n.0, n.1, n.2, s)
    | AcceptOrder(n) -> ((nil : list(operation)), manageOrder(n, True, s))
    | CancelOrder(n) -> ((nil : list(operation)), manageOrder(n, False, s))

    | ConfirmReceiving(n) -> ((nil : list(operation)), s)   
    | Withdraw(n) -> withdraw(self_address, n.0, n.1, s)
    
    | AddItem(n) -> ((nil : list(operation)), s)
    | DeleteItem(n) -> ((nil : list(operation)), s)
    | RequestRefund(n) -> ((nil : list(operation)), s)
    | AcceptRefund(n) -> ((nil : list(operation)), s)
  end

// | MakeOrder of (string * map(nat, nat))
// | AcceptOrder of (nat)
// | CancelOrder of (nat)
// | ConfirmReceiving of (nat)
// | AddItem of (string * nat)
// | DeleteItem of (nat)
// | RequestRefund of (nat)
// | AcceptRefund of (nat)
