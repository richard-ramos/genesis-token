// /*global contract, config, it, assert*/
const testUtils = require('../utils/testUtils');
const PictosisToken = require('Embark/contracts/PictosisToken');
const PictosisCrowdsale = require('Embark/contracts/PictosisCrowdsale');

let accounts;
let whale;
let normalBuyer;

config({
  contracts: {
    PictosisToken: {
      args: [ Math.round((new Date).getTime() / 1000 + 10000), '1000000000000000000000000000' ]        
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
      onDeploy: ['PictosisToken.methods.addMinter("$PictosisCrowdsale").send()']
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts;

  teamMultisig = accounts[0];
  whale = accounts[3];
  normalBuyer = accounts[4];
});

const toBN = web3.utils.toBN;

contract("PictosisCrowdsale - ICO", () => {
  before(async () => {
    // Sending ether to whale
    await web3.eth.sendTransaction({from: accounts[1], to: whale, value: web3.utils.toWei('10', 'ether')});

    await testUtils.increaseTime(500);
  });
  
  it("should allow only contributions up to 100 eth", async () => {
    try {
      await web3.eth.sendTransaction({from: whale, to: PictosisCrowdsale.options.address, value: web3.utils.toWei('100.1', 'ether'), gas: "300000"});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Max allowed is 100 ETH");
    }

    await web3.eth.sendTransaction({from: whale, to: PictosisCrowdsale.options.address, value: web3.utils.toWei('99', 'ether'), gas: "300000"});
    await web3.eth.sendTransaction({from: whale, to: PictosisCrowdsale.options.address, value: web3.utils.toWei('1', 'ether'), gas: "300000"});

    try {
      await web3.eth.sendTransaction({from: whale, to: PictosisCrowdsale.options.address, value: 1, gas: "300000"});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Max allowed is 100 ETH");
    }

    await web3.eth.sendTransaction({from: normalBuyer, to: PictosisCrowdsale.options.address, value: web3.utils.toWei('1', 'ether'), gas: "300000"});
  });

  it("should finalize crowdsale and mint rest of tokens to wallet", async () => {
    const teamBalanceStart = await PictosisToken.methods.balanceOf(teamMultisig).call();

    await testUtils.increaseTime(10000);

    // Should not allow buying after ICO ends
    try {
      await web3.eth.sendTransaction({from: normalBuyer, to: PictosisCrowdsale.options.address, value: web3.utils.toWei('1', 'ether'), gas: "300000"});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }

    await PictosisCrowdsale.methods.finalize().send();

    const teamBalanceEnd = await PictosisToken.methods.balanceOf(teamMultisig).call();
    const cap = await PictosisToken.methods.cap().call();
    const totalSupply = await PictosisToken.methods.totalSupply().call();

    // Rest of supply should go to multisig
    assert(toBN(teamBalanceStart).add(toBN(cap).sub(toBN(totalSupply))), toBN(teamBalanceEnd));

    const isMinter = await PictosisToken.methods.isMinter(PictosisCrowdsale.options.address).call();

    // Crowdsale is not a minter anymore
    assert.strictEqual(false, isMinter);
  });

});



