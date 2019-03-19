pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol"; 

contract PictosisGenesisToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped {
    address public exchangeContract;

    constructor()
        ERC20Capped(125000000000000000000000000)
        ERC20Mintable()
        ERC20Detailed("Pictosis Genesis Token", "PICTO-G", 18)
        ERC20()
        public
    {
    }

    function burnFrom(address from, uint256 value) public onlyMinter {
        _burnFrom(from, value);
    }

    function setExchangeContract(address _exchangeContract) public onlyMinter {
        exchangeContract = _exchangeContract;
    }

    function completeExchange(address from) public {
        require(msg.sender == exchangeContract && exchangeContract != address(0), "Only the exchange contract can invoke this function");
        _burnFrom(from, balanceOf(from));
    }

    function transfer(address to, uint256 value) public returns (bool) {
        revert("Token can only be exchanged for PICTO tokens in the exchange contract");
    }

    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;

    // data is an array of uint256s. Each uint256 represents a transfer.
    // The 160 LSB is the destination of the address that wants to be sent
    // The 96 MSB is the amount of tokens that wants to be sent.
    // i.e. assume we want to mint 1200 tokens for address 0xABCDEFAABBCCDDEEFF1122334455667788990011
    // 1200 in hex: 0x0000410d586a20a4c00000. Concatenate this value and the address
    // ["0x0000410d586a20a4c00000ABCDEFAABBCCDDEEFF1122334455667788990011"]
    function multiMint(uint256[] memory data) public onlyMinter {
        for (uint256 i = 0; i < data.length; i++) {
            address addr = address(data[i] & (D160 - 1));
            uint256 amount = data[i] / D160;
            _mint(addr, amount);
        }
    }

    /// @notice This method can be used by the minter to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0x0000...0000 in case you want to extract ether.
    function claimTokens(address _token) public onlyMinter {
        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        emit ClaimedTokens(_token, msg.sender, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _sender, uint256 _amount);

}
