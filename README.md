The project consists of two contracts:
- Token: the contract used as main payment method 
- Market: the contract used as a core for marketplace.
# Prerequirements

Install Ligo:
```
curl https://gitlab.com/ligolang/ligo/raw/dev/scripts/installer.sh | bash -s "next"
```
Install dependencies:
```
npm i
```

# Usage

`scripts/cli.js` is used for most of contract interactions. Use `--help` to see full documentation.

To build all contracts run:
 ```
node scripts/cli.js build
 ```

To deploy run:
 ```
node scripts/cli.js deploy Token
node scripts/cli.js deploy Market
 ```