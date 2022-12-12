const { expect } = require("chai");
const { deployments, ethers } = require("hardhat");

describe("initial coin offering", () => {
  const price = ethers.utils.parseEther("0.0005");

  const increaseTime = async (n) => {
    await ethers.provider.send("evm_increaseTime", [86400 * n]); // add seconds
    await ethers.provider.send("evm_mine", []); // force mine the next block
  };

  const amount = (n) => ethers.utils.parseEther(n);

  let token, ico, owner, buyer, aBuyer;
  beforeEach(async () => {
    [owner, buyer, aBuyer] = await ethers.getSigners();
    await deployments.fixture(["all"]);
    token = await ethers.getContract("Token");
    ico = await ethers.getContract("ICO");
    const bal = await token.balanceOf(owner.address);
    await token.transfer(ico.address, bal);
  });
  it("get price", async () => {
    const getPrice = await ico.getCurrentPrice();
    expect(getPrice).to.equal(price);
  });
  it("buy token", async () => {
    const amountToBePurchased = 10000;
    await expect(
      ico.connect(buyer).buy(1, { value: price })
    ).to.be.revertedWith("BelowMinimumBuy");
    await expect(
      ico.connect(buyer).buy(amountToBePurchased, { value: price })
    ).to.be.revertedWith("IncorrectAmountOfEtherSent");
    await ico
      .connect(buyer)
      .buy(amountToBePurchased, { value: ethers.utils.parseEther("5") });
    const buyerBalance = await token.balanceOf(buyer.address);
    expect(buyerBalance).to.equal(
      ethers.utils.parseEther(amountToBePurchased.toString())
    );
    increaseTime(1);
    await expect(
      ico
        .connect(buyer)
        .buy(500000, { value: ethers.utils.parseEther("230.75") })
    ).to.be.revertedWith("AboveMaximumBuy");
    increaseTime(15);
    await expect(
      ico
        .connect(buyer)
        .buy(amountToBePurchased, { value: ethers.utils.parseEther("5") })
    ).to.be.revertedWith("SalesHasEnded");

    const bal = await ico.getAmountOfTokenPurchased(buyer.address);
    expect(bal).to.equal(
      ethers.utils.parseEther(amountToBePurchased.toString())
    );
  });
  it("balance above target", async () => {
    await ico.connect(buyer).buy(50000, { value: amount("25") });
    await ico.buy(40000, { value: amount("20") });
    await ico.connect(aBuyer).buy(50000, { value: amount("25") });
    expect(await ico.contractBalance()).to.equal(amount("50"));
  });
  it("withdraw", async () => {
    await expect(ico.withdraw()).to.be.revertedWith("SaleIsStillActive");
    await ico.connect(buyer).buy(10000, { value: amount("5") });
    increaseTime(15);
    await ico.withdraw();
    expect(await ico.contractBalance()).to.equal("0");
  });
});
