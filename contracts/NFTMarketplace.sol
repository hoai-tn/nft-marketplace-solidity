// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CTCKMarketplace is ERC721, ERC721URIStorage, Ownable {
    constructor(
        address initialOwner
    ) ERC721("CTCK Marketplace", "CTCKM") Ownable(initialOwner) {
    }
}
