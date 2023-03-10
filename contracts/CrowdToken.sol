// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CrowdToken is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // function to initialize contract
    function initialize(address _vendorAddress) initializer public {
        __ERC20_init("CrowdToken", "CTK");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(_vendorAddress, 10000000 * 10 ** decimals());
    }
    // function to pause contract
    function pause() public onlyOwner {
        _pause();
    }
    // function to unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }
    // function to transfer token
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    // function to upgrade contract
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}