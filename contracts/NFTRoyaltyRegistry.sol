// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

interface IRegisteredNFT { function ownerOf(uint256 tokenId) external view returns(address); }
contract NFTRoyaltyRegistry is ReentrancyGuard, Ownable {
    struct Royalty {
        address nftContract;
        uint256 tokenId;
        address creator;
        uint256 royaltyBps;
        uint256 totalEarned;
        uint256 claimed;
    }
    Royalty[] public royalties;
    mapping(uint256 => mapping(address => bool)) public royaltyRecord;
    uint256 public royaltyCount;
    mapping(bytes32=>bool) public nftRegistered;

    event RoyaltyRegistered(uint256 indexed rid, address indexed nftContract, uint256 tokenId, address indexed creator, uint256 bps);
    event RoyaltyPaid(uint256 indexed rid, address indexed from, address indexed to, uint256 amount);
    event RoyaltyClaimed(uint256 indexed rid, address indexed creator, uint256 amount);

    // FIX: was onlyOwner with an arbitrary creator param (wrong plane + grief). The
    // creator now self-registers their own NFT; creator address == msg.sender.
    function registerRoyalty(address nftContract, uint256 tokenId, uint256 royaltyBps)
        external nonReentrant returns (uint256) {
        require(nftContract != address(0), "Zero nft contract");
        require(nftContract.code.length>0&&IRegisteredNFT(nftContract).ownerOf(tokenId)==msg.sender,"Not NFT owner");
        bytes32 key=keccak256(abi.encode(nftContract,tokenId));
        require(!nftRegistered[key],"Royalty already registered");nftRegistered[key]=true;
        require(royaltyBps <= 1000, "Max 10%");
        Royalty storage r = royalties.push();
        r.nftContract = nftContract;
        r.tokenId = tokenId;
        r.creator = msg.sender;
        r.royaltyBps = royaltyBps;
        r.totalEarned = 0;
        r.claimed = 0;
        uint256 rid = royalties.length - 1;
        royaltyCount = rid + 1;
        royaltyRecord[rid][msg.sender] = true;
        emit RoyaltyRegistered(rid, nftContract, tokenId, msg.sender, royaltyBps);
        return rid;
    }

    // FIX: previously emitted an event but moved no value (royalty never reached the
    // creator). Now the payer sends the computed royalty into the registry as a claim;
    // creator later withdraws via pull-payment claimRoyalties().
    function payRoyalty(uint256 rid, address from, address to) external payable nonReentrant {
        Royalty storage r = royalties[rid];
        require(royaltyRecord[rid][r.creator], "Not registered");
        require(msg.value > 0, "Zero royalty");
        require(from==msg.sender&&to==r.creator,"Incorrect payment parties");
        r.totalEarned += msg.value;
        emit RoyaltyPaid(rid, from, to, msg.value);
    }

    // FIX: added the missing exit — creator pulls their accrued royalty balance
    // (plain call, no transfer/send).
    function claimRoyalties(uint256 rid) external nonReentrant {
        Royalty storage r = royalties[rid];
        require(msg.sender == r.creator, "Only creator");
        uint256 amount = r.totalEarned - r.claimed;
        require(amount > 0, "Zero claimable");
        r.claimed += amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Claim failed");
        emit RoyaltyClaimed(rid, msg.sender, amount);
    }

    function getRoyalty(uint256 rid) external view returns (address nftContract, uint256 tokenId, address creator, uint256 royaltyBps, uint256 totalEarned) {
        Royalty storage r = royalties[rid];
        return (r.nftContract, r.tokenId, r.creator, r.royaltyBps, r.totalEarned);
    }
}
