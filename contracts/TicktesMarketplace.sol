// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketsMarketPlace is ERC721URIStorage{

    using Counters for Counters.Counter;
    Counters.Counter private _tiketsIds;
    Counters.Counter private _tiketsSold;

    //uint256 listingPrice = 0.00056 ether;
    address  payable public  owner;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
      uint256 tokenId;
      string matchId;
      uint gameWillfinishAfter;
      uint addedAt;
      address payable seller;
      address payable owner;
      uint256 price;
      bool sold;
    }

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      bool sold
    );

    constructor() ERC721("Metaverse Tokens", "METT") {
      owner = payable(msg.sender);
    }

    modifier onlyOnwer(){
      require(msg.sender == owner);
      _;
    }
    

    
    function createTickets(string memory tokenURI,uint _gameWillfinishAfter, uint256 price,uint number,string memory matchId) public payable onlyOnwer  {
        for(uint i=0;i<number ; i++){
            _tiketsIds.increment();
            uint256 newTokenId = _tiketsIds.current();
            _mint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, tokenURI);
            createMarketItem(newTokenId, _gameWillfinishAfter, price,matchId);
         }
    }
    function createMarketItem(
      uint256 tokenId,
      uint _gameWillfinishAfter,
      uint256 price,
      string memory matchId
    ) private {
      require(price > 0, "Price must be at least 1 wei");

      idToMarketItem[tokenId] =  MarketItem(
        tokenId,
        matchId,
        _gameWillfinishAfter,
        block.timestamp,
        payable(msg.sender),
        payable(address(this)),
        price ,
        false
      );

      _transfer(msg.sender, address(this), tokenId);
      emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        price,
        false
      );
    }
    function numberOfTicketById(string memory _matchId) public view returns(uint){
      return fetchMatchById(_matchId).length;
    }

    function fetchMatchById(string memory _matchId) public view returns (MarketItem[] memory) {
      uint totalItemCount = _tiketsIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (keccak256(abi.encodePacked(idToMarketItem[i + 1].matchId)) == keccak256(abi.encodePacked(_matchId))&& !idToMarketItem[i + 1].sold) {
          itemCount += 1;
        }
      }
      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if ( keccak256(abi.encodePacked(idToMarketItem[i + 1].matchId)) == keccak256(abi.encodePacked(_matchId)) && !idToMarketItem[i + 1].sold) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function buyTicketToAttendMatch(
      uint256 tokenId
      ) public payable{
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      uint time = idToMarketItem[tokenId].gameWillfinishAfter + idToMarketItem[tokenId].addedAt;
      require(block.timestamp < time , "Game is over");
      require(msg.value == price , "Please submit the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].sold = true;
      idToMarketItem[tokenId].seller = payable(address(0));
      _tiketsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      //payable(owner).transfer(listingPrice);
      payable(seller).transfer(msg.value);
    }
    function BuyTicketAsCollection(uint256 tokenId
      ) public payable{
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      uint time = idToMarketItem[tokenId].gameWillfinishAfter + idToMarketItem[tokenId].addedAt;
      require(block.timestamp > time , "Game is over");
      require(msg.value == price , "Please submit the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].sold = true;
      idToMarketItem[tokenId].seller = payable(address(0));
      _tiketsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      //payable(owner).transfer(listingPrice);
      payable(seller).transfer(msg.value);
    }

    function fetchMyTikets() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tiketsIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function get(uint tokenId) public view  returns(uint){
      return idToMarketItem[tokenId].price;
    }

    function resellTicket(uint256 tokenId) public payable {
      uint time = idToMarketItem[tokenId].gameWillfinishAfter + idToMarketItem[tokenId].addedAt;
      require(block.timestamp < time , "Game is over");
      require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      idToMarketItem[tokenId].sold = false;
      idToMarketItem[tokenId].price = idToMarketItem[tokenId].price;
      idToMarketItem[tokenId].seller = payable(msg.sender);
      idToMarketItem[tokenId].owner = payable(address(this));
      _tiketsSold.decrement();

      _transfer(msg.sender, address(this), tokenId);
    }

    function resellTicketAsNft(uint256 tokenId,uint256 _price) public payable {
      uint time = idToMarketItem[tokenId].gameWillfinishAfter + idToMarketItem[tokenId].addedAt;
      require(block.timestamp > time , "Game still going");
      require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      idToMarketItem[tokenId].sold = false;
      idToMarketItem[tokenId].price = _price;
      idToMarketItem[tokenId].seller = payable(msg.sender);
      idToMarketItem[tokenId].owner = payable(address(this));
      _tiketsSold.decrement();

      _transfer(msg.sender, address(this), tokenId);
    }
}




