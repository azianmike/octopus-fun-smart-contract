/**
* @type import('hardhat/config').HardhatUserConfig
*/
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
const { API_URL, PRIVATE_KEY } = process.env;
module.exports = {
   solidity: "0.8.0",
   defaultNetwork: "ropsten",
   networks: {
      hardhat: {},
      ropsten: {
         url: API_URL,
         accounts: [`0x${PRIVATE_KEY}`]
      },
      rinkeby: {
         url: "https://eth-rinkeby.alchemyapi.io/v2/TKVGogO6tPjkYkybBvLs4VBMPx4wgItM",
         accounts: [`0x${PRIVATE_KEY}`]
      }
   },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "16BN3EFPR953EC2MT8AIKSRZ1X8FX8BZ28"
  }
}
