const { MichelsonMap } = require('@taquito/michelson-encoder');

module.exports = {
    token: "KT1AnRxYfAivSmNmsnT1v1uXxz4tQfxVWvJ6",
    owner: "tz1bQEJqMqC92ommfsRB6pWG9LVBKNgXPysh",
    cashback: "10",
    fee_pool: "0",
    items_db: "bafyreicbaggkk7fymwwpdxelydxftfh7naq7dxlzz6tptuycp55u4rzzle",
    subscriptions: MichelsonMap.fromLiteral({
        "0": {
            name: "Free",
            price: "0",
            fee: "200"
        }
    }),
    accounts: new MichelsonMap(),
    items: new MichelsonMap(),
    orders: new MichelsonMap(),
    refunds: new MichelsonMap()
}
