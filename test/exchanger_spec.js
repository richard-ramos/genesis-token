// /*global contract, config, it, assert*/
const testUtils = require('../utils/testUtils');
const PictosisToken = require('Embark/contracts/PictosisToken');
const PictosisGenesisToken = require('Embark/contracts/PictosisGenesisToken');
const PictosisGenesisExchanger = require('Embark/contracts/PictosisGenesisExchanger');

let accounts;

config({
  contracts: {
    PictosisGenesisToken: {
      args: []
    },
    PictosisGenesisExchanger: {
      args: ["$PictosisGenesisToken", "$PictosisToken"]
    },
    PictosisToken: {
      args: [ Math.round((new Date).getTime() / 1000 + 5000), '1000000000000000000000000000' ]        
    },
    "TestContract": {}
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts
});

contract("PictosisToken", () => {
  before(async () => {
    await PictosisGenesisToken.methods.mint(accounts[1], "1000").send();
  })

  it("cannot exchange tokens before transfers are enabled", async () => {
    const canCollect = await PictosisGenesisExchanger.methods.canCollect().call();

    assert.strictEqual(canCollect, false);

    try {
      await PictosisGenesisExchanger.methods.collect().send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Cannot collect tokens yet");
    }
  });

  it("should fail if contract does not have tokens", async () => {
    await testUtils.increaseTime(20000);

    try {
      await PictosisGenesisExchanger.methods.collect().send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Exchanger does not have funds available");
    }
  });

  it("contract should receive token funds", async () => {
    const genesisSupply = await PictosisGenesisToken.methods.cap().call();

    const receipt = await PictosisToken.methods.mint(PictosisGenesisExchanger.options.address, genesisSupply).send();

    const contractBalance = await PictosisToken.methods.balanceOf(PictosisGenesisExchanger.options.address).call();

    assert.strictEqual(genesisSupply, contractBalance);
  });

  it("account with no genesis tokens should not receive tokens", async () => {
    let initialBalance = await PictosisToken.methods.balanceOf(accounts[2]).call();
    assert.strictEqual(initialBalance, '0');

    try {
      await PictosisGenesisExchanger.methods.collect().send({from: accounts[2]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert No tokens available or already exchanged");
    }
  });

  it("genesis holder should receive tokens", async () => {
    const accountStartBalance = await PictosisToken.methods.balanceOf(accounts[1]).call();
    const genesisStartBalance = await PictosisGenesisToken.methods.balanceOf(accounts[1]).call();

    assert.strictEqual(accountStartBalance, '0');
    assert.strictEqual(genesisStartBalance, '1000');

    PictosisGenesisToken.methods.approve(PictosisGenesisExchanger.options.address, '1000').send({from: accounts[1]});

    const receipt = await PictosisGenesisExchanger.methods.collect().send({from: accounts[1]});
    
    assert(!!receipt.events.TokensCollected, "TokensCollected() not triggered");

    const accountEndingBalance = await PictosisToken.methods.balanceOf(accounts[1]).call();
    
    assert.strictEqual(accountEndingBalance, '1000');
  });

  it("genesis holder should not receive tokens twice", async () => {
    PictosisGenesisToken.methods.approve(PictosisGenesisExchanger.options.address, '1000').send({from: accounts[1]});

    try {
      await PictosisGenesisExchanger.methods.collect().send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert No tokens available or already exchanged");
    }
  });

  it("can exchange for picto if more genesis tokens are allocated", async () => {
    await PictosisGenesisToken.methods.mint(accounts[1], "200").send();

    const accountStartBalance = await PictosisToken.methods.balanceOf(accounts[1]).call();
    const genesisBalance = await PictosisGenesisToken.methods.balanceOf(accounts[1]).call();

    assert.strictEqual(accountStartBalance, '1000');
    assert.strictEqual(genesisBalance, '1200');

    await PictosisGenesisExchanger.methods.collect().send({from: accounts[1]});
    
    const accountEndingBalance = await PictosisToken.methods.balanceOf(accounts[1]).call();
    
    assert.strictEqual(accountEndingBalance, '1200');

    try {
      await PictosisGenesisExchanger.methods.collect().send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert No tokens available or already exchanged");
    }
  });


  it("extract only the amounts greater than the totalSupply", async() => {
    const initialContractBalance = await PictosisToken.methods.balanceOf(PictosisGenesisExchanger.options.address).call();

    await PictosisGenesisExchanger.methods.claimTokens(PictosisToken.options.address).send();

    const contractBalance = await PictosisToken.methods.balanceOf(PictosisGenesisExchanger.options.address).call();
    const genesisSupply = await PictosisGenesisToken.methods.totalSupply().call();

    assert.strictEqual(contractBalance, genesisSupply);
    
    const accountBalance = await PictosisToken.methods.balanceOf(accounts[0]).call();

    assert.strictEqual(web3.utils.toBN(accountBalance).add(web3.utils.toBN(contractBalance)).toString(), initialContractBalance);
  });
  
});
