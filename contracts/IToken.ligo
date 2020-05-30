type amt is nat;

type account is record
    balance : nat;
    allowances: map(address, nat);
end

type token_storage is record
  totalSupply: amt;
  ledger: big_map(address, account);
end

type token_action is
| Transfer of (address * address * amt)
| Approve of (address * amt)
| GetAllowance of (address * address * contract(amt))
| GetBalance of (address * contract(amt))
| GetTotalSupply of (unit * contract(amt))


