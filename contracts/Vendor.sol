// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./ICrowdToken.sol";

contract Vendor is UUPSUpgradeable, PausableUpgradeable{
/// @custom:oz-upgrades-unsafe-allow constructor
     constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
       __Pausable_init();
        __UUPSUpgradeable_init();
            owner = msg.sender;
            tokenPrice = 0.1 ether;
    }

    address public owner;

     /** @notice state variable for tokens */
    ICrowdToken public crowdToken;

    uint public tokenPrice;

    address public tokenAddress;

    modifier onlyOwner {
        require(msg.sender == owner, "only owner can call function");
        _;
    }

    modifier tokenAddressNotEmpty{
        require(tokenAddress != address(0),"token empty");
        _;
    }
    function setTokenAddress(address _tokenAddress) public onlyOwner{

        tokenAddress = _tokenAddress;

        crowdToken = ICrowdToken(_tokenAddress);
    }
    function buyToken() tokenAddressNotEmpty payable public {
        require(msg.value > 0, "invalid amount");
        uint amount = msg.value * 10 ** 4;
        
        crowdToken.transfer(msg.sender, amount);
       
    }

 function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        
        address _owner = msg.sender;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
      }
     // Function to receive Ether. msg.data must be empty
      receive() external payable {}

      // Fallback function is called when msg.data is not empty
      fallback() external payable {}

      function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}


}