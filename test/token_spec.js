// /*global contract, config, it, assert*/
const testUtils = require('../utils/testUtils');
const PictosisToken = require('Embark/contracts/PictosisToken');
const TestContract = require('Embark/contracts/TestContract');

let accounts;
let newMinter;

config({
  contracts: {
    PictosisToken: {
      args: [ Math.round((new Date).getTime() / 1000 + 5000), '1000000000000000000000000000' ]        
    },
    "TestContract": {}
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts;
  newMinter = accounts[3];
});

contract("PictosisToken", () => {
  before(async () => {
    await PictosisToken.methods.mint(accounts[1], "1000").send();
  })

  it("cannot transfer tokens before start date", async function () {
    try {
      await PictosisToken.methods.transfer(accounts[2], "100").send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Transfers disabled");
    }

    await PictosisToken.methods.approve(accounts[0], "100").send({from: accounts[1]});

    try {
      await PictosisToken.methods.transferFrom(accounts[1], accounts[2], "100").send({from: accounts[0]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Transfers disabled");
    }

    try {
      await PictosisToken.methods.approveAndCall(TestContract.options.address, "100", "0xABCDEF").send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Transfers disabled");
    }
  });

  it("can transfer tokens after start date", async function() {

    await testUtils.increaseTime(20000);

    await PictosisToken.methods.transfer(accounts[2], "100").send({from: accounts[1]});

    await PictosisToken.methods.transferFrom(accounts[1], accounts[2], "100").send({from: accounts[0]});
  });

  it("supports approveAndCall", async () => {
    await PictosisToken.methods.approveAndCall(TestContract.options.address, "100", "0xABCDEF").send({from: accounts[1]});
    
    const balance = await PictosisToken.methods.balanceOf(TestContract.options.address).call();
    
    assert.strictEqual(balance, "100");
  });

  it("only owner can remove minter", async () => {
    await PictosisToken.methods.addMinter(newMinter).send({from: accounts[0]});

    try {
      await PictosisToken.methods.removeMinter(newMinter).send({from: accounts[1]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }

    await PictosisToken.methods.removeMinter(newMinter).send({from: accounts[0]});
  });

});
