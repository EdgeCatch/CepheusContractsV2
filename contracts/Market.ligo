#include "IMarket.ligo"
#include "IToken.ligo"

function setSettings (
    const subscriptions : big_map(nat, subscription_type);
    const cashback: nat;
    const items_db: string;
    var s: market_storage ) :  (market_storage) is
block {
    if Tezos.sender =/= s.owner then failwith("Permision denied") else skip;
    s.subscriptions := subscriptions;
    s.cashback := cashback;
    s.items_db := items_db;
 } with s

function withdrawFee (
    const receiver : address;
    const value: nat;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    if Tezos.sender =/= s.owner then failwith("Permision denied") else skip;
    if s.fee_pool < value then failwith("Not enough funds") else skip;
    s.fee_pool := abs(s.fee_pool - value);
 } with (list transaction(Transfer(Tezos.self_address, receiver, value), 0mutez, (get_contract(s.token): contract(token_action))); end, s)

function withdraw (
    const receiver : address;
    const value: nat;
    var s: market_storage ) :  (list(operation) * market_storage) is
block {
    var user : account_type := get_force(Tezos.sender, s.accounts);
    if user.balance < value then failwith("Not enough funds") else skip;
    user.balance := abs(user.balance - value);
    s.accounts[Tezos.sender] := user;
 } with (list transaction(Transfer(Tezos.self_address, receiver, value), 0mutez, (get_contract(s.token): contract(token_action))); end, s)

function register (
    const this : address;
    const subscription: nat;
    const public_key: string;
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
    s.seller_orders[Tezos.sender] := (set [] : set(string));
    s.buyer_orders[Tezos.sender] := (set [] : set(string));
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
    if subscription_info.price = 0n then skip else
        if user.balance < subscription_info.price then
            operations := list transaction(Transfer(Tezos.sender, this, subscription_info.price), 0mutez, (get_contract(s.token): contract(token_action))); end;
        else 
            user.balance := abs(user.balance - subscription_info.price);
        s.fee_pool := s.fee_pool + subscription_info.price;
    user.subscription := subscription;
    s.accounts[Tezos.sender] := user;
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
                delivery_ipfs = "";
                status = 1n;
                item = item_id;
                count = count;
                valid_until = Tezos.now + 2592000;
            end 
        end;
    s.seller_orders[seller_address] := Set.add (ipfs, get_force(seller_address, s.seller_orders));
    s.buyer_orders[Tezos.sender] := Set.add (ipfs, get_force(Tezos.sender, s.buyer_orders));
    var operations : list(operation) := (nil : list(operation));
    if price = 0n then skip else 
        if user.balance < price then
            operations := list transaction(Transfer(Tezos.sender, this, price), 0mutez, (get_contract(s.token): contract(token_action))); end;
        else 
            user.balance := abs(user.balance - price);
        s.fee_pool := s.fee_pool + price;
 } with (operations, s)

function addItem (
    const ipfs: string;
    const price : nat;
    var s: market_storage ) :  (market_storage) is
block {
    var user : account_type := get_force(Tezos.sender, s.accounts);
    s.items[ipfs] := case s.items[ipfs] of
        | Some (item) -> (failwith ("Item created yet") : item_type)
        | None -> record
                seller_id = Tezos.sender;
                price = price;
            end 
        end;
    s.items_db := ipfs;
 } with (s)

function deleteItem (
    const ipfs: string;
    var s: market_storage ) :  (market_storage) is
block {
    var user : account_type := get_force(Tezos.sender, s.accounts);
    case s.items[ipfs] of
        | Some (item) -> if item.seller_id = Tezos.sender or s.owner = Tezos.sender then
            remove ipfs from map s.items
            else failwith ("Not permitted")
        | None -> failwith ("Item doesn't exist")
        end;
 } with (s)

function requestRefund (
    const ipfs: string;
    const decoded_traking_number : string;
    var s: market_storage ) :  (market_storage) is
block {
    case s.orders[ipfs] of
        | Some (order) ->
            if (order.seller_id = Tezos.sender or order.buyer_id = Tezos.sender) and order.status = 2n then block {
                order.status := 3n;
                s.refunds[ipfs] := case s.refunds[ipfs] of
                | Some (order) -> (failwith ("Created yet") : string)
                | None -> decoded_traking_number 
                end;
                s.orders[ipfs] := order;
            } else failwith ("Not permitted")
        | None -> failwith ("Not requested")
        end;
 } with (s)

function pay (
    const ipfs: string;
    const order: order_type;
    var s: market_storage ) :  (market_storage) is
block {
    var buyer : account_type := get_force(order.buyer_id, s.accounts);
    var seller : account_type := get_force(order.seller_id, s.accounts);
    const subscription_info : subscription_type = get_force(seller.subscription, s.subscriptions);
    const fee: nat = order.total_price * subscription_info.fee / 10000n;
    const cashback: nat = order.total_price * s.cashback / 10000n;
    seller.balance := abs(seller.balance + order.total_price - fee);
    seller.deals_count := seller.deals_count + 1n;
    assert(s.fee_pool + fee >= cashback);
    s.fee_pool := abs(s.fee_pool + fee - cashback);
    buyer.balance := buyer.balance + cashback;
    s.accounts[order.seller_id] := seller;
    s.accounts[order.buyer_id] := buyer;
    order.status := 6n;
    s.orders[ipfs] := order;
 } with (s)

function manageRefund (
    const ipfs: string;
    const action: refund_action;
    var s: market_storage ) :  (market_storage) is
block {
    case s.orders[ipfs] of
        | Some (order) -> 
            case action of
            | SellerRefund -> 
                if (order.buyer_id = Tezos.sender or s.owner = Tezos.sender) and order.status = 2n then 
                    s := pay (ipfs, order, s)
                else failwith ("Not permitted")
            | BuyerRefund ->
                if (order.seller_id = Tezos.sender or s.owner = Tezos.sender)and order.status = 2n then block {
                    var buyer : account_type := get_force(order.buyer_id, s.accounts);
                    var seller : account_type := get_force(order.seller_id, s.accounts);
                    buyer.balance := buyer.balance + order.total_price;
                    seller.refunds_count := seller.refunds_count + 1n;
                    s.accounts[order.seller_id] := seller;
                    s.accounts[order.buyer_id] := buyer;
                    order.status := 5n;
                    s.orders[ipfs] := order;
                } else failwith ("Not permitted")
            end
        | None -> failwith ("Not requested")
        end;
 } with (s)

type order_action is
| ConfirmOrderAction of string
| CancelOrderAction
| ReceiveOrderAction

function manageOrder (
    const ipfs: string;
    const action: order_action;
    var s: market_storage ) :  (market_storage) is
block { 
    case s.orders[ipfs] of
        | Some (order) -> 
            case action of
            | ConfirmOrderAction(d) ->
                if order.seller_id = Tezos.sender and order.status = 1n then block {
                        order.status := 2n;
                        order.valid_until := Tezos.now + 2592000;
                        order.delivery_ipfs := d;
                        s.orders[ipfs] := order;
                } else failwith ("Not permitted")
            | CancelOrderAction -> 
                if (order.seller_id = Tezos.sender or order.buyer_id = Tezos.sender) and order.status = 1n then block {
                    var buyer : account_type := get_force(order.buyer_id, s.accounts);
                    buyer.balance := buyer.balance + order.total_price;
                    s.accounts[order.buyer_id] := buyer;
                    order.status := 4n;
                    s.orders[ipfs] := order;
                } else failwith ("Not permitted")
            | ReceiveOrderAction -> 
                if (order.buyer_id = Tezos.sender or (order.seller_id = Tezos.sender and order.valid_until < Tezos.now)) and order.status = 2n then
                    s := pay (ipfs, order, s)
                else failwith ("Not permitted")
            end
        | None -> failwith ("Not requested")
        end;
 } with (s)

function main (const p : market_action ; const s : market_storage) :
    (list(operation) * market_storage) is case p of
    | SetSettings(n) -> ((nil : list(operation)), setSettings(n.0, n.1, n.2, s))
    | WithdrawFee(n) -> withdrawFee(n.0, n.1, s)  
    | Register(n) -> register(Tezos.self_address, n.0, n.1, s)
    | ChangeSubscription(n) -> changeSubscription(Tezos.self_address, n, s)
    | MakeOrder(n) -> makeOrder(Tezos.self_address, n.0, n.1, n.2, s)
    | AcceptOrder(n) -> ((nil : list(operation)), manageOrder(n.0, ConfirmOrderAction(n.1), s))
    | CancelOrder(n) -> ((nil : list(operation)), manageOrder(n, CancelOrderAction, s))
    | ConfirmReceiving(n) -> ((nil : list(operation)), manageOrder(n, ReceiveOrderAction, s))   
    | Withdraw(n) -> withdraw(n.0, n.1, s)
    | AddItem(n) -> ((nil : list(operation)), addItem(n.0, n.1, s))
    | DeleteItem(n) -> ((nil : list(operation)), deleteItem(n, s))
    | RequestRefund(n) -> ((nil : list(operation)), requestRefund(n.0, n.1, s))
    | AcceptRefund(n) -> ((nil : list(operation)), manageRefund(n.0, n.1, s))
  end
