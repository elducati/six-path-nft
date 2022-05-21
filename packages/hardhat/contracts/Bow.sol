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

contract Bow is ERC721Enumerable {

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
          '<path d="M358.1 30.6c0 1.1.3 1.4.6.6.3-.7.2-1.6-.1-1.9-.3-.4-.6.2-.5 1.3zm-3 7.8c-1.7 3.5-6.5 9.1-15.2 17.7-13.1 13-16.5 17.8-17.9 25.8-.4 2.5-2.1 7.5-3.6 11.1-3.2 7.7-4.3 19.5-2.5 28.2 1.9 9.1 8.4 21.3 14.4 27.1 15.7 15.4 42.9 19.3 62.1 8.9 15.2-8.1 26.6-28.3 26.6-46.9 0-13.8-4.7-25-14.5-34.8C396 67 381.6 60 372.8 60c-1.5 0-2.8-.4-2.8-.9 0-2.1-5.3-7.1-7.5-7.1-1.2 0-3.4-.9-4.9-2.1-3-2.4-3.4-5.8-1-11.4 2.3-5.7 1.2-5.8-1.5-.1zm1.1 12.3c.7.5 2.9 1.6 4.8 2.3s4.3 2.2 5.3 3.4l1.9 2-8.1 1.2c-11.6 1.7-21.5 6.6-29.8 14.9-5.4 5.4-6.4 6.1-5.9 3.9 1.2-4.6 5.3-9.9 14.5-18.9 5-4.9 10.1-10.3 11.3-12.2l2.3-3.3 1.2 2.8c.6 1.6 1.8 3.3 2.5 3.9zm22.7 11.8c26.5 6.3 43.1 31.6 37.7 57.5-7.3 34.9-41.3 51.6-73.2 35.9-19.4-9.6-30.8-33.7-26-55.1 3.9-17.6 20.5-34.7 37.3-38.7 6-1.4 17.2-1.2 24.2.4z"/>',
          '<path d="M359.3 79.4c-6 1.9-10.3 4.8-16.2 11.1-12.3 13-13.1 26.8-2.1 38.9 6.9 7.5 11.3 9.1 25.5 9.1 10.2 0 11.4-.2 16.9-3 11.1-5.6 17.8-16.7 17.9-29.5.1-8.2-2.8-14.5-9.1-20-7.8-6.9-22.4-9.8-32.9-6.6zm25.5 5.8c6.9 3.2 12.2 13.4 12.2 23.2 0 8.2-7.9 19.4-16.8 24-12.8 6.6-33.2-9.6-30.7-24.3 1.6-9.4 12.9-18 22.2-16.7 6.6.9 10.7 3.8 13.7 9.8s3.2 9.6.9 14.5c-5.6 12-26.6 8.1-26.6-4.9 0-4.2 5-8.8 9.6-8.8 6.8 0 10.3 8.7 4.4 10.9-3.4 1.3-4.9.2-4.5-3 .5-3.3-.3-3.6-2.6-1.3-2 1.9-2 4.3-.1 7.1 2.2 3.1 6.7 3.8 11 1.7 6.1-2.9 8.1-9.3 4.9-16-5.3-11.1-24.7-7.1-28.6 5.7-3 10.2 6.9 21.9 18.7 21.9 9.7 0 16.6-6.6 18.7-17.6 1.3-7.2.1-12.3-4.1-18.1-5.7-7.8-15.1-10.1-25.5-6.3-11.8 4.4-19.6 15.1-19.6 26.8 0 7 .8 9.1 5.4 14.1 2.7 3.1 2.8 3.3.6 1.9-3.8-2.3-8.8-9.3-10.1-14.1-2.8-10.6 3.8-23 15.4-28.7 10.4-5.1 22.9-5.8 31.5-1.8zM502 71.1c0 6.7-1.2 10.2-6.2 17.5-3.7 5.4-5.8 12.6-7.8 25.8-2.5 16.7-1 27 5.8 40.1 8.9 17.1 27.2 27.5 48.4 27.5 15.4 0 26.1-4.3 36.4-14.6 6.7-6.8 12.5-16.9 14.9-26 1.9-7.1 2.1-20.1.4-26.9-7.5-30.9-45.5-49.4-74.5-36.1-6 2.8-7.7 2.2-8.8-2.9-.4-1.7-2.5-4.6-4.7-6.6l-3.9-3.7v5.9zm5.2.6c1 .9 1.8 2.5 1.8 3.6 0 1.2.9 3 1.9 4.1 2 2.1 2 2.1-3.7 6.6-3.1 2.5-8.1 7.9-10.9 11.9-2.9 4-5.3 6.8-5.3 6.2 0-2.4 4.4-12.4 7.4-16.8 3.7-5.5 5.6-10.3 5.6-14.4 0-3.3.6-3.6 3.2-1.2zm47.7 6c13.5 3.7 27.8 14.8 33.5 26 10.4 20.5 5.4 47-12.1 63.9-8 7.9-22 13.4-33.8 13.4-13.2 0-29.7-6.4-38.3-14.8-16.3-15.9-20.7-43.2-10-62.2 13-23 36.2-33.1 60.7-26.3z"/>',
             

        '</g>'
      ));

    return render;
  }
}