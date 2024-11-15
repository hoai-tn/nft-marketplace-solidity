import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { NMTMarketplace } from "../typechain-types";
import { parseEther } from "../utils/parser";

type FixtureResult = {
  owner: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
  carol: SignerWithAddress;
  NFTMarketplace: NMTMarketplace;
};
describe("NFTMarketplace", function () {
  async function deployContractFixture(): Promise<FixtureResult> {
    const [owner, alice, bob, carol]: SignerWithAddress[] =
      await ethers.getSigners();

    let nftMarketPlace: NMTMarketplace;

    const NFTMarketplaceContract = await ethers.getContractFactory(
      "NMTMarketplace"
    );

    nftMarketPlace = await NFTMarketplaceContract.deploy(
      await owner.getAddress()
    );

    await nftMarketPlace.waitForDeployment();

    return {
      owner,
      alice,
      bob,
      carol,
      NFTMarketplace: nftMarketPlace,
    };
  }

  // Happy path
  it("Should update listing price", async function () {
    const { NFTMarketplace } = await deployContractFixture();
    const price = parseEther(0.1);

    await NFTMarketplace.updateListingPrice(price);

    const listingPrice = await NFTMarketplace.getListingPrice();

    expect(listingPrice).to.equal(price);
  });

  it("Should create NFT", async function () {
    const { NFTMarketplace, alice } = await deployContractFixture();
    const getListingPrice = await NFTMarketplace.getListingPrice();

    const price = parseEther(0.1);

    await NFTMarketplace.connect(alice).createToken(
      "https://gateway.pinata.cloud/ipfs/",
      price,
      {
        value: getListingPrice,
      }
    );

    const nfts = await NFTMarketplace.fetchMarketItems();

    expect(nfts.length).to.equal(1);

    expect(nfts[0][0]).to.equal(1);
    expect(nfts[0][1]).to.equal(await alice.getAddress());
    expect(nfts[0][3]).to.equal(price);
    expect(nfts[0][4]).to.equal(false);
  });

  it("Should sell NFT", async function () {
    
  });
});
