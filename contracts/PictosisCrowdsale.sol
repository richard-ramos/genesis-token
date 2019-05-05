pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 

interface IMinterRole {
    function renounceMinter() external;
}

contract PictosisCrowdsale is CappedCrowdsale, MintedCrowdsale, TimedCrowdsale, FinalizableCrowdsale, Ownable {
    address presaleAddress;
    uint presaleSold = 0;
    bool presaleActive = false;
    
    uint presaleCap   = 125000000000000000000000000;
    uint maxSupplyCap = 650000000000000000000000000;
    
    address payable private teamMultisig;
    
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
        teamMultisig = wallet;
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
    function mint(address _account, uint256 _value) public {
        require(presaleActive == true, "Presale is not active");
        require(msg.sender == presaleAddress, "Only presale address can call this function");

        uint currentlySold = presaleSold;
        presaleSold = currentlySold.add(_value);

        require(presaleSold <= presaleCap, "Exceeds presale cap");

        ERC20Mintable(address(token())).mint(_account, _value);
    }

    event PresaleFinished(uint amountNotSold, uint blockNumber);

    /// @notice Finish presale period
    function finishPresale() public onlyOwner {
        require(presaleActive == true, "Presale is not active");
        require(presaleAddress != address(0), "Presale address hasn't been set");

        presaleActive = false;
        emit PresaleFinished(presaleSold, block.number);
    }

    function finalization() internal {
        ERC20Capped tkn = ERC20Capped(address(token()));
        uint unmintedTokens = tkn.cap().sub(tkn.totalSupply());
        ERC20Mintable(address(token())).mint(teamMultisig, unmintedTokens);
        IMinterRole(address(token())).renounceMinter();
        super._finalization();
    }

    mapping(address => uint256) private _contributions;

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    uint public constant MAX_CONTRIB_ETH = 100 ether;

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(_contributions[beneficiary].add(weiAmount) <= MAX_CONTRIB_ETH, "Max allowed is 100 ETH");
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }
}
