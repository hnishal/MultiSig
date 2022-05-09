const main = async() =>{
    const[deployer,addr1,addr2,addr3] = await hre.ethers.getSigners();
    console.log("Deployer", deployer.address);
    console.log("Deployer balance: ", (await deployer.getBalance()).toString());
    const contractFactory = await hre.ethers.getContractFactory("MultiSig");
    const multisigwallet= await contractFactory.deploy([deployer.address,addr1.address,addr2.address],2);
    await multisigwallet.deployed();
    console.log("Contract deployed at: ",multisigwallet.address);
}

const runMain = async() =>{
    try{
        await main();
        process.exit(0);
    }catch(err){
        console.log(err);
        process.exit(1);
    }
}

runMain();