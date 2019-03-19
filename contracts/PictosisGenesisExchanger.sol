pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 
import "openzeppelin-solidity/contracts/math/SafeMath.sol"; 

import "./PictosisGenesisToken.sol";

contract PictosisGenesisExchanger is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public collected;
    uint256 public totalCollected;

    PictosisGenesisToken public genesis;
    ERC20 public picto;
    
    constructor(address _genesis, address _picto) public {
        genesis = PictosisGenesisToken(_genesis);
        picto = ERC20(_picto);
    }

    /// @notice This method should be called by the genesis holders to collect their picto token
    function collect() public {
        uint256 balance = genesis.balanceOf(msg.sender);
        uint256 amount = balance.sub(collected[msg.sender]);

        require(amount > 0, "Tokens already exchanged");
        require(picto.balanceOf(address(this)) >= amount, "Exchanger does not have funds available");

        totalCollected = totalCollected.add(amount);
        collected[msg.sender] = collected[msg.sender].add(amount);

        require(picto.transfer(msg.sender, amount), "Transfer failure");

        genesis.completeExchange(msg.sender);

        emit TokensCollected(msg.sender, amount);
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

        if(_token == address(picto)){
            require(totalCollected >= genesis.totalSupply(), "Cannot withdraw PICTO until everyone exchanges the tokens");
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        emit ClaimedTokens(_token, msg.sender, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensCollected(address indexed _holder, uint256 _amount);
}