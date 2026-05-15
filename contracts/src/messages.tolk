import "storage"
import "common/c5"

const SEND_TOKENS_EXTERNAL = 0xb3f8dc75
const BURN_TOKENS_EXTERNAL = 0xe488ddb5

// ---- Receive External ----
// + 512 bit - signature
struct SendTokensExternal {
    seqno: uint32
    askInfo: Cell<AskToTransferInfo>
    jettonInfo: Cell<JettonMsg>
    op: uint32
    @abi.clientType(Cell<OutActionWithSendMessageOnly>?)
    extraActions: OutActionsCell?
}

struct AskToTransferInfo {
    queryId: uint64
    jettonMinter: address
    jettonWallet: address
}

// ---- Receive Internal ----
struct (0x00000000) OpenpoolInit {
    publicKey: uint256
    owner: address
    domain: string
    serverLink: string
    availableJettons: map<address, Cell<JettonInfo>>
}

struct (0xd53276db) TopUp {
    queryId: uint64
}

struct (0x06bbb2f8) Refund {
    queryId: uint64
    value: coins
}

struct (0x10397b4c) AddJetton {
    queryId: uint64
    comissionPercentMul: uint17
    minAmount: coins
    minter: address
    ownerWallet: address
    forwardNanoTonLimit: coins
}

struct (0x37191ccb) RemoveJetton {
    queryId: uint64
    minter: address
}

// ---- Send ----
struct (0xa45306a9) AskToTransferByPool {
    queryId: uint64
    sendExcessesTo: address
    comissionWallet: address
    poolInfo: Cell<PoolInfo>
    jettonInfo: Cell<JettonMsg>
}

struct (0xbc878ae9) AskToBurnByPool {
    queryId: uint64
    sendExcessesTo: address
    comissionWallet: address
    poolInfo: Cell<PoolInfo>
    jettonInfo: Cell<JettonMsg>
}

// + 512 bit - signature
struct JettonMsg {
    seqno: uint32
    validUntil: uint32
    jettonAmount: coins
    comissionPercentMul: uint17 // muldiv(amount, fee_percent, 100000);
    forwardNanoTonAmount: coins
    customPayload: cell?
    forwardPayload: cell?
}

struct PoolInfo {
    index: uint200
    collection: address
}

struct (0x7362d09c) RefundNotification {
    queryId: uint64
}
