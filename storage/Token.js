const { MichelsonMap } = require('@taquito/michelson-encoder');

module.exports = {
    owner: "tz1bQEJqMqC92ommfsRB6pWG9LVBKNgXPysh",
    totalSupply: "10000000000",
    ledger: MichelsonMap.fromLiteral({
        "tz1bQEJqMqC92ommfsRB6pWG9LVBKNgXPysh": {
            balance: "3000000000",
            allowances: MichelsonMap.fromLiteral({})
        },
        "tz1YMUyxoBs1FjLGz5caLwh9ScxnnxXWAuMn": {
            balance: "3000000000",
            allowances: MichelsonMap.fromLiteral({})
        },
        "tz1ec53idwXui2LHEP1E9A3cVTT229gghEsW": {
            balance: "2000000000",
            allowances: MichelsonMap.fromLiteral({})
        },
        "tz1UbJvKdgfP4WXVttHyL7LLaMon5TTmdp73": {
            balance: "2000000000",
            allowances: MichelsonMap.fromLiteral({})
        }
    })
}