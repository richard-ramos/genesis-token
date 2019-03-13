pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol"; 

contract PictosisTestToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped {
    constructor()
        ERC20Capped(125000000000000000000000000000)
        ERC20Mintable()
        ERC20Detailed("Pictosis Test Token", "PICTO-T", 18)
        ERC20()
        public
    {
    }

}
