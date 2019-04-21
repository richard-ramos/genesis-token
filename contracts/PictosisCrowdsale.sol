// TODO: Token debe poderse transferir al finalizar crowdsale?

pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 


contract PictosisCrowdsale is CappedCrowdsale, MintedCrowdsale, TimedCrowdsale, Ownable {
    address presaleAddress;
    uint presaleSold = 0;
    bool presaleActive = false;
    
    uint presaleCap   = 125000000000000000000000000;
    uint maxSupplyCap = 650000000000000000000000000;

    constructor (
        uint256 openingTime,
        uint256 closingTime,
        uint256 rate,
        address payable wallet,
        ERC20Mintable token
    )
        public
        Crowdsale(rate, wallet, token)
        CappedCrowdsale(maxSupplyCap)
        TimedCrowdsale(openingTime, closingTime)
    {
    }

    event PresaleAddressSet(address presaleAddress);

    /// @notice Set presale address
    /// @param _presaleAddress address that will mint tokens
    function setPresaleAddress(address _presaleAddress) public onlyOwner {
        require(presaleAddress == address(0), "Presale address has been set already");

        presaleAddress = _presaleAddress;
        emit PresaleAddressSet(presaleAddress);
    }

    event PresaleStarted(uint blockNumber);

    /// @notice Enable presale period
    function startPresale() public onlyOwner {
        require(presaleAddress != address(0), "Presale address hasn't been set");
        require(presaleActive == false, "Presale is already active");
        require(presaleSold == 0, "Presale has already happened");
        
        presaleActive = true;
        emit PresaleStarted(block.number);
    }
    
    /// @notice Mint tokens (can only be called by the presale address)
    /// @param _account Address to mint tokens
    /// @param _value Amount in token equivalents to mint
    function mintPresaleToken(address _account, uint256 _value) public {
        require(presaleActive == true, "Presale is not active");
        require(msg.sender == presaleAddress, "Only presaleaddress can call this function");

        uint currentlySold = presaleSold;
        presaleSold = currentlySold + _value;

        require(presaleSold >= currentlySold, "Math error");
        require(presaleSold <= presaleCap, "Exceeds presale cap");

        ERC20Mintable(address(token())).mint(_account, _value);
    }

    event PresaleFinished(uint amountNotSold, uint blockNumber);

    /// @notice Finish presale period
    function finishPresale() public onlyOwner {
        require(presaleActive == true, "Presale is not active");

        // TODO: check presale ended?
        presaleActive = false;
        emit PresaleFinished(presaleSold, block.number);
    }
    
}
