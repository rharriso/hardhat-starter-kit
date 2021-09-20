const { expect } = require('chai')

describe('GOT20VRF', async function () {
  let got20VRF, vrfCoordinatorMock;
  let owner, user0, user1;

  beforeEach(async () => {
    await deployments.fixture(['mocks', 'vrf']);
    [owner, user0, user1] = await ethers.getSigners()

    const LinkToken = await deployments.get('LinkToken')
    linkToken = await ethers.getContractAt('LinkToken', LinkToken.address)
    const GOT20VFR = await deployments.get('GOT20VRF')
    got20VRF = await ethers.getContractAt('GOT20VRF', GOT20VFR.address)
    const VRFCoordinatorMock = await deployments.get('VRFCoordinatorMock')
    vrfCoordinatorMock = await ethers.getContractAt('VRFCoordinatorMock', VRFCoordinatorMock.address)
  })

  it('rollDice should successfully make an external random number request', async () => {
    const houseIndex = '4';
    const expectedHouse = 'Baratheon';
    await linkToken.transfer(got20VRF.address, '2000000000000000000')

    // roll dice and get transaction id
    const transaction = await got20VRF.rollDice(user1.address)
    const tx_receipt = await transaction.wait()
    const diceRolledEvent = tx_receipt.events.find((e) => e.event === 'DiceRolled');
    const requestId = diceRolledEvent.args[0];

    // Test the result of the random number request
    await vrfCoordinatorMock.callBackWithRandomness(requestId, houseIndex, got20VRF.address)
    await sleep(2000);
    expect(await got20VRF.house(user1.address)).to.equal(expectedHouse)
  });

  it('house fails if user still rolling', async () => {
    await linkToken.transfer(got20VRF.address, '2000000000000000000')
    const transaction = await got20VRF.rollDice(user0.address);
    await transaction.wait();

    try {
      await got20VRF.house(user0.address)
      throw new Error('Shouldn\'t be here')
    } catch (e) {
      expect(e.message).to.contain("'Roll in progress'")
      console.error(e.message);
    }
  })

  it('house fails if user hasn\'t rolled', async () => {
    await linkToken.transfer(got20VRF.address, '2000000000000000000')

    try {
      await got20VRF.house(user0.address)
      throw new Error('Shouldn\'t be here')
    } catch (e) {
      expect(e.message).to.contain("'Dice not rolled'")
    }
  })
})

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}