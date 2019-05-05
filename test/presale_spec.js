// /*global contract, config, it, assert*/
const testUtils = require('../utils/testUtils');
const PictosisToken = require('Embark/contracts/PictosisToken');
const PictosisCrowdsale = require('Embark/contracts/PictosisCrowdsale');

let accounts;

config({
  contracts: {
    PictosisToken: {
      args: [ Math.round((new Date).getTime() / 1000 + 10000) ]        
    },
    PictosisCrowdsale: {
      args: [ parseInt((new Date()).getTime() / 1000, 10) + 1000, parseInt((new Date()).getTime() / 1000, 10) + 2000, '1500', "$accounts[0]", "$PictosisToken"  ],
      onDeploy: ['PictosisToken.methods.addMinter("$PictosisCrowdsale").send()']
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts
});

contract("PictosisToken", () => {
  it("should not be able to buy tokens", async () => {
    try {
      await web3.eth.sendTransaction({from: accounts[1], to: PictosisCrowdsale.options.address, value: web3.utils.toWei("1", "ether")});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }

    try {
      await PictosisCrowdsale.methods.buyTokens(accounts[1]).send({from: accounts[1], value: web3.utils.toWei("1", "ether")});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert");
    }
  });

  it("cannot start presale without setting the address", async () => {
    try {
      await PictosisCrowdsale.methods.startPresale().send();
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale address hasn't been set");
    }
  });

  it("should set correctly the presale calling address", async () => {
    const receipt = await PictosisCrowdsale.methods.setPresaleAddress(accounts[3]).send();
    assert(!!receipt.events.PresaleAddressSet, "PresaleAddressSet() not triggered");
    
    const presaleAddress = await PictosisCrowdsale.methods.presaleAddress().call();
    assert.strictEqual(presaleAddress, accounts[3]);
  });

  it("cannot set presale calling address twice", async () => {
    try {
      await PictosisCrowdsale.methods.setPresaleAddress(accounts[4]).send();
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale address has been set already");
    }
  });

  it("should not be able to mint presale tokens before presale starts", async () => {
    try {
      await PictosisCrowdsale.methods.mint(accounts[9], "1000").send({from: accounts[3]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale is not active");
    }
  });

  it("cannot finish an unstarted presale", async () => {
    try {
      await PictosisCrowdsale.methods.finishPresale().send();
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale is not active");
    }
  });

  it("can start presale", async () => {
    const receipt = await PictosisCrowdsale.methods.startPresale().send();
    assert(!!receipt.events.PresaleStarted, "PresaleStarted() not triggered");

    const presaleStarted = await PictosisCrowdsale.methods.presaleActive().call();
    assert.strictEqual(presaleStarted, true);
  });

  it("cannot start presale twice", async () => {
    try {
      const receipt = await PictosisCrowdsale.methods.startPresale().send();
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale is already active");
    }
  });

  it("only presale address should be able to mint tokens", async () => {
    await PictosisCrowdsale.methods.mint(accounts[9], "1000").send({from: accounts[3]});

    try {
      await PictosisCrowdsale.methods.mint(accounts[9], "1000").send({from: accounts[0]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Only presale address can call this function");
    }
  });

  it("can mint tokens", async () => {
    const startSupply = await PictosisToken.methods.totalSupply().call();
    const amountToMint = "3000";

    await PictosisCrowdsale.methods.mint(accounts[8], amountToMint).send({from: accounts[3]});

    const endSupply = await PictosisToken.methods.totalSupply().call();

    assert.strictEqual(parseInt(endSupply), parseInt(startSupply) + parseInt(amountToMint));
  });

  it("cannot exceed the hard cap", async () => {
    const presaleCap = await PictosisCrowdsale.methods.presaleCap().call();
    const currentSupply = await PictosisToken.methods.totalSupply().call();
    const amountToMint = web3.utils.toBN(presaleCap).sub(web3.utils.toBN(currentSupply));

    await PictosisCrowdsale.methods.mint(accounts[8], amountToMint.toString()).send({from: accounts[3]});

    const endSupply = await PictosisToken.methods.totalSupply().call();
    assert.strictEqual(endSupply, presaleCap);

    try {
      await PictosisCrowdsale.methods.mint(accounts[9], "1").send({from: accounts[3]});
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Exceeds presale cap");
    }
  });

  it("can finish presale", async () => {
    const receipt = await PictosisCrowdsale.methods.finishPresale().send();
    assert(!!receipt.events.PresaleFinished, "PresaleFinished() not triggered");

    const presaleActive = await PictosisCrowdsale.methods.presaleActive().call();
    const presaleFinished = await PictosisCrowdsale.methods.presaleFinished().call();

    assert.strictEqual(presaleActive, false);
    assert.strictEqual(presaleFinished, true);
  });

  it("can't finish presale twice", async () => {
    try {
      const receipt = await PictosisCrowdsale.methods.finishPresale().send();
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale already finished");
    }
  });

  it("can't start a finished presale", async () => {
    try {
      const receipt = await PictosisCrowdsale.methods.startPresale().send();
      assert.fail('should have reverted');
    } catch (error) {
      assert.strictEqual(error.message, "VM Exception while processing transaction: revert Presale already finished");
    }
  });

});
