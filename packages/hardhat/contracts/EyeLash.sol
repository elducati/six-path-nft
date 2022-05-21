//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './HexStrings.sol';
import './ToColor.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Eyelash is ERC721Enumerable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address payable public constant recipient =
    payable(0x8faC8383Bb69A8Ca43461AB99aE26834fd6D8DeC);

  uint256 public constant limit = 1000;
  uint256 public constant curve = 1005; // price increase 0,5% with each purchase
  uint256 public price = 0.002 ether;

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => bool) public crazy;

  constructor() ERC721("Loogie Bow", "LOOGBOW") {
    // RELEASE THE LOOGIE BOW!
  }

  function mintItem() public payable returns (uint256) {
      require(_tokenIds.current() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");

      price = (price * curve) / 1000;

      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      bytes32 genes = keccak256(abi.encodePacked( id, blockhash(block.number-1), msg.sender, address(this) ));
      color[id] = bytes2(genes[0]) | ( bytes2(genes[1]) >> 8 ) | ( bytes3(genes[2]) >> 16 );
      crazy[id] = uint8(genes[3]) > 200;

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      return id;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('Loogie Bow #',id.toString()));
      string memory crazyText = '';
      string memory crazyValue = 'false';
      if (crazy[id]) {
        crazyText = ' and it is crazy';
        crazyValue = 'true';
      }
      string memory description = string(abi.encodePacked('This Loogie Bow is the color #',color[id].toColor(),crazyText,'!!!'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://www.fancyloogies.com/bow/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              color[id].toColor(),
                              '"},{"trait_type": "crazy", "value": ',
                              crazyValue,
                              '}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    // bow svg from https://www.svgrepo.com/svg/203940/bow with CCO Licence
    string memory animate = '';
    if (crazy[id]) {
      animate = '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 235 245" to="360 235 245" begin="0s" dur="2s" repeatCount="indefinite" additive="sum" />';
    }
    string memory render = string(abi.encodePacked(
      '<g class="bow" fill="#',color[id].toColor(),'"  transform="translate(-65,8) scale(0.4 0.4)">',
          '<path d="M535.5 86.4c-8 2.5-13.2 6.3-18.3 13.4-3.8 5.4-7.2 15.6-7.2 21.8 0 9.8 7.3 21.5 16.8 27.2 4.1 2.3 5.8 2.7 12.7 2.7 9.3 0 14.4-2 21.9-8.6 6-5.3 9.2-12.3 10.7-23.4s-.1-17.7-5.7-24.3c-7.2-8.4-20.3-12.1-30.9-8.8zm19.1 5.7c7.9 3.8 15.1 14.4 13.8 20.2-3.5 16.5-23.6 29-35.3 22.1-6.4-3.8-10.1-12.2-8.7-19.7.8-4.5 7-11.5 12-13.8 4.9-2.2 11.7-2.4 15.4-.5 11.1 5.7 4.1 25.6-9 25.6-4.3 0-7.8-3.6-7.8-8 0-6 7.6-10.6 11-6.5 2.1 2.6.8 5-2.8 5-2.3 0-3.2.4-3 1.4.8 4.1 7.6 3.8 10.5-.5 4.4-6.8.1-14.7-7.9-14.7-9 0-14.8 5.8-14.8 14.9s7.1 16 15.4 15c5.2-.6 12.4-5.3 16-10.4 4.2-5.9 4.8-14.2 1.4-19.1-3.4-5.1-7.9-7.3-15.7-7.9-8.5-.6-15.3 2.1-21.1 8.4-5 5.5-6 8-6 15.2.1 13.8 11.7 25.2 25.7 25.2 5.1 0 9.8-1.8 15-5.7l3.8-2.7-3 3.2c-1.6 1.8-5.6 4.6-8.9 6.2-13 6.5-26.5 2.1-32.7-10.8-3-6.2-3.3-20.4-.6-27.3 5-13.1 24.7-20.9 37.3-14.8zM242.7 121c-10.9 8.5-11.5 10.1-6.7 17.1 1.6 2.4 3 5.1 3 6 0 .8-1.4 3.7-3.1 6.4l-3 4.8 2.1 2.1 2.2 2.1-1.2-2.3c-1-2-.8-2.9 1.6-6.3 3.4-5 3.5-8.6.1-13.1-3.9-5.1-3.5-7.4 2.4-13 2.9-2.7 5.4-4.7 5.6-4.4.2.2-.3 2.6-1.2 5.3-2.1 6.2-2.2 16-.1 20 4.3 8.3 12.1 10.6 19.2 5.5l3.9-2.8.1 5.6c0 6.6 1.4 9.2 11 20.7 8.8 10.5 11.6 16.5 12.2 25.9.5 7.8-1.1 18.2-3.4 22.4l-1.3 2.5.4-3c1.3-9.1 1.3-11.7 0-18.7-3.6-20.5-20.9-37.5-42-41.3-3.8-.7-7.4-1.4-8-1.6-1.9-.5-13.1 1.4-18.4 3.2-7.7 2.7-14.1 7.1-20.8 14.3-12.2 13-16.6 28.1-13.2 44.8 1.7 8.4 8.3 21.1 13.8 26.6 9.2 9.2 24.3 15.2 38.6 15.2 19.3 0 34.6-9.5 44.5-27.8 9-16.4 10-18.8 11.1-26.2 2.1-14.2-.5-23.3-9.9-34.5-10.6-12.6-12.6-16.1-13-22.8-.2-4.8.1-7.1 1.7-10.1 1.9-3.7 1.8-3.7-4.4 2.3-6 5.8-7.7 6.6-13 6.2-2.9-.3-7.2-5.4-8.5-10.3-1.5-5.3.1-14 3.7-21.1 1.3-2.7 2.2-5.1 2-5.3s-3.8 2.3-8 5.6zm4.8 43.5c13.3 3.5 27.3 14.3 33 25.4 13.2 26.2-.1 61-27.1 70.8-13.5 4.8-27.9 3.7-42.2-3.2-13.5-6.7-22.4-19.1-25.9-36-3.1-15.3 1.5-29.9 13.2-42.3 10.8-11.4 20.9-16 35.5-16.1 4.2-.1 10.2.6 13.5 1.4z"/>',
          '<path d="M235.7 178.1c-6.1.9-16.2 5.7-21 9.8-2 1.8-5.1 6.3-6.9 9.9-2.8 5.7-3.3 7.7-3.3 13.7.1 16.6 3.5 23.4 14.3 28.7 12.7 6.2 25.2 3.6 36.5-7.7s15.3-24.7 10.8-36.5c-5-13.3-16.3-20-30.4-17.9zm11.7 5.4c7 1.8 9.8 3.8 12.8 9 1.9 3.4 2.3 5.4 2.3 12.5-.1 10.8-2.3 17.4-8 23.8-11.2 12.4-27.4 14.4-38.2 4.5l-3.8-3.4 5.6 3.1c7.5 4.1 14.1 4.1 22.4.1 11.1-5.3 18.6-15.7 19.3-26.7.6-9.4-3.6-15.3-13.2-18.4-7.4-2.4-20.5.8-26.4 6.3-11.1 10.3-6.1 26.6 9.1 30.1 9.3 2.2 20.7-7.6 20.7-17.8 0-7.7-3.8-11.7-11.2-11.8-7.7-.2-13.8 5-13.8 11.5 0 6.2 7.5 9.3 11.2 4.7 2.2-2.8 1.7-3.6-1.1-1.8-1.7 1.1-2.3 1-3.7-.4-1.6-1.6-1.6-1.8 0-4.2 1.1-1.8 2.5-2.6 4.6-2.6 3.2 0 7 3 7 5.6 0 3.4-3.4 8.6-6.7 10.2-3 1.4-3.8 1.5-7.6.2-9.1-3.2-11.6-14.4-4.7-21.5 10.3-10.7 30.1-3.7 30 10.7-.1 6.9-7.5 17.2-14.3 19.7-4.9 1.9-13.7 1.3-18.7-1.3-5.3-2.7-10.5-9-12-14.7-1-3.5-.8-4.7 1.1-8.7 2.9-6 10.2-13.8 15.4-16.5 7.6-3.9 13.2-4.5 21.9-2.2zM460.5 116c-1.1.5-6.4.9-11.9.9l-9.8.1 3.1 3.5c1.7 2 3.1 4.3 3.2 5.3 0 1.1.2 1.2.6.4.2-.7-.4-2.7-1.4-4.5l-1.9-3.2h18.3l-.8 3.5c-.5 1.9-.9 5.4-.9 7.7 0 6.2-1.7 8.9-6.9 11.4-2.5 1.1-5.4 2.8-6.3 3.6-1.6 1.5-1.7 1.2-1.3-3.8l.5-5.4-1.3 6c-1.5 6.8-2.6 9.2-5.6 11.9-1.2 1.1-2.1 2.4-2.1 2.9s2.7-1.8 6-5.2c3.2-3.4 7.8-7 10.2-8 6.9-2.9 8-4.9 8.8-15 .4-4.8 1.3-9.8 1.9-11 1.2-2.2.8-2.5-2.4-1.1zm144.7 16.2c-5.8 8.5-6.5 10.7-5.2 15.1.6 2.1 1.4 3.6 1.7 3.3s.1-1.8-.5-3.5c-.9-2.5-.6-3.8 1.8-8.8l2.9-5.8-.6 4.5c-1.6 10.9-.3 15 6.4 19.5l2.9 2-5.7 10.5c-5.5 9.9-10.8 15.8-13 14.4-.5-.3-.9-2-.9-3.7 0-1.8-.9-5-2-7.1l-1.9-3.9 3.3-4.1c3.7-4.5 6.6-9.8 6.6-11.8-.1-.7-1.2 1-2.6 3.9-1.4 2.8-4.1 6.6-6.1 8.4-3 2.6-3.4 3.4-2.5 4.8 3.6 5 5.1 14.1 3.4 20.4-1.4 4.8-.6 4.7 1.7-.3 1-2.2 3.3-5 5.2-6.3 2.2-1.5 5.4-5.9 9.6-13.2 3.4-6.1 6.2-11.5 6.2-12.2.1-.6-.8-1.4-1.8-1.8-1.1-.3-3.4-2.2-5.2-4.2-3.1-3.6-3.2-3.8-2.6-11.4.3-4.2 1-8.6 1.7-9.9 2.1-4 .2-3.2-2.8 1.2z"/>',
          
    

        '</g>'
      ));

    return render;
  }
}