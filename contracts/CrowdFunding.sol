// SPDX-License-Identifier: MIT



pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./ICrowdToken.sol";


contract CrowdFunding is UUPSUpgradeable, PausableUpgradeable {
 /// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
        _disableInitializers();
    }
// function to initialize contract
     function initialize(address _tokenAddress) initializer public {
       __Pausable_init();
        __UUPSUpgradeable_init();
            owner = msg.sender;
             crowdToken = ICrowdToken(_tokenAddress);
            
    }
   
  // state variable for appeals

    mapping(uint256 => Appeal) public appeals;

    // state variable for appeal count
    uint256 public appealCount;

    // state variable for donation count
    uint256 public donationId;

    // state variable for owner
    address public owner;

    //  state variable for token
     ICrowdToken public crowdToken;

    // state variable for token address
     mapping(uint256 => Donor) public donors;

    // modifier for only owner
    modifier onlyOwner {
        require(msg.sender == owner, "only owner can call function");
        _;
    }
  

// struct for appeal
  struct Appeal {
    uint256 id;
    string name;
    string description;
    uint256 targetAmount;
    uint256 raisedAmount;
    uint256 deadline;
    address payable beneficiary;
    bool completed;
  }
  
    // struct for donor
struct Donor{
        uint256 id;
        address name;
        uint256 amount;
        uint256 appealId;
    }
// event for appeal created
    event AppealCreated(
        uint256 id,
        string name,
        string description,
        uint256 targetAmount,
        uint256 raisedAmount,
        uint256 deadline,
        address payable beneficiary,
        bool completed
    );

// event for appeal completed
    event AppealCompleted(uint256 id, string name, bool completed);


// event for donation received
    event DonationReceived(
        uint256 id,
        address name,
        uint256 amount,
        uint256 appealId
    );

// function to create appeal
    function createAppeal(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint256 _deadline
    ) public {
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_targetAmount > 0, "Target amount is required");
        require(_deadline > 0, "Deadline is required");

        appealCount++;
        appeals[appealCount] = Appeal(
            appealCount,
            _name,
            _description,
            _targetAmount,
            0,
            block.timestamp + _deadline,
            payable(msg.sender),
            false
        );

        emit AppealCreated(
            appealCount,
            _name,
            _description,
            _targetAmount,
            0,
            block.timestamp + _deadline,
            payable(msg.sender),
            false
        );
    }
    
    // function to donate
function donate(uint256 _id, uint256 _amount) public  {
        require(_amount > 0, "Amount is required");
        require(appeals[_id].beneficiary != msg.sender, "Beneficiary cannot donate");
        require(_id > 0 && _id <= appealCount, "Invalid appeal id");
        require(appeals[_id].deadline > block.timestamp, "Deadline has passed");
        require(appeals[_id].completed == false, "Appeal is completed");
        require(crowdToken.balanceOf(msg.sender) > 0, "Insufficient balance");
        
        crowdToken.transferFrom(msg.sender, address(this), _amount);
        donationId++;
        appeals[_id].raisedAmount += _amount;
        donors[donationId] = Donor(
            donationId,
            msg.sender,
            _amount,
            _id
        );

        emit DonationReceived(
            donationId,
            msg.sender,
            _amount,
            _id
        );
}
        // function to end appeal
        function endAppeal(uint256 _id) public {
            require(appeals[_id].deadline < block.timestamp, "Deadline has not passed");
            require(appeals[_id].completed == false, "Appeal is completed");
            require(appeals[_id].beneficiary == msg.sender || owner == msg.sender,  "Only beneficiary can end appeal");
            require(_id > 0 && _id <= appealCount, "Invalid appeal id");
            
    
            appeals[_id].completed = true;

            if (appeals[_id].raisedAmount < appeals[_id].targetAmount) {
                _refundDonors(_id);
            } else {
                crowdToken.transfer(appeals[_id].beneficiary, appeals[_id].raisedAmount);
            }


    
            emit AppealCompleted(_id, appeals[_id].name, true);
        }
    
    // function to get appeals
        function getAppeals() public view returns (Appeal[] memory) {
            Appeal[] memory _appeals = new Appeal[](appealCount);
            for (uint256 i = 1; i <= appealCount; i++) {
                _appeals[i - 1] = appeals[i];
            }
            return _appeals;
        }
    

    // function to get donors
        function getDonors() public view returns (Donor[] memory) {
            Donor[] memory _donors = new Donor[](donationId);
            for (uint256 i = 1; i <= donationId; i++) {
                _donors[i - 1] = donors[i];
            }
            return _donors;
        }

// function to refund donors
        function _refundDonors(uint256 _id) internal {
            
    
            for (uint256 i = 1; i <= donationId; i++) {
                if (donors[i].appealId == _id) {
                    
               crowdToken.transfer(donors[i].name,donors[i].amount);
                }
            }
        }

// function to pause contract
        function pause() public onlyOwner {
            _pause();
        }

// function to unpause contract
        function unpause() public onlyOwner {
            _unpause();
        }


 function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}