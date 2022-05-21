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

contract ContactLenses is ERC721Enumerable {

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
      '<svg width="400" height="400"  xmlns="http://www.w3.org/2000/svg">',
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
          '<path d="M445.2 132.5c0 1.6.2 2.2.5 1.2.2-.9.2-2.3 0-3-.3-.6-.5.1-.5 1.8zm-29.6 9.5c-1.1 5.6-6.7 15.9-10.6 19.4-2.3 2-5.2 3.5-7.7 3.9-2.2.4-4.6 1.5-5.4 2.4-2 2.3-6.8 15.1-7 18.3-.3 6.3.1 6.6 3 2 4.2-6.6 11.2-12.7 15.7-13.6 2.7-.5 3.9-.3 4.2.6.3.7 2.2-.8 4.8-3.6 2.4-2.6 4.4-4.9 4.4-5.1 0-.3-.7-1.1-1.5-1.9-2-2.1-1.9-5.9.5-13.4 2.2-6.9 2.4-8.8 1.1-10.8-.6-1-1-.4-1.5 1.8zm-1 10c-1.9 4.7-2.1 11.1-.5 12.7 1.7 1.7-3.9 8.4-6.4 7.8-4.1-.8-10.6 2.6-16.2 8.7-4.9 5.3-5.5 5.7-4.9 3.2.4-1.6 1.9-5.8 3.4-9.4 2.6-6.3 2.8-6.5 8-8.2 6.7-2.2 10.8-6.2 14.5-13.8 3.2-6.7 4.7-7.3 2.1-1z"/>',
    '<path d="M162.4 319.8c-9.8 3.4-18.4 11.5-24.5 23.2-3.6 6.8-3.4 18.4.4 26.2 1.6 3.2 4.5 7.1 6.5 8.8 14.6 12.1 40.9 4.7 50.9-14.2 2.6-4.9 2.8-6.1 2.6-15.6-.1-9-.5-11.1-2.8-15.8-3.2-6.4-8.4-10.7-15.8-12.9-6.5-1.9-11-1.9-17.3.3zm16.9 4.2c2.9 1.1 6.7 3.4 8.3 5.1l2.9 3.2-4.4-2.9c-3.9-2.6-5.4-2.9-12-2.9-9.1 0-14.9 2.4-21.5 9.1-8.8 8.7-12.2 22.4-7.6 29.9 4.8 7.7 14.9 10.9 25.6 8 14.4-3.9 21.6-14.8 17-25.8-2.7-6.7-11.9-11.6-19.5-10.3-10.5 1.7-18.1 14.9-13.9 24.1 3.5 7.7 18.3 7.3 22.3-.6 2.3-4.3 1.6-8.8-1.8-11.3-2.6-1.9-3-1.9-5.5-.5-1.5.8-2.8 2.4-3 3.4-.3 1.6-.1 1.8.9.7 3.2-3 6.9 0 4.9 3.9-2.3 4.2-9.1 3.6-11-1-2.2-5.5 3.6-13.1 10-13.1 3 0 7.5 2.5 9.9 5.6 1.5 1.9 2.1 4.1 2.1 7.7 0 4.4-.4 5.4-3.8 8.7-4.2 4.3-10.2 6.3-15.3 5.4-12.8-2.4-18.4-14.4-11.8-25 8.5-13.9 24.5-15.9 35.8-4.6 3.2 3.2 5.1 6.2 6 9.3 1.2 4.2 1.1 5.1-.7 9.3-2.9 6.5-11.2 14.9-17.5 17.7-9.5 4.1-23.1 2.6-29.5-3.4-4.6-4.2-5.7-7.6-5.6-17.2.1-7.7.5-10 2.8-15 4-8.9 10.5-14.9 19.5-18.1 5.2-1.9 10.3-1.7 16.4.6zm236.9 67.3c-3.9 4.6-6.6 15.7-3.9 15.7 2.3 0 3.9 1.7 4.7 5.1l.8 3.4.1-3.3c.1-2.7-.5-3.6-2.9-5-1.6-.9-3-2.2-3-2.9 0-.6 1.5-4.1 3.4-7.7 3.1-6 3.5-8.6.8-5.3zm-8.5 24.9c-.6 10-2.5 19-3.8 18.2-.5-.3-.9.2-.9 1 0 3.6 2.1 1.2 3.5-4.2.9-3.1 1.9-6.4 2.2-7.2s.5-4.3.4-7.8c-.3-6.2.3-7.2 2.9-5 .8.7.6.3-.4-1-1.1-1.2-2.2-2.2-2.6-2.2s-1 3.7-1.3 8.2zm4.5-.4c-1.1 2.5-1.1 2.5.4 1 .9-.9 1.5-2.1 1.3-2.7s-1 .2-1.7 1.7zM377 426.7c-4.7.8-8.5 2.6-11.8 5.7-3.4 3.1-7.2 9.4-7.2 11.8 0 .7.9-.5 1.9-2.7s2.5-4.6 3.4-5.4c1.5-1.2 1.7-1.1 1.7 1.1 0 3.1 2.7 5.6 6.9 6.4 4.3.9 8.1-2.5 8.1-7.3 0-2.6-.6-3.7-3.1-5.2-3.8-2.3-2.7-3.1 5.1-3.8 5.6-.5 6-.4 7 1.8l1 2.4-.3-2.5c-.2-2.3-.6-2.5-5.2-2.6-2.7-.1-6.1 0-7.5.3zm24.1.9c0 1.1.3 1.4.6.6.3-.7.2-1.6-.1-1.9-.3-.4-.6.2-.5 1.3zm1 4c0 1.1.3 1.4.6.6.3-.7.2-1.6-.1-1.9-.3-.4-.6.2-.5 1.3z"/>',
         
        '</g>'
      ));

    return render;
  }
}