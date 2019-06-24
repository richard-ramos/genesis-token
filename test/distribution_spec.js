// /*global contract, config, it, assert*/
const testUtils = require('../utils/testUtils');
const PictosisToken = require('Embark/contracts/PictosisToken');
const PictosisGenesisToken = require('Embark/contracts/PictosisGenesisToken');
const PictosisGenesisExchanger = require('Embark/contracts/PictosisGenesisExchanger');
const PictosisCrowdsale = require('Embark/contracts/PictosisCrowdsale');

let accounts;
let presaleAccount;
let presaleBuyer;
let whale;
let normalBuyer;


config({
  contracts: {
    PictosisToken: {
      args: [ Math.round((new Date).getTime() / 1000 + 10000), '1000000000000000000000000000' ]
    },
    PictosisGenesisToken: {},
    PictosisGenesisExchanger: {
      args: ["$PictosisGenesisToken", "$PictosisToken"],
      onDeploy: ['PictosisGenesisToken.methods.setExchangeContract("$PictosisGenesisExchanger").send()']
    },
    PictosisCrowdsale: {
      args: [ 
        parseInt((new Date()).getTime() / 1000, 10) + 100, 
        parseInt((new Date()).getTime() / 1000, 10) + 5000, 
        '2500', 
        "$accounts[0]", 
        "$PictosisToken",
        '625000000000000000000000000', // 500MM
        '100000000000000000000' // 100 eth
      ],
      onDeploy: [
        'PictosisToken.methods.addMinter("$PictosisCrowdsale").send()',
        'PictosisToken.methods.mint("$PictosisGenesisExchanger", "125000000000000000000000000").send()'
      ]
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts;

  teamMultisig = accounts[0];
  whale = accounts[3];
  normalBuyer = accounts[4];
});



contract("PictosisCrowdsale - Distribution", () => {
  before(async () => {
    // Mint Genesis Tokens
    await PictosisGenesisToken.methods.mint(whale, "125000000000000000000000000").send();

    // TODO: preguntar si se van a repartir todos los genesis tokens antes del crowdsale
    // SI es asi, hacer deploy de exchanger y tokens al crear el picto token

    await testUtils.increaseTime(500);

    // Crowdsale 
    await web3.eth.sendTransaction({from: whale, to: PictosisCrowdsale.options.address, value: web3.utils.toWei('50', 'ether'), gas: "300000"});

    await testUtils.increaseTime(10000);

    await PictosisCrowdsale.methods.finalize().send();
  });
  
  it("distribution should be correct", async () => {
    const totalSupply = await PictosisToken.methods.totalSupply().call();
    assert(totalSupply, "100000000000000000000000000");

    const exchangerBalance = await PictosisToken.methods.balanceOf(PictosisGenesisExchanger.options.address).call();
    assert(totalSupply, "125000000000000000000000000");

    const whaleBalance = await PictosisToken.methods.balanceOf(whale).call();
    const teamBalance = await PictosisToken.methods.balanceOf(teamMultisig).call();

    const toBN = web3.utils.toBN;

    assert(toBN(whaleBalance).add(toBN(teamBalance)).add(toBN(exchangerBalance)), toBN(totalSupply))
  });

});



