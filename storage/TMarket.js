const { MichelsonMap } = require('@taquito/michelson-encoder');

module.exports = {
    token: "KT1AnRxYfAivSmNmsnT1v1uXxz4tQfxVWvJ6",
    owner: "tz1bQEJqMqC92ommfsRB6pWG9LVBKNgXPysh",
    cashback: "10",
    fee_pool: "0",
    items_db: "Qmeg1Hqu2Dxf35TxDg18b7StQTMwjCqhWigm8ANgm8wA3p",
    orders_db: "Qmeg1Hqu2Dxf35TxDg18b7StQTMwjCqhWigm8ANgm8wA3p",
    subscriptions: MichelsonMap.fromLiteral({
        "0": {
            price: "0",
            fee: "200"
        },
        "1": {
            price: "100",
            fee: "100"
        }
    }),
    accounts: new MichelsonMap(),
    items: new MichelsonMap(),
    orders: new MichelsonMap(),
    refunds: new MichelsonMap()
}
