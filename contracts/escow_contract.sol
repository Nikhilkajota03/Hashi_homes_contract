// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract HashiHomes is ERC721URIStorage {

    IERC20 public token;

    struct Property {
        string name;
        uint256 totalShares;
        uint256 pricePerShare;
        address[] owners;
        mapping(address => uint256) shares;
        bool isFullyPurchased;
        bool availableForRent;
        uint256 nftId;
        uint256 rentAmount;
    }

    struct Rental {
        uint256 propertyId;
        address tenant;
        uint256 rentAmount;
        uint256 startDate;
        uint256 endDate;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => Rental) public rentals;
    uint256 public propertyCount;
    uint256 public rentalCount;

    address public owner;

    constructor(IERC20 _token) ERC721("HashiHomes", "HSHM") {
        owner = msg.sender;
        token = _token;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function addProperty(
        string memory _name,
        uint256 _totalShares,
        uint256 _pricePerShare,
        string memory _nftURI
    ) public onlyOwner {
        require(_totalShares > 0, "Total shares must be greater than zero");
        propertyCount++;

        uint256 nftId = propertyCount;
        _mint(msg.sender, nftId);
        _setTokenURI(nftId, _nftURI);

        Property storage newProperty = properties[propertyCount];
        newProperty.name = _name;
        newProperty.totalShares = _totalShares;
        newProperty.pricePerShare = _pricePerShare;
        newProperty.isFullyPurchased = false;
        newProperty.availableForRent = false;
        newProperty.nftId = nftId;
    }

    function buyShares(uint256 propertyId, uint256 shares) public {
        Property storage property = properties[propertyId];
        require(property.totalShares > 0, "Property does not exist");
        require(!property.isFullyPurchased, "Property is already fully purchased");
        require(shares > 0, "Cannot buy 0 shares");

        uint256 cost = shares * property.pricePerShare;
        require(token.transferFrom(msg.sender, address(this), cost), "Token transfer failed");
        require(property.shares[msg.sender] + shares <= property.totalShares, "Not enough shares available");

        if (property.shares[msg.sender] == 0) {
            property.owners.push(msg.sender);
        }
        property.shares[msg.sender] += shares;

        uint256 totalSoldShares = 0;
        for (uint256 i = 0; i < property.owners.length; i++) {
            totalSoldShares += property.shares[property.owners[i]];
        }

        if (totalSoldShares == property.totalShares) {
            property.isFullyPurchased = true;
            property.availableForRent = true;
        }
    }

    function rentProperty(uint256 propertyId, uint256 rentAmount, uint256 startDate, uint256 endDate) public {
        Property storage property = properties[propertyId];
        require(property.availableForRent, "Property is not available for rent");
        require(token.transferFrom(msg.sender, address(this), rentAmount), "Token transfer failed");

        rentalCount++;
        rentals[rentalCount] = Rental({
            propertyId: propertyId,
            tenant: msg.sender,
            rentAmount: rentAmount,
            startDate: startDate,
            endDate: endDate
        });
    }

    function distributeRent(uint256 propertyId) public {
        Property storage property = properties[propertyId];
        require(property.availableForRent, "Property is not in rental phase");

        uint256 totalRent = token.balanceOf(address(this));

        for (uint256 i = 0; i < property.owners.length; i++) {
            address propertyOwner = property.owners[i];
            uint256 ownerShare = (property.shares[propertyOwner] * totalRent) / property.totalShares;
            require(token.transfer(propertyOwner, ownerShare), "Token transfer to owner failed");
        }
    }

    function getShares(uint256 propertyId, address ownerAddress) public view returns (uint256) {
        return properties[propertyId].shares[ownerAddress];
    }

    function getOwners(uint256 propertyId) public view returns (address[] memory) {
        return properties[propertyId].owners;
    }

    function withdrawTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Token transfer failed");
    }
}
