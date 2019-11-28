let secret = {};
try {
  secret = require('./.secret.json');
} catch(err) {
  console.dir("warning: .secret.json file not found; this is only needed to deploy to testnet or livenet etc..");
}

module.exports = {
  // default applies to all environments
  default: {
    // Blockchain node to deploy the contracts
    deployment: {
      host: "localhost", // Host of the blockchain node
      port: 8545, // Port of the blockchain node
      type: "rpc" // Type of connection (ws or rpc),
      // Accounts to use instead of the default account to populate your wallet
      /*,accounts: [
        {
          privateKey: "your_private_key",
          balance: "5 ether"  // You can set the balance of the account in the dev environment
                              // Balances are in Wei, but you can specify the unit with its name
        },
        {
          privateKeyFile: "path/to/file", // Either a keystore or a list of keys, separated by , or ;
          password: "passwordForTheKeystore" // Needed to decrypt the keystore file
        },
        {
          mnemonic: "12 word mnemonic",
          addressIndex: "0", // Optionnal. The index to start getting the address
          numAddresses: "1", // Optionnal. The number of addresses to get
          hdpath: "m/44'/60'/0'/0/" // Optionnal. HD derivation path
        }
      ]*/
    },
    // order of connections the dapp should connect to
    dappConnection: [
      "$WEB3",  // uses pre existing web3 object if available (e.g in Mist)
      "ws://localhost:8546",
      "http://localhost:8545"
    ],
    gas: "auto",
    strategy: 'explicit', // 'implicit' is the default
    contracts: {
      PictosisToken: {
        args: [ Math.round((new Date).getTime() / 1000 + 10000), '1000000000000000000000000000' ]        
      },
      PictosisGenesisToken: {
        args: []
      },
      PictosisGenesisExchanger: {
        args: ["$PictosisGenesisToken", "$PictosisToken"]
      },
      PictosisCrowdsale: {
        args: [ 
          parseInt((new Date()).getTime() / 1000, 10) + 100, 
          parseInt((new Date()).getTime() / 1000, 10) + 5000, 
          '1500', 
          "$accounts[0]", 
          "$PictosisToken",
          '625000000000000000000000000', // 500MM
          '100000000000000000000' // 100 eth
        ],
        onDeploy: ['PictosisToken.methods.addMinter("$PictosisCrowdsale").send()']
        // TODO: preguntar si se van a repartir todos los genesis tokens antes del presale y crowdsale
        // SI es asi, hacer deploy de exchanger y tokens al crear el picto token
      }
    }
  },

  // default environment, merges with the settings in default
  // assumed to be the intended environment by `embark run`
  development: {
    dappConnection: [
      "ws://localhost:8546",
      "http://localhost:8545",
      "$WEB3"  // uses pre existing web3 object if available (e.g in Mist)
    ]
  },

  // merges with the settings in default
  // used with "embark run privatenet"
  privatenet: {
  },

  // merges with the settings in default
  // used with "embark run testnet"
  testnet: {
    contracts: {
      PictosisToken: {
        args: [ Math.round((new Date).getTime() / 1000 + 86400 * 3), '1000000000000000000000000000' ]        
      },
      PictosisGenesisToken: {
        args: []
      },
      PictosisGenesisExchanger: {
        args: ["$PictosisGenesisToken", "$PictosisToken"]
      },
      PictosisCrowdsale: {
        args: [ 
          Math.round((new Date()).getTime() / 1000) + 600, 
          Math.round((new Date()).getTime() / 1000) + 86400 * 3, 
          '1500', 
          "$accounts[0]", 
          "$PictosisToken",
          '3000000000000000000000',  // 3000
          '15000000000000000000000', // 15000
          '1000000000000000000' // 1 eth
        ],
        onDeploy: ['PictosisToken.methods.addMinter("$PictosisCrowdsale").send()']
      },
      PictosisBounties: {
        args: ["$PictosisGenesisToken", "3000000000000000000000"],
        onDeploy: ['PictosisGenesisToken.methods.addMinter("$PictosisBounties").send()']
      },
    },
    deployment: {
      accounts: [
        {
          mnemonic: secret.mnemonic,
          hdpath: "m/44'/60'/0'/0/",
          numAddresses: "10"        }
      ],
      host: `ropsten.infura.io/${secret.infuraKey}`,
      port: false,
      protocol: 'https',
      type: "rpc"
    },
    dappConnection: ["$WEB3"]
  },

  // merges with the settings in default
  // used with "embark run livenet"
  livenet: {
  },

  // you can name an environment with specific settings and then specify with
  // "embark run custom_name" or "embark blockchain custom_name"
  //custom_name: {
  //}
};
