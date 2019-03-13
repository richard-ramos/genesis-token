pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol"; 
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 
import "openzeppelin-solidity/contracts/math/SafeMath.sol"; 

import "./PictosisGenesisToken.sol";

contract PictosisGenesisExchanger is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public collected;
    uint256 public totalCollected;

    PictosisGenesisToken public genesis;
    IERC20 public picto;
    
    constructor(address _genesis, address _picto) public {
        genesis = PictosisGenesisToken(_genesis);
        picto = IERC20(_picto);
    }

    /// @notice This method should be called by the genesis holders to collect their picto token
    function collect() public {
        uint256 balance = genesis.balanceOf(msg.sender);
        
        require(balance > 0, "You do not have tokens to exchange");
        require(genesis.allowance(msg.sender, address(this)) == balance, "You must approve the full balance to collect your tokens");
        require(picto.balanceOf(address(this)) >= balance, "Exchanger does not have funds available");
        
        genesis.completeExchange(msg.sender);

        totalCollected = totalCollected.add(balance);
        collected[msg.sender] = collected[msg.sender].add(balance);

        require(picto.transfer(msg.sender, balance), "Transfer failure");

        emit TokensCollected(msg.sender, balance);
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

        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        emit ClaimedTokens(_token, msg.sender, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensCollected(address indexed _holder, uint256 _amount);
}