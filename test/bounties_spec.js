// /*global contract, config, it, assert*/
const testUtils = require('../utils/testUtils');
const PictosisToken = require('Embark/contracts/PictosisToken');
const PictosisGenesisToken = require('Embark/contracts/PictosisGenesisToken');
const PictosisBounties = require('Embark/contracts/PictosisBounties');

let accounts;
let controller;
let newController;
let owner;

config({
  contracts: {
    PictosisGenesisToken: {
      args: []
    },
    PictosisBounties: {
      args: ["$PictosisGenesisToken", "125000000000000000000000"],
      onDeploy: ['PictosisGenesisToken.methods.addMinter("$PictosisBounties").send()']
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts;
  owner = accounts[0];
  controller = accounts[5];
  newController = accounts[6];
});

contract("PictosisBounties", () => {
  before(async () => {
    await PictosisBounties.methods.setController(controller).send({from: owner});
  });

  it("should fail if random account calls mint", async () => {
    try {
      await PictosisBounties.methods.mint(accounts[9], 10).send({from: accounts[9]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Only controller can call this function");
    }
  });

  it("should allow controller to mint tokens", async () => {
    const startBalance = await PictosisBounties.methods.balanceOf(accounts[9]).call();
    assert.strictEqual(startBalance, "0");

    const receipt = await PictosisBounties.methods.mint(accounts[9], 10).send({from: controller});
    assert(!!receipt.events.Mint, "NewControllerSet() not triggered");
    assert.strictEqual(receipt.events.Mint.returnValues.account, accounts[9]);
    assert.strictEqual(receipt.events.Mint.returnValues.value, '10');

    const endBalance = await PictosisBounties.methods.balanceOf(accounts[9]).call();
    assert.strictEqual(endBalance, "10");
  });

  it("should not let the contract mint more than the specified cap", async () => {
    const minted = web3.utils.toBN(await PictosisBounties.methods.minted().call());
    const cap = web3.utils.toBN(await PictosisBounties.methods.cap().call());

    try {
      await PictosisBounties.methods.mint(accounts[9], cap.sub(minted).add(web3.utils.toBN(1)).toString()).send({from: controller});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Exceeds cap");
    }
  });

  it("only the owner can change the controller", async () => {
    try {
      const receipt = await PictosisBounties.methods.setController(accounts[9]).send({from: accounts[9]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }

    const receipt = await PictosisBounties.methods.setController(newController).send({from: owner});
    assert(!!receipt.events.NewControllerSet, "NewControllerSet() not triggered");

    const contractController = await PictosisBounties.methods.controller().call();
    assert.strictEqual(contractController, newController);
  });

  it("only the owner can revoke the minting privilege", async () => {
    await PictosisBounties.methods.mint(accounts[9], 10).send({from: newController});

    try {
      const receipt = await PictosisBounties.methods.revokeMintingRole().send({from: accounts[9]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }

    const receipt = await PictosisBounties.methods.revokeMintingRole().send({from: owner});
    assert(!!receipt.events.MintingPrivilegeRevoked, "MintingPrivilegeRevoked() not triggered");

    try {
      await PictosisBounties.methods.mint(accounts[9], 10).send({from: newController});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }

  });
  
});
