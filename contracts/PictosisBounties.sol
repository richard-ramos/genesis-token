pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 
import "openzeppelin-solidity/contracts/math/SafeMath.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";

interface IMinterRole {
    function renounceMinter() external;
}

contract PictosisBounties is Ownable {
    using SafeMath for uint256;

    address public genesis;
    uint public cap;
    uint public minted;
    address payable public controller;

    constructor(address _genesis, uint _cap) public {
        genesis = _genesis;
        cap = _cap;
    }

    /// @notice Mint tokens (can only be called by a minter address)
    /// @param _account Address to mint tokens
    /// @param _value Amount in token equivalents to mint
    function mint(address _account, uint256 _value) public {
      require(msg.sender == controller, "Only controller can call this function");
      uint currentlyMinted = minted;
      minted = currentlyMinted.add(_value);
      require(minted <= cap, "Exceeds cap");
      ERC20Mintable(address(genesis)).mint(_account, _value);
      emit Mint(_account, _value);
    }

    event Mint(address account, uint256 value);

    /// @notice Returns account balance (fwds to token)
    /// @param _account Address to check balance
    /// @return balance
    function balanceOf(address _account) public view returns(uint) {
      return ERC20(address(genesis)).balanceOf(_account);
    }

    /// @notice Change contract controller
    /// @param _newController address that will control the contract
    function setController(address payable _newController) public onlyOwner {
      emit NewControllerSet(controller, _newController);
      controller = _newController;
    }

    event NewControllerSet(address oldController, address newController);

    /// @notice Renounce to minting privilege
    function revokeMintingRole() public onlyOwner {
      IMinterRole(address(genesis)).renounceMinter();
      emit MintingPrivilegeRevoked();
    }

    event MintingPrivilegeRevoked();

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