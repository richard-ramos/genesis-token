pragma solidity ^0.5.2;

import "./ApproveAndCallFallBack.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
 
contract TestContract is ApproveAndCallFallBack {

    function receiveApproval(
      address from,
      uint256 _amount,
      address _token,
      bytes memory _data)
      public
    {
      require(ERC20(_token).transferFrom(from, address(this), _amount), "Couldnt transfer");
    }
}