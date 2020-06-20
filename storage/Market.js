const { MichelsonMap } = require('@taquito/michelson-encoder');
const fs = require("fs");

const { address: tokenAddress } = JSON.parse(
    fs.readFileSync("./deploy/Token.json").toString()
);
module.exports = {
    token: tokenAddress,
    owner: "tz1bQEJqMqC92ommfsRB6pWG9LVBKNgXPysh",
    cashback: "10",
    fee_pool: "0",
    items_db: "",
    subscriptions: MichelsonMap.fromLiteral({
        "0": {
            name: "Free",
            price: "0",
            fee: "200"
        }
    }),
    accounts: new MichelsonMap(),
    items: new MichelsonMap(),
    seller_orders: new MichelsonMap(),
    buyer_orders: new MichelsonMap(),
    orders: new MichelsonMap(),
    refunds: new MichelsonMap()
}
