pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./TruthSeekerSVG.sol";
import "./HexStrings.sol";
import "./ToColor.sol";

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Loogies is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using HexStrings for uint160;
    using ToColor for bytes3;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    // all funds go to buidlguidl.eth
    address payable public constant recipient =
        payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);
    uint256 public constant limit = 1000;
    uint256 public constant curve = 1002; // price increase 0,4% with each purchase
    uint256 public price = 0.001 ether;
    // the 1154th optimistic loogies cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH
    mapping(uint256 => bytes3) public color;
    mapping(uint256 => uint256) public chubbiness;
    mapping(uint256 => uint256) public mouthLength;
    mapping(uint256 => uint256) public truthSeekerById;

    constructor() public ERC721("OptimisticLoogies", "OPLOOG") {}

    function mintItem() public payable returns (uint256) {
        require(_tokenIds.current() < limit, "DONE MINTING");
        require(msg.value >= price, "NOT ENOUGH");

        price = (price * curve) / 1000;

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                id,
                blockhash(block.number - 1),
                msg.sender,
                address(this)
            )
        );
        color[id] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);
        chubbiness[id] =
            35 +
            ((55 * uint256(uint8(predictableRandom[3]))) / 255);
        // small chubiness loogies have small mouth
        mouthLength[id] =
            180 +
            ((uint256(chubbiness[id] / 4) *
                uint256(uint8(predictableRandom[4]))) / 255);

        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "could not send");

        return id;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "not exist");
        string memory name = string(
            abi.encodePacked("SixPath #", id.toString())
        );
        string memory description = string(
            abi.encodePacked(
                "SixPath color #",
                color[id].toColor(),
                " with a of ",
                uint2str(chubbiness[id]),
                " and length of ",
                uint2str(mouthLength[id]),
                "!!!"
            )
        );
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "external_url":"https://burnyboys.com/token/',
                                id.toString(),
                                '", "attributes": [{"trait_type": "color", "value": "#',
                                color[id].toColor(),
                                '"},{"trait_type": "chubbiness", "value": ',
                                uint2str(chubbiness[id]),
                                '},{"trait_type": "mouthLength", "value": ',
                                uint2str(mouthLength[id]),
                                '}], "owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGofTokenById(uint256 id)
        internal
        view
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                '<svg width="400" height="400"   xmlns="http://www.w3.org/2000/svg">',
                renderTokenById(id),
                "</svg>"
            )
        );

        return svg;
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        string memory animate = "";

        animate = '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 235 245" to="360 235 245" begin="0s" dur="2s" repeatCount="indefinite" additive="sum" />';

        string memory render;

        render = string(
            abi.encodePacked(
                '<g class="eyelash" fill="#',color[id].toColor(),'" transform="translate(100,0) scale(0.5 0.5)">',
                '<g transform="matrix(1 0 0 -1 161 101)">',
                '<circle r="40" fill="transparent" stroke="#000" stroke-width="30" stroke-dasharray="18,18">',
                '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0" to="360" begin="0" dur="5s" repeatCount="indefinite"/>',
                "</circle>",
                '<path stroke="#000" d="M-20 0h40M0-20v40"/>',
                "</g>",
                '<path d="M146.1 21c-28.2 5.9-51.7 26.5-60.4 52.8-7.3 22-5.7 42.8 5 63.5 3.8 7.5 6.4 10.9 14.3 18.7 7.7 7.8 11.2 10.5 18.5 14.2 16 8.2 32.3 11.2 48.3 8.9 31.8-4.7 56.4-25.7 66.2-56.6 3.4-10.6 3.9-29.2 1.2-40.6-6.7-27.9-26.2-49.2-53.4-58.2-8.1-2.6-10.9-3.1-22.3-3.3-7.1-.2-15 .1-17.4.6zm30.7 3.6c51 10.5 76.6 67.3 51.1 113.4-5.3 9.4-17.8 22.1-27.4 27.8-38.1 22.5-87.1 8.5-107.4-30.7-12.2-23.7-11.4-51.4 2.1-74.6 4.9-8.3 18-21.6 26.1-26.4 16.9-10 36.7-13.4 55.5-9.5z"/>',
                '<path d="M149.1 41.5c-15.1 3.4-28.7 12.6-36.9 24.9-6.9 10.3-9.3 17.7-9.9 30.6-.9 18.6 4.1 31.4 17.2 44.5 12.2 12.3 24.7 17.5 41.5 17.5 26.2 0 48.2-15.7 56.5-40.3 7.3-21.7 2.1-44-13.8-60.2-8.1-8.1-13.6-11.6-23.6-15.1-9-3.1-22.2-3.9-31-1.9zm25.9 3.6c17.4 3.8 34.1 19.6 40 37.8 2.7 8.6 3.2 21.5 1.1 30.1-5 20.2-23 37.8-42.9 41.9-35.2 7.3-68.1-19.5-68.2-55.4 0-18.5 9.8-36.6 25.4-46.6C144 44 158.3 41.6 175 45.1z"/>',
                '<path d="M151 61.5c-3 .9-7.3 2.6-9.5 4-5.8 3.4-13.2 11.7-16.3 18.3-2.4 5-2.7 6.9-2.7 16.2 0 9.6.3 11 2.9 16.5 3.8 7.7 12 15.8 19.3 19.3 5.2 2.4 7 2.7 16.3 2.7 9.5 0 11.1-.3 16.8-2.9 8.2-3.8 17.1-13.1 20.3-21.3 4.5-11.6 2.8-26.1-4.3-36.8-8.8-13.2-27.6-20.2-42.8-16zm16.6 2.6c10.7 2 21.2 9.8 26.2 19.6 9 17.5 1.4 39.7-16.6 48.5-6.1 3-7.4 3.3-16.2 3.3-8.4 0-10.2-.3-15.2-2.8-7.4-3.6-13.9-10.1-17.5-17.5-2.5-5-2.8-6.8-2.8-15.2 0-8.8.3-10.1 3.3-16.2 5.9-12.1 16.6-19 31.8-20.7.6 0 3.7.4 7 1z"/>',
                '<path d="M158 75.7c-19.9 3.2-27.9 27.2-13.7 41.1 12.4 12.1 32.7 8.2 39.5-7.8 3.5-8.3.9-20.2-5.9-26.7-5.2-4.9-13.5-7.6-19.9-6.6zm15.1 6.8c6.4 4.5 9.1 10.4 8.7 18.5-.5 7.7-3.2 12.5-9.2 16.4-16.1 10.5-36.7-4.6-31.7-23.2 1.4-5 6-10.5 11-13.3 5.6-3 15.7-2.3 21.2 1.6z"/>',
                '<path d="M156 94c-2.6 2.6-3.4 6.3-2 8.9 4.1 7.7 15 5.4 15-3.2 0-6.3-8.6-10.1-13-5.7zM21.3 220.9c-6.7 2.3-11.8 6.2-15.4 11.9-7.2 11.3-5.8 25.1 3.6 35.1 5.8 6.2 12.9 9.4 21.2 9.5 3.5.1 6.3.3 6.3.6s-.9 1.8-1.9 3.4c-2.4 3.6-8.3 8.3-17.8 14.3-4 2.5-7.3 4.7-7.3 5 0 .8 11.2-.8 17-2.4 7.8-2.1 14.6-5.8 20-10.9 8.9-8.3 13-19.3 13.1-35.7.1-9.2-.2-10.4-3.1-16.3-6.6-13.4-21.4-19.5-35.7-14.5zM34.5 245c3.6 4-.7 10-5.8 8.1-3.3-1.3-4.3-4.6-2.3-7.6s5.6-3.2 8.1-.5zm117.4-24.5c-5.7 1.8-14.2 9.3-17.1 14.9-2.9 5.7-3.5 15.9-1.4 22.4 3.7 11.2 15.3 19.5 27.2 19.6 4.9.1 6.4.4 6.4 1.5 0 2.4-9.7 10.9-18.7 16.3-4.6 2.8-8.3 5.3-8.3 5.5 0 .6 9.3-.5 15.5-1.9 8.1-1.8 15.1-5.3 20.6-10.5 10.4-9.6 14.1-19.1 14.3-35.8.1-12.3-1.3-16.9-7.3-23.8-6.9-7.8-20.9-11.5-31.2-8.2zm12.5 24.1c2.4 2.4 2 6.1-.9 8-2.3 1.5-2.7 1.5-5 0-1.7-1.1-2.5-2.6-2.5-4.6 0-4.5 5.2-6.6 8.4-3.4zm116.2-23.1c-19.8 8.1-24.7 32.8-9.5 47.6 5.7 5.5 12.7 8.3 21.2 8.3 3.1.1 5.7.4 5.7.9 0 .4-1.8 2.7-4 5.1-3.6 3.9-10.2 8.7-21 15.4-3.3 2-3.4 2.2-1 2.1 1.4 0 6-.6 10.3-1.4 24.9-4.4 38.6-21.5 38.7-48.1 0-11.2-2-16.6-8.9-23.4-9.1-9-20-11.3-31.5-6.5zm15.1 24.4c1.4 2.9.4 5.5-2.8 7.1-2.8 1.5-6.9-1.1-6.9-4.5 0-5.5 7.3-7.4 9.7-2.6zm-274.4 87c-6.7 2.3-11.8 6.2-15.4 11.9-7.2 11.3-5.8 25.1 3.6 35.1 5.8 6.2 12.9 9.4 21.2 9.5 3.5.1 6.3.3 6.3.6s-.9 1.8-1.9 3.4c-2.4 3.6-8.3 8.3-17.8 14.3-4 2.5-7.3 4.7-7.3 5 0 .8 11.2-.8 17-2.4 7.8-2.1 14.6-5.8 20-10.9 8.9-8.3 13-19.3 13.1-35.7.1-9.2-.2-10.4-3.1-16.3-6.6-13.4-21.4-19.5-35.7-14.5zM34.5 357c3.6 4-.7 10-5.8 8.1-3.3-1.3-4.3-4.6-2.3-7.6s5.6-3.2 8.1-.5zm117.4-24.5c-5.7 1.8-14.2 9.3-17.1 14.9-2.9 5.7-3.5 15.9-1.4 22.4 3.7 11.2 15.3 19.5 27.2 19.6 4.9.1 6.4.4 6.4 1.5 0 2.4-9.7 10.9-18.7 16.3-4.6 2.8-8.3 5.3-8.3 5.5 0 .6 9.3-.5 15.5-1.9 8.1-1.8 15.1-5.3 20.6-10.5 10.4-9.6 14.1-19.1 14.3-35.8.1-12.3-1.3-16.9-7.3-23.8-6.9-7.8-20.9-11.5-31.2-8.2zm12.5 24.1c2.4 2.4 2 6.1-.9 8-2.3 1.5-2.7 1.5-5 0-1.7-1.1-2.5-2.6-2.5-4.6 0-4.5 5.2-6.6 8.4-3.4zm116.2-23.1c-19.8 8.1-24.7 32.8-9.5 47.6 5.7 5.5 12.7 8.3 21.2 8.3 3.1.1 5.7.4 5.7.9 0 .4-1.8 2.7-4 5.1-3.6 3.9-10.2 8.7-21 15.4-3.3 2-3.4 2.2-1 2.1 1.4 0 6-.6 10.3-1.4 24.9-4.4 38.6-21.5 38.7-48.1 0-11.2-2-16.6-8.9-23.4-9.1-9-20-11.3-31.5-6.5zm15.1 24.4c1.4 2.9.4 5.5-2.8 7.1-2.8 1.5-6.9-1.1-6.9-4.5 0-5.5 7.3-7.4 9.7-2.6zm-274.4 86c-6.7 2.3-11.8 6.2-15.4 11.9-7.2 11.3-5.8 25.1 3.6 35.1 5.8 6.2 12.9 9.4 21.2 9.5 3.5.1 6.3.3 6.3.6s-.9 1.8-1.9 3.4c-2.4 3.6-8.3 8.3-17.8 14.3-4 2.5-7.3 4.7-7.3 5 0 .8 11.2-.8 17-2.4 7.8-2.1 14.6-5.8 20-10.9 8.9-8.3 13-19.3 13.1-35.7.1-9.2-.2-10.4-3.1-16.3-6.6-13.4-21.4-19.5-35.7-14.5zM34.5 468c3.6 4-.7 10-5.8 8.1-3.3-1.3-4.3-4.6-2.3-7.6s5.6-3.2 8.1-.5zm117.4-24.5c-5.7 1.8-14.2 9.3-17.1 14.9-2.9 5.7-3.5 15.9-1.4 22.4 3.7 11.2 15.3 19.5 27.2 19.6 4.9.1 6.4.4 6.4 1.5 0 2.4-9.7 10.9-18.7 16.3-4.6 2.8-8.3 5.3-8.3 5.5 0 .6 9.3-.5 15.5-1.9 8.1-1.8 15.1-5.3 20.6-10.5 10.4-9.6 14.1-19.1 14.3-35.8.1-12.3-1.3-16.9-7.3-23.8-6.9-7.8-20.9-11.5-31.2-8.2zm12.5 24.1c2.4 2.4 2 6.1-.9 8-2.3 1.5-2.7 1.5-5 0-1.7-1.1-2.5-2.6-2.5-4.6 0-4.5 5.2-6.6 8.4-3.4zm116.2-23.1c-19.8 8.1-24.7 32.8-9.5 47.6 5.7 5.5 12.7 8.3 21.2 8.3 3.1.1 5.7.4 5.7.9 0 .4-1.8 2.7-4 5.1-3.6 3.9-10.2 8.7-21 15.4-3.3 2-3.4 2.2-1 2.1 1.4 0 6-.6 10.3-1.4 24.9-4.4 38.6-21.5 38.7-48.1 0-11.2-2-16.6-8.9-23.4-9.1-9-20-11.3-31.5-6.5zm15.1 24.4c1.4 2.9.4 5.5-2.8 7.1-2.8 1.5-6.9-1.1-6.9-4.5 0-5.5 7.3-7.4 9.7-2.6z"/>',
                "</g>"
            )
        );

        return render;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
