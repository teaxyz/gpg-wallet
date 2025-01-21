// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { GPGWalletDeployer } from "src/GPGWalletDeployer.sol";
import { GPGWallet } from "src/GPGWalletImpl.sol";
// import { Airdropper } from "src/Airdropper.sol";

contract GPGWalletTest is Test {
    GPGWalletDeployer deployer;
    GPGWallet impl;
    // Airdropper airdropper;
    address eoa = makeAddr("eoa");

    event GPGWalletDeployed(address wallet, uint256 amount);
    event FundsTransferred(address wallet, uint256 amount);

    // to get key ids: gpg --list-keys
    bytes8 ED_KEY_ID = bytes8(0x49CEB217B43F2378);
    bytes8 RSA_KEY_ID = bytes8(0x4C4C3AB789F86A6F);

    // to get pubkey: gpg --export {key id} | xxd -p | tr -d '\n'
    bytes ED_KEY = hex"9833046768354e16092b06010401da470f0101074089ea06d9820134822b9ddaeef1929c50ddfd9bbcf7c0794f3082d864fecb30feb42f5a616368204f62726f6e7420287465612d676574682d7465737429203c7a6f62726f6e7440676d61696c2e636f6d3e88930413160a003b162104c4e971386f7e24899b765c6b49ceb217b43f237805026768354e021b03050b0908070202220206150a09080b020416020301021e07021780000a091049ceb217b43f2378e65600ff538b73b85fc29fe716c0857343ac1efb4ac2864fd346de79f00d0e0f6d6e8e970100cdaf800a4ea1c9fabe8c982a191bff567c16019dad016c06e643b689ff3fd60eb838046768354e120a2b060104019755010501010740cf010ab1e65c0a4560292d4f8faaf2c03b6e115f2482464404d12bed986c8f530301080788780418160a0020162104c4e971386f7e24899b765c6b49ceb217b43f237805026768354e021b0c000a091049ceb217b43f237866a900fe2d50d10d916ced462d925220880b538cc9ab4fde817aa5bb3928d4f2a46003a50100d420071637d56defa999a22bc43bf0b0b179cf288d9643a54e98c13eb346df0a";
    bytes RSA_KEY = hex"99020d04678fd745011000d6a2e19ddb1d378fdf58bd6c231dc7c5d1db60ad5aa8a6cc0c1cf2a8881adeccadbbdfa0148aa32885972d2f02033097a771c9f2b309c12aed7807b084334c1b9238458a692e819bb8a2c9ec40e5ab19055116bf4fe77b8c00f2481131c46645eaffae7ae6d767b9e3aa7eb34f446d21faabc38ec55f0f37accade05fe00e2f7e7ba97a98fb198255a4cd222964d2c0c3f129ce155692d8233f32afb016df1c72c3d9fa7c04f2ff30adebc830dcbdec77c38b2540c0b11dde2a246022ccce7e917fb9fe6b18a3a81e5a7b3be550eefd240fc87261e777e527363d4fd72e84ba6e0138903de95a2177c173f0df97858f202301021b776abb925e70b59e752a0f5b4e374cbf72ed81e8f0ce43ca3b996fc92f68d532de133f77cb2d24b91a70e7a4f9217d31581d871ee7e9107ee178b27d2a31816e845b1f7bc189df648e03a07f4886a0d332e84df9ff81857cda725f762f384ab8984ee29e5cebb676c880945ab7d54c83b92a0dec87d790320e10198c62cd68cc78273b198347d5532c5f4bf14a8c761e81ae97f66f57f0782d6a3d426b482ef93dec7fc3b7f4d08f526a4dc660f19399ec0a1debea7538b900b74d913164f75df383b9a2bfc3b3e526dded8d6bd505e3a68f41629dbc8473d49e2bafa1730aafd71c92284de7563141cc58f2fdcd1815f903ed315ad1483aad5682ef8e88cf21f034c47d92d40ab8398904b0011010001b41f5a616368204f62726f6e74203c7a6f62726f6e7440676d61696c2e636f6d3e89025104130108003b162104fd22037dffd75189a0399b084c4c3ab789f86a6f0502678fd745021b03050b0908070202220206150a09080b020416020301021e07021780000a09104c4c3ab789f86a6fc4050ffe3c79d78ca987329fb699647ef2d7991bcdf42f467fe9532657e7b409dab1032ae96dbcf4315bfa096c5bd4161be10f57e679276ae9e10eb02bed8f5c39a548f695a4f96347de201bb4882d731149c783aa7b0ec4ab92ff595c64527ff86cb9132ea0ec2df6e2170239523639ad4665b0ed48d5dec9967895517f54797d3d8f5c12c952e38cd2002e699d0bdf587b048d75371be233684710c1f06b854d46f18c6308d7b6e1a3230afd2856599c594f50434464541b0e6306d7afdfcaa127832525e65d67f1bb4192ed47fe3c0275fbbc8bf2d73997b12d4ef1c18cd63ca571bf73d6e71e971c5f018acb537ac4d2e4fcdb39de9e78cd1b8a140b9ce703452c6d5c569e25a83b5e9bdd2e3d314557f02b45ff2d3b933d2a5610d14b6f670aeac1c3b75be559bc800533120296fa467297f5c84edcfae1dd34cffce6802e47c7baf1b4a4264768fda65166f7b88bc412144710a849cce0759adbae21aef5f7340933877a42408132f24e37f593fe2ee29287a36bfbef83e5ef028e51958ac55996372a1e5b02ed02b63bfd60bd40af8c9728d3a2527102a9d6b872afbaaf0c4273009496aea5868957b9d37727f57610943491ab96a542aa0387de7796fff0d64aa73fa0d272a79b1543dfdf1f063413b0326a9b90065e3a45a03768cf60b49a9453171a8478b5faea86014ebd43f70253584acc3a83389b964dcbbc7a768d9d8fb9020d04678fd745011000d9b191215c1834fadd6eb0ee86470444ce08a8606fc91bb51507ce634364190116a0eaed2771d22b96b7d5b20b784e49b1ea5d341950c14bacc6b2e62df8d150cdeff991075204ab6014315868551237c247d33cf0d2e66e72ae3c0d173fede1ed7a59c63a1e9d80bbc04de79304625cd05748c0bb773879450e1a7c663838bdb56465ff417cf9c97aa801698baa0bb2a098b24923322dc1e42c34cc8ec3dcd2fda39b43294bc0a91be1c7772b8d71547cc4755d793d2f4c3dfb1abea9ea45a8b9899e2ab763392cf84d5f462adabf9f2a0d9c87db537702aaacbb445a2a91e43b6e5c02b8d877f340434115997846b7a3ae419f1307a2cbcf9c0c85c7733dae540c746ea62aef40493aa1b7b581e7f9e6b63cdfaf8847003429c1bf1e5733a1ec38be7a360f98053b86e43efe1de87735924f5fdf6b4718ef4203d80901039818fad0e68fd435536fde8d569d6c262b571e8e224c959225146b6dfee2734a23122a420bf2f6624b53cc7582e07d0ec1483fb6256bcc2367681ec8ce93ea685bdd3f4539e3e7ef19cfe95dcd23c5c9bc004a9517bbf8142febb02b1f6415e37361b1a3bf0a1f2b47edb1e5457cabe93e71ac97b50ab48a2d276b2ff6e4a13d4a7204ff3f0d36275f0952300f7d88557a74a92ff3c573cc57a419dfb3ad7d0767fee980db6bb1af84573a048a6e1ec7a88b98a8655f7a62a190fa5fb75dfee6070011010001890236041801080020162104fd22037dffd75189a0399b084c4c3ab789f86a6f0502678fd745021b0c000a09104c4c3ab789f86a6fd6101000b5248d88e035b6d0c18777f98e11451dc37cc441840038968ce3d50f183be21056a65f57486ae6b0d23723a70e4beb2e1f9424cd5400936e9398e0193098b39219e183c9d58e333119f9d0d84c376285807e98e3b80501dbf9636b0a05c5150c8086ee4cd5c5c9dae504bebcb0210f394b3daa5962981c7d48036811d2957b02acfdc04d39cb4b3f035969386d547f96f751baa1949b09e4420b4788bd50e270233c58ba61cb5ab63b4ef85ce9f35e183175b1892f506f905944b425e22697cdcde93c20307537ca2e651469f3240dd642e6062952b7bbf4b7c6a57d0b8de20fba9e2fce7cd1c664d529a1a2adb660c4ac696f9c3cdec6018931639ceb314c703e3391ec9e2b65ffba440126b6b2f17c3f98d3c97c5a57f3792e2df940ab6b30da3d51d8daf25a56d1df8026bd38da903849d0dfb654d7e35e46f0a493a3815e03e3bb4070574eda87f39672b198699ead436dacb2cd3a9e45dfaacc051c517267054202458d944932ec9c3845555ae31748bd29967112f9b6768c300e9a566aa0f337510e7fbd94edaa8fbc18f7095bc16847e0cf8be26b805ac9e3a8c33d278b1baee4e6857fcbdaf85744a4914605df28ee4a0d5495af7a604127a9e8b04411999e10926338073c9d4a9bfa89f2bf4e6bd3a3a7319fb788e0551d4be38a38dbcf0767d398ec3d232995b2f814713a12be50409c0a5dcf25a450f0954da453";

    function setUp() public {
        impl = new GPGWallet();
        deployer = new GPGWalletDeployer(address(impl));
        // airdropper = new Airdropper(deployer);
    }

    function testDeployment(bytes8 keyId, uint256 value) public {
        vm.deal(address(this), value);

        vm.expectEmit();
        (address predicted,) = deployer.predictAddress(keyId);
        emit GPGWalletDeployed(predicted, value);

        address wallet = deployer.deploy{value: value}(keyId);
        assert(wallet.code.length > 0);
    }

    function testDeploymentGas() public {
        bytes8 keyId = bytes8(0x1234567890abcdef);
        uint gasBefore = gasleft();
        address wallet = deployer.deploy(keyId);
        // console.log(gasBefore - gasleft());
    }

    function testPredictAddress(bytes8 keyId) public {
        (address predictedBefore, bool deployedBefore) = deployer.predictAddress(keyId);
        address wallet = deployer.deploy(keyId);
        (address predictedAfter, bool deployedAfter) = deployer.predictAddress(keyId);

        assertEq(predictedBefore, wallet);
        assertEq(predictedAfter, wallet);

        assertEq(deployedBefore, false);
        assertEq(deployedAfter, true);
    }

    function testRedeployTransfers() public {
        bytes8 keyId = bytes8(0x1234567890abcdef);
        uint256 amount = 100;

        address wallet = deployer.deploy(keyId);
        assertEq(wallet.balance, 0);

        vm.expectEmit();
        emit FundsTransferred(wallet, amount);
        deployer.deploy{value: amount}(keyId);

        assertEq(wallet.balance, amount);
    }

    function testReadKeyId(bytes8 keyId) public {
        GPGWallet wallet = GPGWallet(payable(deployer.deploy(keyId)));
        bytes32 keyIdFromWallet = wallet.keyId();
        assertEq(keyId, keyIdFromWallet);
    }

    function testReceive() public {
        address walletAddr = deployer.deploy(bytes8(0));
        (bool success,) = walletAddr.call{value: 1}("");
        require(success);
    }

    // add signer with gpg key
    function testAddSigner() public {
        // GPGWallet wallet = GPGWallet(payable(deployer.deploy(RSA_KEY_ID)));
        GPGWallet wallet = GPGWallet(payable(deployer.deploy(ED_KEY_ID)));

        // ED: 0x5af06adaf66d4711487c062b6d213c163973294ff7b0d532289274c566b57bb4
        // RSA: 0x8d36183ef046bbd47bdaf0974f44afb4a4cfe0ec3b63bb1b06338f1bc0deb097
        bytes32 structHash = wallet.getAddSignerStructHash(eoa, 0, 0, bytes32(0));
        // console.logBytes32(structHash);

        // echo "{structHash}" | xxd -r -p | gpg -u {key id} --pinentry-mode loopback --detach-sign | xxd -p | tr -d '\n'
        bytes memory signedED = hex"88750400160a001d162104c4e971386f7e24899b765c6b49ceb217b43f23780502678fee15000a091049ceb217b43f237896b40100f52ea02d10938943be614b37cdfb88e50747369bd0ee9fef045db0ff707ca90f00fe3e44932659240c78c30b880eb479a1e6dfada998d7e6f8868ef00eb4dc3dd000";
        bytes memory signedRSA = hex"89023304000108001d162104fd22037dffd75189a0399b084c4c3ab789f86a6f0502678fede6000a09104c4c3ab789f86a6f65760fff6e9f5a7b79b0a6b703e0b4ced6677461626f0f8dbe59bfd2c3b3b8db53e9077b972c1202567d2a28817e0e4f0b6944808aedb0b430c606c7267679bdb97c3af554684cd36065c84567e0c1e9c4a251f7de89e4e7c167307a29e3a63352243d48fc8d7375b861462e03a66e7be075edd1be586ef7c27bf634b96b9a4945d67504f29b3fa2292de37b6680829cdcd956ba11b571311adaf3598e145eee0ca1612f3a7014005e6403d231129d03240bc6273e835ba227bfad89de650fcc63f392128080a3f01e8b51f9c22ed1b92fdadb9581292e26e582f2017c5e94423a6f804f47f280c881e42a776abf26ddbc4d5b21a23e88bc78c6e1f811a064e5e5d4f77771518d64856eb88fb55b7560441ac1f99abae48bb3cd172e4e002f4297fbf53bec4b131aa9318e5b3811738ba885bd76b99368eb706380603c2161c1e5efb5918662816b86823029aa3f0a7f0159922bcb1188169d4f4ceebd0b274f210a1adbd4f8542800c3df8885e9fd55ec4d9af9637d944d99c68b37e568c5009bdfb63e1e6900bc55996150947b31b18bf2c4a8eea5454c67767f50371a0702ca8e26e8fd74076cf5a0e149d890537af1afd06954dd44892768145ed92dc98012b1ef28101d2694afe511a77e02caedaa9522b0263adbe9cd188222f4dda3db15c699d04148f3706d92484c339c12456f9d39f99d7e2d0b1e4f21152f776d2ccaddc1bc";

        // this verifies on the precompile in tea-geth!
        // console.logBytes(abi.encode(structHash, RSA_KEY_ID, RSA_KEY, signedRSA));
        // console.logBytes(abi.encode(structHash, ED_KEY_ID, ED_KEY, signedED));
    }

    // withdraw all with gpg key

    // execute with gpg sig

    // execute with ecdsa

    // execute with eoa
}
