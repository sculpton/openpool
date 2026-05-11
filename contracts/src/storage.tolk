struct PoolStorageNotInit {
    index: uint200
    seqno: uint32
    collection: address
}

struct JettonInfo {
    comissionPercentMul: uint17 // muldiv(amount, fee_percent, 100000);
    minAmount: coins
    ownerWallet: address
    forwardNanoTonLimit: coins
}

struct PoolStorage {
    index: uint200
    seqno: uint32
    collection: address
    publicKey: uint256
    owner: address
    domain: string
    serverLink: string
    availableJettons: map<address, Cell<JettonInfo>>
}

fun PoolStorage.save(self) {
    contract.setData(self.toCell());
}

// struct AdditionalInfo {
//     owner: address
//     forwardNanoTonLimit: coins
//     nanoTonPercentComission: uint64
// }
struct PoolStorageMaybe {
    contractData: slice
}

fun PoolStorageMaybe.isInitialized(self): bool {
    val hasDomain = self.contractData.remainingRefsCount();
    return hasDomain > 1;
}

fun PoolStorageMaybe.parseNotInitialized(self): PoolStorageNotInit {
    return PoolStorageNotInit.fromSlice(self.contractData);
}

fun PoolStorageMaybe.parseInitialized(self): PoolStorage {
    return PoolStorage.fromSlice(self.contractData);
}

fun startLoadingPoolStorage(): PoolStorageMaybe {
    return { contractData: contract.getData().beginParse() };
}
