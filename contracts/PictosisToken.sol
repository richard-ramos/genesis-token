pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/drafts/ERC20Snapshot.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ApproveAndCallFallBack.sol";

contract PictosisToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped, ERC20Snapshot, Ownable {
    uint transfersEnabledDate;

    modifier onlyTransfersEnabled() {
        require(block.timestamp >= transfersEnabledDate, "Transfers disabled");
        _;
    }

    constructor(uint _enableTransfersDate, uint _cap)
        ERC20Capped(_cap)
        ERC20Mintable()
        ERC20Detailed("Pictosis Token", "PICTO", 18)
        ERC20()
        Ownable()
        public
    {
        transfersEnabledDate = _enableTransfersDate;
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function areTransfersEnabled() public view returns(bool) {
        return block.timestamp >= transfersEnabledDate;
    }

    function transfer(
            address to,
            uint256 value
        )
        public
        onlyTransfersEnabled
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
            address from,
            address to,
            uint256 value
        )
        public
        onlyTransfersEnabled
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(
            address _spender,
            uint256 _amount,
            bytes memory _extraData
        )
        public
        returns (bool success)
    {
        require(approve(_spender, _amount), "Couldn't approve spender");

        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, address(this), _extraData);

        return true;
    }
}