pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol"; 
import "openzeppelin-solidity/contracts/drafts/ERC20Snapshot.sol";

contract PictosisToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped, ERC20Snapshot {
    constructor()
        ERC20Capped(125000000000000000000000000)
        ERC20Mintable()
        ERC20Detailed("Pictosis Token", "PICTO", 18)
        ERC20()
        public
    {
    }

}
