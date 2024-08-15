// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


struct TMembership {
    uint256 price;
    uint256 multiplier;
    uint256 tokenId;
    string name;
}

interface IHoopNFT {
    function name() external view  returns (string memory);
    function symbol() external view  returns (string memory);
    function setURI(string memory newuri) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function updatePrice(uint256 _tokenId, uint256 _price) external;
    function updateMultiplier(uint256 _tokenId, uint256 _multiplier) external;
    function updateRoyaltiesReceiver(address _receiver) external;
    function addMinter(address _minter,bool _canMint) external;
    function setMerkleRoot(bytes32 _merkleRoot) external;
    function getRoyaltiesReceiver() external view returns(address);
    function getTokenInfo(uint256 _tokenId) external view returns(TMembership memory);
    function getAllTokens() external view returns(TMembership[] memory);
    function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view returns (address, uint256);
    function getClaimFee() external view returns(uint256);
    function updatePricePerAction(uint256 _price) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function withdrawEarnings(address user) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function burn(address account, uint256 id, uint256 value) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
}