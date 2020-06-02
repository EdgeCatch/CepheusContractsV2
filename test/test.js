const { TezosToolkit } = require("@taquito/taquito");
const fs = require("fs");
const assert = require("assert");
const BigNumber = require("bignumber.js");
const path = require('path');
const provider = "https://api.tez.ie/rpc/carthagenet";
const { InMemorySigner } = require("@taquito/signer");
const { MichelsonMap } = require('@taquito/michelson-encoder');


const { address: tokenAddress } = JSON.parse(
    fs.readFileSync(path.join(__dirname, "../deploy/Token.json")).toString()
);
const { address: marketAddress } = JSON.parse(
    fs.readFileSync(path.join(__dirname, "../deploy/Market.json")).toString()
);

class Market {

    constructor(Tezos, contract) {
        this.tezos = Tezos;
        this.contract = contract;
    }
    static async init(Tezos) {
        return new Market(Tezos, await Tezos.contract.at(marketAddress))
    }

    async getFullStorage(maps = { subscriptions: [], accounts: [], items: [], orders: [], refunds: [] }) {
        const storage = await this.contract.storage();
        var result = {
            ...storage
        };
        for (let key in maps) {
            result[key + "Extended"] = await maps[key].reduce(async (prev, current) => {
                let entry;

                try {
                    entry = await storage[key].get(current);
                } catch (ex) {
                    console.error(ex);
                }

                return {
                    ...await prev,
                    [current]: entry
                };
            }, Promise.resolve({}));
        }
        return result;
    }

    async setSettings(subscriptions, cashback, items_db, orders_db) {
        const operation = await this.contract.methods
            .setSettings(subscriptions, cashback, items_db, orders_db)
            .send();
        await operation.confirmation();
        return operation;
    }

    async register(subscription, public_key) {
        let storage = await this.getFullStorage({ subscriptions: [subscription] });
        if (storage.subscriptionsExtended[subscription].price != 0) {
            let token = await this.tezos.contract.at(storage.token);
            let operation = await token.methods
                .approve(marketAddress, storage.subscriptionsExtended[subscription].price)
                .send();
            await operation.confirmation();
        }
        const operation = await this.contract.methods
            .register(subscription, public_key)
            .send();
        await operation.confirmation();
        return operation;
    }
}
const setup = async (keyPath = "../key") => {
    keyPath = path.join(__dirname, keyPath)
    const secretKey = fs.readFileSync(keyPath).toString();
    let tezos = new TezosToolkit();
    await tezos.setProvider({ rpc: provider, signer: await new InMemorySigner.fromSecretKey(secretKey) });
    return tezos;
};

describe('Market', function () {
    describe('SetSettings()', function () {
        it('should update settings', async function () {
            this.timeout(100000);
            let market = await Market.init(await setup());
            let initialStorage = await market.getFullStorage({ subscriptions: ["0", "1"] });
            assert.equal(initialStorage.fee_pool, 0);
            let subscriptions = MichelsonMap.fromLiteral({
                "0": {
                    price: "0",
                    fee: "200"
                },
                "1": {
                    price: "100",
                    fee: "100"
                },
                "2": {
                    price: "5000",
                    fee: "0"
                }
            });
            let operation = await market.setSettings(subscriptions, 100, "Qmeg1Hqu2Dxf35TxDg18b7StQTMwjCqhWigm8ANgm8wA3p", "Qmeg1Hqu2Dxf35TxDg18b7StQTMwjCqhWigm8ANgm8wA3p")
            assert(operation.status === "applied", "Operation was not applied");
            let updatedStorage = await market.getFullStorage({ subscriptions: ["0", "1", "2"] });
            assert.equal(updatedStorage.subscriptionsExtended["2"].price, 5000);
            assert.equal(updatedStorage.subscriptionsExtended["2"].fee, 0);
            assert.equal(updatedStorage.cashback, 100);
        });
    });
    describe('Register()', function () {
        it('should register free account', async function () {
            this.timeout(100000);
            let Tezos = await setup();
            let market = await Market.init(Tezos);
            let pkh = await Tezos.signer.publicKeyHash();
            let initialStorage = await market.getFullStorage({ accounts: [pkh] });
            assert.equal(initialStorage.accounts[pkh], undefined);

            let operation = await market.register("0", await Tezos.signer.publicKey());
            assert(operation.status === "applied", "Operation was not applied");
            let updatedStorage = await market.getFullStorage({ accounts: [pkh] });

            assert.equal(updatedStorage.accountsExtended[pkh].public_key, await Tezos.signer.publicKey());
            assert.equal(updatedStorage.accountsExtended[pkh].balance, 0);
            assert.equal(updatedStorage.accountsExtended[pkh].subscription, 0);
            assert.equal(updatedStorage.accountsExtended[pkh].refunds_count, 0);
            assert.equal(updatedStorage.accountsExtended[pkh].deals_count, 0);
        });

        it('should register paid account', async function () {
            this.timeout(100000);
            let Tezos = await setup("../key1");
            let market = await Market.init(Tezos);
            let pkh = await Tezos.signer.publicKeyHash();
            let initialStorage = await market.getFullStorage({ accounts: [pkh] });
            assert.equal(initialStorage.accounts[pkh], undefined);

            let operation = await market.register("1", await Tezos.signer.publicKey());
            assert(operation.status === "applied", "Operation was not applied");
            let updatedStorage = await market.getFullStorage({ accounts: [pkh] });

            assert.equal(updatedStorage.accountsExtended[pkh].public_key, await Tezos.signer.publicKey());
            assert.equal(updatedStorage.accountsExtended[pkh].balance, 0);
            assert.equal(updatedStorage.accountsExtended[pkh].subscription, 1);
            assert.equal(updatedStorage.accountsExtended[pkh].refunds_count, 0);
            assert.equal(updatedStorage.accountsExtended[pkh].deals_count, 0);
        });
    });
});


// | WithdrawFee of (address * nat)
// | ChangeSubscription of (nat)
// | MakeOrder of (string * string * nat)
// | AcceptOrder of (string)
// | CancelOrder of (string)
// | ConfirmReceiving of (string)
// | Withdraw of (address * nat)
// | AddItem of (string * nat)
// | DeleteItem of (string)
// | RequestRefund of (string * string)
// | AcceptRefund of (string * refund_action)
