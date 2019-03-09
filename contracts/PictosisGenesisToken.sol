pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol"; 

contract PictosisGenesisToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped {
    address public swapContract;

    constructor()
        ERC20Capped(125000000000000000000000000000)
        ERC20Mintable()
        ERC20Detailed("Pictosis Genesis Token", "PICTO-G", 18)
        ERC20()
        public
    {
    }

    function burnFrom(address from, uint256 value) public onlyMinter {
        _burnFrom(from, value);
    }

    function setSwapContract(address _swapContract) public onlyMinter {
        swapContract = _swapContract;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        revert("Token can only be exchanged for PICTO tokens in the swap contract");
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
}
