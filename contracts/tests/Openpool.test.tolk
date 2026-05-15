import "@acton/crypto"
import "@acton/emulation/network"
import "@acton/emulation/testing"
import "@acton/testing/assert"
import "@acton/testing/expect"
import "@acton/tlb/maybe"
import "@acton/types/message"
import "@acton/types/transaction"
import "@contracts/errors"
import "@contracts/messages"
import "@contracts/storage"
import "@wrappers/Openpool.gen"
import "@contracts/common/c5"

fun Expectation<T>.isType<U>(self): void {
    if (self.value is U) {
        return;
    }
    Assert.fail("expect(<actual>).isType(<expected>)", self.location);
}

fun Expectation<TlbAccountState>.hasEqualData(self, data: cell): void {
    if (self.value is TlbAccountStateActive) {
        Assert.equal(
            self.value.stateInit.data,
            data,
            "expect(<actual>).hasEqualData(<expected>): data not equal",
            self.location,
        );

        return;
    }

    Assert.fail(
        "expect(<actual>).hasEqualData(<expected>): type is not TlbAccountStateActive",
        self.location,
    );
}

fun createShardAccount(addr: address, balance: coins, stateInit: StateInit): TlbShardAccount {
    return TlbShardAccount {
        account: (TlbAccountInfo {
            addr: addr,
            storageStat: TlbStorageInfo {
                used: TlbStorageUsed {
                    cells: 0,
                    bits: 0,
                },
                storageExtra: TlbStorageExtraNone {},
                lastPaid: 0,
                duePayment: TlbMaybe.none(),
            },
            storage: TlbAccountStorage {
                lastTransLt: 0,
                balance: TlbCurrencyCollection {
                    grams: balance,
                    other: [],
                },
                state: TlbAccountStateActive { stateInit: stateInit },
            },
        } as TlbAccount).toCell(),
        lastTransHash: 0,
        lastTransLt: 0,
    };
}

struct TestData {
    openpool: Openpool
    owner: Treasury
    notOwner: Treasury
    collection: Treasury
    keypair: KeyPair
    storage: PoolStorage
}

fun setupTest(): TestData {
    val owner = testing.treasury("owner");
    val notOwner = testing.treasury("not_owner");
    val collection = testing.treasury("collection");
    val keypair = crypto.generateKeyPair();

    val storage = PoolStorage {
        index: 123,
        seqno: 111,
        collection: collection.address,
        publicKey: keypair.publicKey,
        owner: owner.address,
        domain: "first",
        serverLink: "https://example.com/api/sendTokens",
        availableJettons: [],
    };

    val contract = Openpool.fromStorage({
        index: storage.index,
        seqno: storage.seqno,
        collection: collection.address,
    });

    return TestData {
        openpool: contract,
        owner: owner,
        notOwner: notOwner,
        collection: collection,
        keypair: keypair,
        storage: storage,
    };
}

fun TestData.contractDataCompare(self) {
    val state = testing.getAccountState(self.openpool.address);

    expect(state).toBeNotNull();
    expect(state!.storage.state).hasEqualData(self.storage.toCell());
}

fun TestData.initialize(self, balance: coins) {
    val stateInit = StateInit {
        fixedPrefixLength: null,
        special: null,
        code: self.openpool.stateInit!.code,
        data: self.storage.toCell(),
        library: null,
    };

    val shardAccount = createShardAccount(self.openpool.address, balance, stateInit);

    testing.setShardAccount(self.openpool.address, shardAccount);
}

get fun `test should not deploy`() {
    val testData = setupTest();

    val initBody = OpenpoolInit {
        publicKey: testData.storage.publicKey,
        owner: testData.storage.owner,
        domain: testData.storage.domain,
        serverLink: testData.storage.serverLink,
        availableJettons: testData.storage.availableJettons,
    };

    val invalidDeploy = net.send(
        testData.notOwner.address,
        createMessage({
            bounce: true,
            value: ton("1000"),
            dest: { stateInit: testData.openpool.stateInit! },
            body: initBody.toCell(),
        }),
    );

    expect(invalidDeploy).toHaveFailedTx({
        from: testData.notOwner.address,
        to: testData.openpool.address,
        exitCode: ERROR_NOT_FROM_COLLECTION,
    });
}

get fun `test should deploy`() {
    val testData = setupTest();

    val initBody = OpenpoolInit {
        publicKey: testData.storage.publicKey,
        owner: testData.storage.owner,
        domain: testData.storage.domain,
        serverLink: testData.storage.serverLink,
        availableJettons: testData.storage.availableJettons,
    };

    val okDeploy = net.send(
        testData.collection.address,
        createMessage({
            bounce: true,
            value: ton("1000"),
            dest: { stateInit: testData.openpool.stateInit! },
            body: initBody.toCell(),
        }),
    );

    expect(okDeploy).toHaveSuccessfulTx({
        from: testData.collection.address,
        to: testData.openpool.address,
    });

    testData.contractDataCompare();
}

get fun `test top up`() {
    val testData = setupTest();

    testData.initialize(ton("0.05"));

    val result = testData.openpool.sendTopUp(testData.storage.owner, 123, { value: ton("1") });

    expect(result).toHaveSuccessfulTx({
        from: testData.owner.address,
        to: testData.openpool.address,
        body: TopUp { queryId: 123 }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test refund: fail - not owner`() {
    val testData = setupTest();

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendRefund(
            testData.notOwner.address,
            123,
            ton("5"),
            { value: ton("1") },
        );

    expect(result).toHaveFailedTx({
        from: testData.notOwner.address,
        to: testData.openpool.address,
        exitCode: ERROR_NOT_FROM_OWNER,
        body: Refund {
            queryId: 123,
            value: ton("5"),
        }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test refund: fail - insufficient funds`() {
    val testData = setupTest();

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendRefund(
            testData.owner.address,
            123,
            ton("5.1"),
            { value: ton("0.05") },
        );

    expect(result).toHaveFailedTx({
        from: testData.owner.address,
        to: testData.openpool.address,
        exitCode: ERROR_INSUFFICIENT_FUNDS,
        body: Refund {
            queryId: 123,
            value: ton("5.1"),
        }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test refund: success`() {
    val testData = setupTest();

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendRefund(
            testData.owner.address,
            123,
            ton("4"),
            { value: ton("0.05") },
        );

    expect(result).toHaveSuccessfulTx({
        from: testData.owner.address,
        to: testData.openpool.address,
        body: Refund {
            queryId: 123,
            value: ton("4"),
        }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test add jetton: fail - not owner`() {
    val testData = setupTest();
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendAddJetton(
            testData.notOwner.address,
            123,
            5,
            50,
            minter,
            ownerWallet,
            1,
            { value: ton("1") },
        );

    expect(result).toHaveFailedTx({
        from: testData.notOwner.address,
        to: testData.openpool.address,
        exitCode: ERROR_NOT_FROM_OWNER,
        body: AddJetton {
            queryId: 123,
            comissionPercentMul: 5,
            minAmount: 50,
            minter: minter,
            ownerWallet: ownerWallet,
            forwardNanoTonLimit: 1,
        }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test add jetton: success`() {
    var testData = setupTest();
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendAddJetton(
            testData.owner.address,
            123,
            5,
            50,
            minter,
            ownerWallet,
            1,
            { value: ton("1") },
        );

    expect(result).toHaveSuccessfulTx({
        from: testData.owner.address,
        to: testData.openpool.address,
        body: AddJetton {
            queryId: 123,
            comissionPercentMul: 5,
            minAmount: 50,
            minter: minter,
            ownerWallet: ownerWallet,
            forwardNanoTonLimit: 1,
        }.toCell(),
    });

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 50,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.contractDataCompare();
}

get fun `test update jetton: fail - not owner`() {
    var testData = setupTest();
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 50,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendAddJetton(
            testData.notOwner.address,
            123,
            5,
            150,
            minter,
            ownerWallet,
            1,
            { value: ton("1") },
        );

    expect(result).toHaveFailedTx({
        from: testData.notOwner.address,
        to: testData.openpool.address,
        exitCode: ERROR_NOT_FROM_OWNER,
        body: AddJetton {
            queryId: 123,
            comissionPercentMul: 5,
            minAmount: 150,
            minter: minter,
            ownerWallet: ownerWallet,
            forwardNanoTonLimit: 1,
        }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test update jetton: success`() {
    var testData = setupTest();
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 50,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendAddJetton(
            testData.owner.address,
            123,
            5,
            150,
            minter,
            ownerWallet,
            1,
            { value: ton("0.05") },
        );

    expect(result).toHaveSuccessfulTx({
        from: testData.owner.address,
        to: testData.openpool.address,
        body: AddJetton {
            queryId: 123,
            comissionPercentMul: 5,
            minAmount: 150,
            minter: minter,
            ownerWallet: ownerWallet,
            forwardNanoTonLimit: 1,
        }.toCell(),
    });

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 150,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.contractDataCompare();
}

get fun `test remove jetton: fail - not owner`() {
    var testData = setupTest();
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 50,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendRemoveJetton(
            testData.notOwner.address,
            123,
            minter,
            { value: ton("1") },
        );

    expect(result).toHaveFailedTx({
        from: testData.notOwner.address,
        to: testData.openpool.address,
        exitCode: ERROR_NOT_FROM_OWNER,
        body: RemoveJetton {
            queryId: 123,
            minter: minter,
        }.toCell(),
    });

    testData.contractDataCompare();
}

get fun `test remove jetton: success`() {
    var testData = setupTest();
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 50,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("5"));

    val result = testData
        .openpool
        .sendRemoveJetton(
            testData.owner.address,
            123,
            minter,
            { value: ton("0.05") },
        );

    expect(result).toHaveSuccessfulTx({
        from: testData.owner.address,
        to: testData.openpool.address,
        body: RemoveJetton {
            queryId: 123,
            minter: minter,
        }.toCell(),
    });

    testData.storage.availableJettons.delete(minter);

    testData.contractDataCompare();
}

fun createSendTokensExternal(op: uint32 = SEND_TOKENS_EXTERNAL): SendTokensExternal {
    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    return SendTokensExternal {
        seqno: 111,
        askInfo: AskToTransferInfo {
            queryId: 123,
            jettonMinter: minter,
            jettonWallet: ownerWallet,
        }.toCell(),
        jettonInfo: JettonMsg {
            seqno: 1,
            validUntil: blockchain.now() + 3600,
            jettonAmount: 100,
            comissionPercentMul: 5,
            forwardNanoTonAmount: 1,
            customPayload: null,
            forwardPayload: null,
        }.toCell(),
        op: op,
        extraActions: null,
    };
}

fun rejectExternalMessage(testData: TestData, body: cell, error: int) {
    val result = testData.openpool.sendAnyExternal(body);

    expect(result).toBeNotAccepted();
    expect(result).toHaveExternalVmExitCode(error);
}

fun runThroughAllOptions(fn: (uint32) -> ()) {
    val opcodes: array<uint32> = [SEND_TOKENS_EXTERNAL, BURN_TOKENS_EXTERNAL];
    var i = 0;

    while (i < opcodes.size()) {
        fn(opcodes.get(i));
        i += 1;
    }
}

get fun `test external: not init`() {
    var testData = setupTest();
    val data = PoolStorageNotInit {
        index: testData.storage.index,
        seqno: testData.storage.seqno,
        collection: testData.storage.collection,
    }.toCell();

    val stateInit = StateInit {
        fixedPrefixLength: null,
        special: null,
        code: testData.openpool.stateInit!.code,
        data: data,
        library: null,
    };

    val shardAccount = createShardAccount(testData.openpool.address, ton("1"), stateInit);

    testing.setShardAccount(testData.openpool.address, shardAccount);

    val state = testing.getAccountState(testData.openpool.address);

    expect(state).toBeNotNull();
    expect(state!.storage.state).hasEqualData(data);

    runThroughAllOptions(fun(op) {
        val msg = createSendTokensExternal(op);

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_NOT_INITIALIZED);

        return ();
    });
}

get fun `test external: insufficient funds`() {
    var testData = setupTest();

    testData.initialize(ton("0.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        val msg = createSendTokensExternal(op);

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_INSUFFICIENT_FUNDS);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: invalid signature`() {
    var testData = setupTest();

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    val keypair = crypto.generateKeyPair();

    runThroughAllOptions(fun(op) {
        val msg = createSendTokensExternal(op);

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_INVALID_SIGNATURE);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: seqno not equal`() {
    var testData = setupTest();

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);

        msg.seqno += 1;

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_INVALID_SEQNO);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: expired`() {
    var testData = setupTest();

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);

        var jettonInfo = msg.jettonInfo.load();

        jettonInfo.validUntil = blockchain.now() - 1;
        msg.jettonInfo = jettonInfo.toCell();

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_EXPIRED);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: jetton empty`() {
    var testData = setupTest();

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_JETTON_NOT_FOUND);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: not found jetton`() {
    var testData = setupTest();

    val minter = randomAddress("other-minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_JETTON_NOT_FOUND);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: not equal comission`() {
    var testData = setupTest();

    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);
        var jettonInfo = msg.jettonInfo.load();

        jettonInfo.comissionPercentMul = 4;
        msg.jettonInfo = jettonInfo.toCell();

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_JETTON_NOT_EQUAL_COMMISION);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: unavailable message`() {
    var testData = setupTest();

    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);

        msg.op = 11011;

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_INVALID_MESSAGE_OPERATION);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: jetton amount is less`() {
    var testData = setupTest();

    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    runThroughAllOptions(fun(op) {
        var msg = createSendTokensExternal(op);
        var jettonInfo = msg.jettonInfo.load();

        jettonInfo.jettonAmount = 99;

        msg.jettonInfo = jettonInfo.toCell();

        val body = beginCell()
            .storeSlice(msg.toCell().beginParse())
            .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
            .endCell();

        rejectExternalMessage(testData, body, ERROR_JETTON_LESS_THAN_MINIMUM);

        return ();
    });

    testData.contractDataCompare();
}

get fun `test external: forward ton greater than maximum`() {
    var testData = setupTest();

    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    var msg = createSendTokensExternal();
    var jettonInfo = msg.jettonInfo.load();

    jettonInfo.forwardNanoTonAmount = 2;

    msg.jettonInfo = jettonInfo.toCell();

    val body = beginCell()
        .storeSlice(msg.toCell().beginParse())
        .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
        .endCell();

    rejectExternalMessage(testData, body, ERROR_JETTON_NANO_TON_GREAT_THAN_MAXIMUM);

    testData.contractDataCompare();
}

get fun `test external: transfer with actions success`() {
    var testData = setupTest();

    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    var msg = createSendTokensExternal();

    msg.extraActions = OutActionWithSendMessageOnly {
        prev: createEmptyCell(),
        sendMode: SEND_MODE_IGNORE_ERRORS,
        outMsg: createMessage({
            bounce: false,
            value: ton("0.01"),
            dest: testData.storage.owner,
            body: beginCell().storeUint(0, 32).storeSlice("SOME TEXT MESSAGE".literalSlice()),
        }).messageCell,
    }.toCell() as OutActionsCell;

    val body = beginCell()
        .storeSlice(msg.toCell().beginParse())
        .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
        .endCell();

    val result = testData.openpool.sendAnyExternal(body);

    expect(result).toBeAccepted();

    val txs = result.unwrap();

    expect(txs).toHaveTx<AskToTransferByPool>({
        from: testData.openpool.address,
        to: ownerWallet,
        body: AskToTransferByPool {
            queryId: msg.askInfo.load().queryId,
            sendExcessesTo: testData.openpool.address,
            comissionWallet: ownerWallet,
            poolInfo: PoolInfo {
                index: testData.storage.index,
                collection: testData.storage.collection,
            }.toCell(),
            jettonInfo: msg.jettonInfo,
        }.toCell(),
    });

    expect(txs).toHaveTx({
        from: testData.openpool.address,
        to: testData.storage.owner,
        body: beginCell().storeUint(0, 32).storeSlice("SOME TEXT MESSAGE".literalSlice()).endCell(),
    });

    testData.storage.seqno += 1;
    testData.contractDataCompare();
}

get fun `test external: burn with actions success`() {
    var testData = setupTest();

    val minter = randomAddress("minter");
    val ownerWallet = randomAddress("owner_wallet");

    testData
        .storage
        .availableJettons
        .set(
            minter,
            JettonInfo {
                comissionPercentMul: 5,
                minAmount: 100,
                ownerWallet: ownerWallet,
                forwardNanoTonLimit: 1,
            }.toCell(),
        );

    testData.initialize(ton("1.05"));

    testData.contractDataCompare();

    var msg = createSendTokensExternal(BURN_TOKENS_EXTERNAL);

    msg.extraActions = OutActionWithSendMessageOnly {
        prev: createEmptyCell(),
        sendMode: SEND_MODE_IGNORE_ERRORS,
        outMsg: createMessage({
            bounce: false,
            value: ton("0.01"),
            dest: testData.storage.owner,
            body: beginCell().storeUint(0, 32).storeSlice("SOME TEXT MESSAGE".literalSlice()),
        }).messageCell,
    }.toCell() as OutActionsCell;

    val body = beginCell()
        .storeSlice(msg.toCell().beginParse())
        .storeSlice(crypto.sign(testData.keypair.privateKey, msg.toCell()))
        .endCell();

    val result = testData.openpool.sendAnyExternal(body);

    expect(result).toBeAccepted();

    val txs = result.unwrap();

    expect(txs).toHaveTx<AskToBurnByPool>({
        from: testData.openpool.address,
        to: ownerWallet,
        body: AskToBurnByPool {
            queryId: msg.askInfo.load().queryId,
            sendExcessesTo: testData.openpool.address,
            comissionWallet: ownerWallet,
            poolInfo: PoolInfo {
                index: testData.storage.index,
                collection: testData.storage.collection,
            }.toCell(),
            jettonInfo: msg.jettonInfo,
        }.toCell(),
    });

    expect(txs).toHaveTx({
        from: testData.openpool.address,
        to: testData.storage.owner,
        body: beginCell().storeUint(0, 32).storeSlice("SOME TEXT MESSAGE".literalSlice()).endCell(),
    });

    testData.storage.seqno += 1;
    testData.contractDataCompare();
}
