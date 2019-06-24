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

    uint public maxSupplyCap;
    uint public maxContribETH;

    address payable public teamMultisig;

    constructor (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address payable _wallet,
        ERC20Mintable _token,
        uint _maxSupplyCap,
        uint _maxContribETH
    )
        public
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_maxSupplyCap)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        teamMultisig = _wallet;
        maxSupplyCap = _maxSupplyCap;
        maxContribETH = _maxContribETH;
    }

    function _finalization() internal {
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

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(_contributions[beneficiary].add(weiAmount) <= maxContribETH, "Max allowed is 100 ETH");
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

    /// @notice This method can be used by the minter to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0x0000...0000 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        emit ClaimedTokens(_token, msg.sender, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
}
