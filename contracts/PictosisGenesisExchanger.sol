pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol"; 
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; 
import "openzeppelin-solidity/contracts/math/SafeMath.sol"; 

import "./PictosisGenesisToken.sol";
import "./PictosisToken.sol";

contract PictosisGenesisExchanger is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public collected;
    uint256 public totalCollected;

    PictosisGenesisToken public genesis;
    PictosisToken public picto;
    
    constructor(address _genesis, address _picto) public {
        genesis = PictosisGenesisToken(_genesis);
        picto = PictosisToken(_picto);
    }

    /// @notice Can collect tokens;
    function canCollect() public view returns(bool) {
        return picto.areTransfersEnabled();
    }

    /// @notice This method should be called by the genesis holders to collect their picto token. Requires approval
    function collect() public {
        require(picto.areTransfersEnabled(), "Cannot collect tokens yet");

        uint balance = genesis.balanceOf(msg.sender);
        uint256 amountToSend = balance.sub(collected[msg.sender]);

        require(balance >= collected[msg.sender], "Balance must be greater than collected amount");
        require(amountToSend > 0, "No tokens available or already exchanged");
        require(picto.balanceOf(address(this)) >= amountToSend, "Exchanger does not have funds available");

        totalCollected = totalCollected.add(amountToSend);
        collected[msg.sender] = collected[msg.sender].add(amountToSend);

        require(picto.transfer(msg.sender, amountToSend), "Transfer failure");

        emit TokensCollected(msg.sender, amountToSend);
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

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));

        if(_token == address(picto)){
            if(balance > genesis.totalSupply()){
                balance = balance.sub(genesis.totalSupply());
            }
            require(balance >= genesis.totalSupply(), "Cannot withdraw PICTO until everyone exchanges the tokens");
        }

        token.transfer(msg.sender, balance);
        emit ClaimedTokens(_token, msg.sender, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensCollected(address indexed _holder, uint256 _amount);
}