pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; 
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol"; 
import "openzeppelin-solidity/contracts/drafts/ERC20Snapshot.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 


contract PictosisToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped, ERC20Snapshot, Ownable {
    constructor()
        ERC20Capped(1000000000000000000000000000)
        ERC20Mintable()
        ERC20Detailed("Pictosis Token", "PICTO", 18)
        ERC20()
        Ownable()
        public
    {
    }
}
