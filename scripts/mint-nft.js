require("dotenv").config()
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const API_URL = process.env.API_URL

const { createAlchemyWeb3 } = require("@alch/alchemy-web3")
const web3 = createAlchemyWeb3(API_URL)

const contract = require("../artifacts/contracts/OctopusFun.sol/OctopusFun.json")
const contractAddress = "0x55B0b498B2B0d001635ABD51dF428374c5D59d61"
//console.log(JSON.stringify(contract.abi))
const nftContract = new web3.eth.Contract(contract.abi, contractAddress)


async function mintNFT(tokenURI) {
  const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, "latest") //get latest nonce

  //the transaction
  const tx = {
    from: PUBLIC_KEY,
    to: contractAddress,
    nonce: nonce,
    gas: 500000,
    data: nftContract.methods.mintNFT(PUBLIC_KEY, tokenURI).encodeABI(),
    value: 1,
  }

  const signPromise = web3.eth.accounts.signTransaction(tx, PRIVATE_KEY)
  signPromise
    .then((signedTx) => {
      web3.eth.sendSignedTransaction(
        signedTx.rawTransaction,
        function (err, hash) {
          if (!err) {
            console.log(
              "The hash of your transaction is: ",
              hash,
              "\nCheck Alchemy's Mempool to view the status of your transaction!"
            )
          } else {
            console.log(
              "Something went wrong when submitting your transaction:",
              err
            )
          }
        }
      )
    })
    .catch((err) => {
      console.log(" Promise failed:", err)
    })
}

mintNFT(
  "https://gateway.pinata.cloud/ipfs/QmQxTqyrgpbLom65XWtXaCbRMZoCxwiiT3EByT2jWy5UQt"
)
