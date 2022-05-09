const {expect} = require("chai");


describe("MultiSig Wallet",function(){

    let walletContract;
    let addr1;
    let addr2;
    let owner;
    let addr3;

    beforeEach(async function(){
        const contractfactory = await hre.ethers.getContractFactory("MultiSig");
        [owner, addr1, addr2, addr3] = await hre.ethers.getSigners();
        walletContract= await contractfactory.deploy([owner.address, addr1.address, addr2.address],2);
        await walletContract.deployed();
    });

    describe("Deployment", function(){

        it("should set the right owner", async function(){
            expect(await walletContract.getDeployers()).to.equal(owner.address);
        })

        it("should populate the owners list", async function(){
            expect(await walletContract.getOwners()).to.have.lengthOf(3);
        })
    });

    describe("Transaction" ,function(){

        beforeEach(async function(){
            await walletContract.submitTransaction(addr3.address, hre.ethers.utils.parseEther("0.01"),{value: hre.ethers.utils.parseEther("0.01")});
        })

        it("should create a transaction", async function(){
            expect(await walletContract.getTotalTransactionCount()).to.equal(1);
        });
        const provider = waffle.provider;
        it("should be added to wallet balance",async function(){
            const balance = await provider.getBalance(walletContract.address);
            expect(hre.ethers.utils.formatEther(balance)).to.equal('0.01');
        });

        it("should execute the Transaction", async function(){
            let tx = await walletContract.signTransaction(0);
            tx= await walletContract.connect(addr1).signTransaction(0);
            let txe = await walletContract.executeTransaction(0);
            expect(await walletContract.getTransactionStatus(0)).to.equal(true);

        })
        it("Transacttion count reduced", async function(){
            expect(await walletContract.getpendingTransaxtion()).to.equal(0);
        })

    });


})