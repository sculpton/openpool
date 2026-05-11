import "@stdlib/gas-payments"
import "@contracts/messages"
import "@contracts/storage"
import "errors"
import "common/c5"

contract Openpool {
    author: "Shyhiev Shamil"
    version: "1.0.0"
    description: "Simple openpool realization for gasless usage"
    storage: PoolStorage
    incomingMessages: AllowedInternalMessage
    incomingExternal: slice
    storageAtDeployment: PoolStorageNotInit
}

const SIZE_SIGNATURE = 512
const MIN_BALANCE_FOR_MESSAGE = 1000000000 //ton("1") // TODO: ???
const VALUE_FOR_MESSAGE = ton("0.05") // TODO: ???

type AllowedInternalMessage = TopUp | Refund | AddJetton | RemoveJetton

fun onInternalMessage(in: InMessage) {
    val cs = startLoadingPoolStorage();

    if (!cs.isInitialized()) {
        val msg = lazy OpenpoolInit.fromSlice(
            in.body,
            { throwIfOpcodeDoesNotMatch: ERROR_INVALID_MESSAGE_OPERATION },
        );

        val st = cs.parseNotInitialized();

        assert (in.senderAddress == st.collection) throw ERROR_NOT_FROM_COLLECTION;

        val storage = PoolStorage {
            index: st.index,
            seqno: st.seqno,
            collection: st.collection,
            publicKey: msg.publicKey,
            owner: msg.owner,
            domain: msg.domain,
            serverLink: msg.serverLink,
            availableJettons: msg.availableJettons,
        };

        storage.save();

        return;
    }
    var storage = cs.parseInitialized();

    val msg = lazy AllowedInternalMessage.fromSlice(
        in.body,
        { throwIfOpcodeDoesNotMatch: ERROR_INVALID_MESSAGE_OPERATION },
    );

    match (msg) {
        TopUp => {
            return;
        }
        Refund => {
            assert (in.senderAddress == storage.owner) throw ERROR_NOT_FROM_OWNER;
            // TODO: add storage fee calculation
            assert (
                contract.getOriginalBalance() >= MIN_BALANCE_FOR_MESSAGE + msg.value
            ) throw ERROR_INSUFFICIENT_FUNDS;
            val balance = contract.getOriginalBalance() - MIN_BALANCE_FOR_MESSAGE - msg.value;

            val outMsg = createMessage({
                bounce: false,
                value: balance,
                dest: storage.owner,
                body: RefundNotification { queryId: msg.queryId },
            });

            outMsg.send(SEND_MODE_IGNORE_ERRORS);
        }
        AddJetton => {
            assert (in.senderAddress == storage.owner) throw ERROR_NOT_FROM_OWNER;

            storage
                .availableJettons
                .set(
                    msg.minter,
                    JettonInfo {
                        comissionPercentMul: msg.comissionPercentMul,
                        minAmount: msg.minAmount,
                        ownerWallet: msg.ownerWallet,
                        forwardNanoTonLimit: msg.forwardNanoTonLimit,
                    }.toCell(),
                );

            storage.save();
        }
        RemoveJetton => {
            assert (in.senderAddress == storage.owner) throw ERROR_NOT_FROM_OWNER;

            storage.availableJettons.delete(msg.minter);

            storage.save();
        }
    }
}

fun onExternalMessage(inMsgBody: slice) {
    val cs = startLoadingPoolStorage();

    assert (cs.isInitialized()) throw ERROR_NOT_INITIALIZED;
    assert (
        contract.getOriginalBalance() >= MIN_BALANCE_FOR_MESSAGE
    ) throw ERROR_INSUFFICIENT_FUNDS;

    var storage = cs.parseInitialized();

    var signature = inMsgBody.getLastBits(SIZE_SIGNATURE);
    var signedSlice = inMsgBody.removeLastBits(SIZE_SIGNATURE);

    var msg = lazy SendTokensExternal.fromSlice(signedSlice);

    assert (
        isSignatureValid(signedSlice.hash(), signature, storage.publicKey)
    ) throw ERROR_INVALID_SIGNATURE;
    assert (msg.seqno == storage.seqno) throw ERROR_INVALID_SEQNO;

    val jettonMsg = lazy msg.jettonInfo.load();

    assert (jettonMsg.validUntil > blockchain.now()) throw ERROR_EXPIRED;

    assert (!storage.availableJettons.isEmpty()) throw ERROR_JETTON_NOT_FOUND;

    val askInfo = lazy msg.askInfo.load();

    val jettonStorage = lazy storage
        .availableJettons
        .mustGet(
            askInfo.jettonMinter,
            ERROR_JETTON_NOT_FOUND,
        )
        .load();

    assert (jettonMsg.jettonAmount >= jettonStorage.minAmount) throw ERROR_JETTON_LESS_THAN_MINIMUM;
    assert (
        jettonStorage.comissionPercentMul == jettonMsg.comissionPercentMul
    ) throw ERROR_JETTON_NOT_EQUAL_COMMISION;

    match (msg.op) {
        SEND_TOKENS_EXTERNAL => {
            assert (
                jettonStorage.forwardNanoTonLimit >= jettonMsg.forwardNanoTonAmount
            ) throw ERROR_JETTON_NANO_TON_GREAT_THAN_MAXIMUM;

            acceptExternalMessage();

            val msg_ = createMessage({
                dest: askInfo.jettonWallet,
                bounce: true, // Подумать, тк деньги бы вернуть
                value: VALUE_FOR_MESSAGE + jettonMsg.forwardNanoTonAmount,
                body: AskToTransferByPool {
                    queryId: askInfo.queryId,
                    sendExcessesTo: contract.getAddress(),
                    comissionWallet: jettonStorage.ownerWallet,
                    poolInfo: PoolInfo {
                        index: storage.index,
                        collection: storage.collection,
                    }.toCell(),
                    jettonInfo: msg.jettonInfo,
                },
            });
            msg_.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        BURN_TOKENS_EXTERNAL => {
            acceptExternalMessage();

            val msg_ = createMessage({
                dest: askInfo.jettonWallet,
                bounce: true, // Подумать, тк деньги бы вернуть
                value: VALUE_FOR_MESSAGE,
                body: AskToBurnByPool {
                    queryId: askInfo.queryId,
                    sendExcessesTo: contract.getAddress(),
                    comissionWallet: jettonStorage.ownerWallet,
                    poolInfo: PoolInfo {
                        index: storage.index,
                        collection: storage.collection,
                    }.toCell(),
                    jettonInfo: msg.jettonInfo,
                },
            });
            msg_.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        else => {
            throw ERROR_INVALID_MESSAGE_OPERATION;
        }
    }

    storage.seqno += 1;
    storage.save();

    if (msg.extraActions != null) {
        // TODO: optimize it. msg must be first
        updateC5(msg.extraActions.verifyC5Actions(true));
    }
}
