require('dotenv').config();
const Web3 = require('web3');
const express = require('express');
const ipfsClient = require('ipfs-http-client');
const multer = require('multer');
const contract = require('./compile');
const Magic = require('@magic-sdk/admin');

const app = express();
app.use(express.urlencoded({extended: true}));
app.use(express.json());

const mAdmin = new Magic(process.env.MAGIC_SECRET_KEY);
const provider = new Web3.providers.HttpProvider(process.env.NODE_ADDRESS);
const web3 = new Web3(provider);
const privateKey = process.env.PRIVATE_KEY;
const account = web3.eth.accounts.privateKeyToAccount(privateKey);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

const ipfs = ipfsClient({ host: 'ipfs.infura.io', port: 5001, protocol: 'https' });
const upload = multer({ storage: multer.memoryStorage() });

const contractAddress = 'YOUR_CONTRACT_ADDRESS';
const dUpload = new web3.eth.Contract(contract.abi, contractAddress);

//https://magic.link/docs/auth/api-reference/server-side-sdks/node

app.post('/login', (req, res) => {
  try {
    const didToken = req.headers.authorization.substring(7);
    await magic.token.validate(didToken);
    res.status(200).json({ authenticated: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

async function authenticate(req, res, next) {
  try {
    const didToken = req.headers.authorization.substring(7);
    await mAdmin.token.validate(didToken);
    const metadata = await mAdmin.users.getMetadataByToken(didToken);
    req.user = {
      did: metadata.issuer,
      publicAddress: metadata.publicAddress,
    };
    next();
  } catch (error) {
    res.status(401).json({ error: 'Authentication failed' });
  }
}

app.use(authenticate);	//** Authenticates for ALL.

app.post('/upload', upload.single('file'), async (req, res) => {
    try {
        const file = req.file;
        const { name, description, contractAddress } = req.body;

        if (!file || !name || !description || !contractAddress) {
            return res.status(400).send('Missing required fields');
        }

        const ipfsResult = await ipfs.add(file.buffer);
        const documentHash = ipfsResult.path;

        const gasEstimate = await dUpload.methods
            .uploadDocument(account.address, name, description, documentHash)
            .estimateGas({ from: account.address });

        const receipt = await dUpload.methods
            .uploadDocument(account.address, name, description, documentHash)
            .send({ from: account.address, gas: gasEstimate });

        res.send({ receipt, documentHash });
    } catch (err) {
        res.status(500).send(err.toString());
    }
});

app.post('/incrementAllowedUploads', async (req, res) => {
    const { userAddress, additionalUploads} = req.body;

    if (!userAddress || !additionalUploads) {
        return res.status(400).send('Missing required fields');
    }

    const gasEstimate = await dUpload.methods
        .incrementAllowedUploads(userAddress, additionalUploads)
        .estimateGas({ from: account.address });

    const receipt = await dUpload.methods
        .incrementAllowedUploads(userAddress, additionalUploads)
        .send({ from: account.address, gas: gasEstimate });

    res.send({ receipt });
});

app.post('/deleteDocument', async (req, res) => {
    const { userAddress, index } = req.body;

    if (!userAddress || !index) {
        return res.status(400).send('Missing required fields');
    }

    const gasEstimate = await dUpload.methods
        .deleteDocument(userAddress, index)
        .estimateGas({ from: account.address });

    const receipt = await dUpload.methods
        .deleteDocument(userAddress, index)
        .send({ from: account.address, gas: gasEstimate });

    res.send({ receipt });
});

app.get('/getAllDocuments', async (req, res) => {
    const { userAddress } = req.body;

    if (!userAddress ) {
        return res.status(400).send('Missing required fields');
    }

    const documents = await dUpload.methods.getAllDocuments(userAddress).call();
    res.send({ documents });
});

app.get('/getUploadedDocumentCount', async (req, res) => {
    const { userAddress } = req.body;

    if (!userAddress) {
        return res.status(400).send('Missing required fields');
    }

    const count = await dUpload.methods.getUploadedDocumentCount(userAddress).call();
    res.send({ count });
});

app.get('/getAllowedUploads', async (req, res) => {
    const { userAddress } = req.body;

    if (!userAddress ) {
        return res.status(400).send('Missing required fields');
    }

    const allowedUploads = await dUpload.methods.getAllowedUploads(userAddress).call();
    res.send({ allowedUploads });
});

app.listen(3000, () => console.log('Server running on port 3000'));




/*
****Client side
const didToken = await magic.auth.loginWithMagicLink({ email });

await fetch(`\${serverUrl}user/login`, {
  headers: new Headers({
    Authorization: "Bearer " + didToken
  }),
  withCredentials: true,
  credentials: "same-origin",
  method: "POST"
});
****

*/