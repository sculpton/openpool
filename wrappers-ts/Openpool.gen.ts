// AUTO-GENERATED, do not edit
// It's a TypeScript wrapper for a Openpool contract in Tolk.
/* eslint-disable */

import * as c from '@ton/core';
import { beginCell, ContractProvider, Sender, SendMode } from '@ton/core';

// ————————————————————————————————————————————
//   predefined types and functions
//

type StoreCallback<T> = (obj: T, b: c.Builder) => void
type LoadCallback<T> = (s: c.Slice) => T

export type CellRef<T> = {
    ref: T
}

function makeCellFrom<T>(self: T, storeFn_T: StoreCallback<T>): c.Cell {
    let b = beginCell();
    storeFn_T(self, b);
    return b.endCell();
}

function loadAndCheckPrefix32(s: c.Slice, expected: number, structName: string): void {
    let prefix = s.loadUint(32);
    if (prefix !== expected) {
        throw new Error(`Incorrect prefix for '${structName}': expected 0x${expected.toString(16).padStart(8, '0')}, got 0x${prefix.toString(16).padStart(8, '0')}`);
    }
}

function lookupPrefix(s: c.Slice, expected: number, prefixLen: number): boolean {
    return s.remainingBits >= prefixLen && s.preloadUint(prefixLen) === expected;
}

function throwNonePrefixMatch(fieldPath: string): never {
    throw new Error(`Incorrect prefix for '${fieldPath}': none of variants matched`);
}

function storeCellRef<T>(cell: CellRef<T>, b: c.Builder, storeFn_T: StoreCallback<T>): void {
    let b_ref = c.beginCell();
    storeFn_T(cell.ref, b_ref);
    b.storeRef(b_ref.endCell());
}

function loadCellRef<T>(s: c.Slice, loadFn_T: LoadCallback<T>): CellRef<T> {
    let s_ref = s.loadRef().beginParse();
    return { ref: loadFn_T(s_ref) };
}

function storeTolkNullable<T>(v: T | null, b: c.Builder, storeFn_T: StoreCallback<T>): void {
    if (v === null) {
        b.storeUint(0, 1);
    } else {
        b.storeUint(1, 1);
        storeFn_T(v, b);
    }
}

function createDictionaryValue<V>(loadFn_V: LoadCallback<V>, storeFn_V: StoreCallback<V>): c.DictionaryValue<V> {
    return {
        serialize(self: V, b: c.Builder) {
            storeFn_V(self, b);
        },
        parse(s: c.Slice): V {
            const value = loadFn_V(s);
            s.endParse();
            return value;
        }
    }
}

// ————————————————————————————————————————————
//   parse get methods result from a TVM stack
//

class StackReader {
    constructor(private tuple: c.TupleItem[]) {
    }

    static fromGetMethod(expectedN: number, getMethodResult: { stack: c.TupleReader }): StackReader {
        let tuple = [] as c.TupleItem[];
        while (getMethodResult.stack.remaining) {
            tuple.push(getMethodResult.stack.pop());
        }
        if (tuple.length !== expectedN) {
            throw new Error(`expected ${expectedN} stack width, got ${tuple.length}`);
        }
        return new StackReader(tuple);
    }

    private popExpecting<ItemT>(itemType: string): ItemT {
        const item = this.tuple.shift();
        if (item?.type === itemType) {
            return item as ItemT;
        }
        throw new Error(`not '${itemType}' on a stack`);
    }

    private popCellLike(): c.Cell {
        const item = this.tuple.shift();
        if (item && (item.type === 'cell' || item.type === 'slice' || item.type === 'builder')) {
            return item.cell;
        }
        throw new Error(`not cell/slice on a stack`);
    }

    readBigInt(): bigint {
        return this.popExpecting<c.TupleItemInt>('int').value;
    }

    readBoolean(): boolean {
        return this.popExpecting<c.TupleItemInt>('int').value !== 0n;
    }

    readCell(): c.Cell {
        return this.popCellLike();
    }

    readSlice(): c.Slice {
        return this.popCellLike().beginParse();
    }
}

// ————————————————————————————————————————————
//   auto-generated serializers to/from cells
//

type coins = bigint

type uint17 = bigint
type uint32 = bigint
type uint64 = bigint
type uint200 = bigint
type uint256 = bigint

/**
 > struct (0xd53276db) TopUp {
 >     queryId: uint64
 > }
 */
export interface TopUp {
    readonly $: 'TopUp'
    queryId: uint64
}

export const TopUp = {
    PREFIX: 0xd53276db,

    create(args: {
        queryId: uint64
    }): TopUp {
        return {
            $: 'TopUp',
            ...args
        }
    },
    fromSlice(s: c.Slice): TopUp {
        loadAndCheckPrefix32(s, 0xd53276db, 'TopUp');
        return {
            $: 'TopUp',
            queryId: s.loadUintBig(64),
        }
    },
    store(self: TopUp, b: c.Builder): void {
        b.storeUint(0xd53276db, 32);
        b.storeUint(self.queryId, 64);
    },
    toCell(self: TopUp): c.Cell {
        return makeCellFrom<TopUp>(self, TopUp.store);
    }
}

/**
 > struct (0x06bbb2f8) Refund {
 >     queryId: uint64
 >     value: coins
 > }
 */
export interface Refund {
    readonly $: 'Refund'
    queryId: uint64
    value: coins
}

export const Refund = {
    PREFIX: 0x06bbb2f8,

    create(args: {
        queryId: uint64
        value: coins
    }): Refund {
        return {
            $: 'Refund',
            ...args
        }
    },
    fromSlice(s: c.Slice): Refund {
        loadAndCheckPrefix32(s, 0x06bbb2f8, 'Refund');
        return {
            $: 'Refund',
            queryId: s.loadUintBig(64),
            value: s.loadCoins(),
        }
    },
    store(self: Refund, b: c.Builder): void {
        b.storeUint(0x06bbb2f8, 32);
        b.storeUint(self.queryId, 64);
        b.storeCoins(self.value);
    },
    toCell(self: Refund): c.Cell {
        return makeCellFrom<Refund>(self, Refund.store);
    }
}

/**
 > struct (0x10397b4c) AddJetton {
 >     queryId: uint64
 >     comissionPercentMul: uint17
 >     minAmount: coins
 >     minter: address
 >     ownerWallet: address
 >     forwardNanoTonLimit: coins
 > }
 */
export interface AddJetton {
    readonly $: 'AddJetton'
    queryId: uint64
    comissionPercentMul: uint17
    minAmount: coins
    minter: c.Address
    ownerWallet: c.Address
    forwardNanoTonLimit: coins
}

export const AddJetton = {
    PREFIX: 0x10397b4c,

    create(args: {
        queryId: uint64
        comissionPercentMul: uint17
        minAmount: coins
        minter: c.Address
        ownerWallet: c.Address
        forwardNanoTonLimit: coins
    }): AddJetton {
        return {
            $: 'AddJetton',
            ...args
        }
    },
    fromSlice(s: c.Slice): AddJetton {
        loadAndCheckPrefix32(s, 0x10397b4c, 'AddJetton');
        return {
            $: 'AddJetton',
            queryId: s.loadUintBig(64),
            comissionPercentMul: s.loadUintBig(17),
            minAmount: s.loadCoins(),
            minter: s.loadAddress(),
            ownerWallet: s.loadAddress(),
            forwardNanoTonLimit: s.loadCoins(),
        }
    },
    store(self: AddJetton, b: c.Builder): void {
        b.storeUint(0x10397b4c, 32);
        b.storeUint(self.queryId, 64);
        b.storeUint(self.comissionPercentMul, 17);
        b.storeCoins(self.minAmount);
        b.storeAddress(self.minter);
        b.storeAddress(self.ownerWallet);
        b.storeCoins(self.forwardNanoTonLimit);
    },
    toCell(self: AddJetton): c.Cell {
        return makeCellFrom<AddJetton>(self, AddJetton.store);
    }
}

/**
 > struct (0x37191ccb) RemoveJetton {
 >     queryId: uint64
 >     minter: address
 > }
 */
export interface RemoveJetton {
    readonly $: 'RemoveJetton'
    queryId: uint64
    minter: c.Address
}

export const RemoveJetton = {
    PREFIX: 0x37191ccb,

    create(args: {
        queryId: uint64
        minter: c.Address
    }): RemoveJetton {
        return {
            $: 'RemoveJetton',
            ...args
        }
    },
    fromSlice(s: c.Slice): RemoveJetton {
        loadAndCheckPrefix32(s, 0x37191ccb, 'RemoveJetton');
        return {
            $: 'RemoveJetton',
            queryId: s.loadUintBig(64),
            minter: s.loadAddress(),
        }
    },
    store(self: RemoveJetton, b: c.Builder): void {
        b.storeUint(0x37191ccb, 32);
        b.storeUint(self.queryId, 64);
        b.storeAddress(self.minter);
    },
    toCell(self: RemoveJetton): c.Cell {
        return makeCellFrom<RemoveJetton>(self, RemoveJetton.store);
    }
}

/**
 > struct (0xa45306a9) AskToTransferByPool {
 >     queryId: uint64
 >     sendExcessesTo: address
 >     comissionWallet: address
 >     poolInfo: Cell<PoolInfo>
 >     jettonInfo: Cell<JettonMsg>
 > }
 */
export interface AskToTransferByPool {
    readonly $: 'AskToTransferByPool'
    queryId: uint64
    sendExcessesTo: c.Address
    comissionWallet: c.Address
    poolInfo: CellRef<PoolInfo>
    jettonInfo: CellRef<JettonMsg>
}

export const AskToTransferByPool = {
    PREFIX: 0xa45306a9,

    create(args: {
        queryId: uint64
        sendExcessesTo: c.Address
        comissionWallet: c.Address
        poolInfo: CellRef<PoolInfo>
        jettonInfo: CellRef<JettonMsg>
    }): AskToTransferByPool {
        return {
            $: 'AskToTransferByPool',
            ...args
        }
    },
    fromSlice(s: c.Slice): AskToTransferByPool {
        loadAndCheckPrefix32(s, 0xa45306a9, 'AskToTransferByPool');
        return {
            $: 'AskToTransferByPool',
            queryId: s.loadUintBig(64),
            sendExcessesTo: s.loadAddress(),
            comissionWallet: s.loadAddress(),
            poolInfo: loadCellRef<PoolInfo>(s, PoolInfo.fromSlice),
            jettonInfo: loadCellRef<JettonMsg>(s, JettonMsg.fromSlice),
        }
    },
    store(self: AskToTransferByPool, b: c.Builder): void {
        b.storeUint(0xa45306a9, 32);
        b.storeUint(self.queryId, 64);
        b.storeAddress(self.sendExcessesTo);
        b.storeAddress(self.comissionWallet);
        storeCellRef<PoolInfo>(self.poolInfo, b, PoolInfo.store);
        storeCellRef<JettonMsg>(self.jettonInfo, b, JettonMsg.store);
    },
    toCell(self: AskToTransferByPool): c.Cell {
        return makeCellFrom<AskToTransferByPool>(self, AskToTransferByPool.store);
    }
}

/**
 > struct (0xbc878ae9) AskToBurnByPool {
 >     queryId: uint64
 >     sendExcessesTo: address
 >     comissionWallet: address
 >     poolInfo: Cell<PoolInfo>
 >     jettonInfo: Cell<JettonMsg>
 > }
 */
export interface AskToBurnByPool {
    readonly $: 'AskToBurnByPool'
    queryId: uint64
    sendExcessesTo: c.Address
    comissionWallet: c.Address
    poolInfo: CellRef<PoolInfo>
    jettonInfo: CellRef<JettonMsg>
}

export const AskToBurnByPool = {
    PREFIX: 0xbc878ae9,

    create(args: {
        queryId: uint64
        sendExcessesTo: c.Address
        comissionWallet: c.Address
        poolInfo: CellRef<PoolInfo>
        jettonInfo: CellRef<JettonMsg>
    }): AskToBurnByPool {
        return {
            $: 'AskToBurnByPool',
            ...args
        }
    },
    fromSlice(s: c.Slice): AskToBurnByPool {
        loadAndCheckPrefix32(s, 0xbc878ae9, 'AskToBurnByPool');
        return {
            $: 'AskToBurnByPool',
            queryId: s.loadUintBig(64),
            sendExcessesTo: s.loadAddress(),
            comissionWallet: s.loadAddress(),
            poolInfo: loadCellRef<PoolInfo>(s, PoolInfo.fromSlice),
            jettonInfo: loadCellRef<JettonMsg>(s, JettonMsg.fromSlice),
        }
    },
    store(self: AskToBurnByPool, b: c.Builder): void {
        b.storeUint(0xbc878ae9, 32);
        b.storeUint(self.queryId, 64);
        b.storeAddress(self.sendExcessesTo);
        b.storeAddress(self.comissionWallet);
        storeCellRef<PoolInfo>(self.poolInfo, b, PoolInfo.store);
        storeCellRef<JettonMsg>(self.jettonInfo, b, JettonMsg.store);
    },
    toCell(self: AskToBurnByPool): c.Cell {
        return makeCellFrom<AskToBurnByPool>(self, AskToBurnByPool.store);
    }
}

/**
 > struct JettonMsg {
 >     seqno: uint32
 >     validUntil: uint32
 >     jettonAmount: coins
 >     comissionPercentMul: uint17
 >     forwardNanoTonAmount: coins
 >     customPayload: cell?
 >     forwardPayload: cell?
 > }
 */
export interface JettonMsg {
    readonly $: 'JettonMsg'
    seqno: uint32
    validUntil: uint32
    jettonAmount: coins
    comissionPercentMul: uint17
    forwardNanoTonAmount: coins
    customPayload: c.Cell | null
    forwardPayload: c.Cell | null
}

export const JettonMsg = {
    create(args: {
        seqno: uint32
        validUntil: uint32
        jettonAmount: coins
        comissionPercentMul: uint17
        forwardNanoTonAmount: coins
        customPayload: c.Cell | null
        forwardPayload: c.Cell | null
    }): JettonMsg {
        return {
            $: 'JettonMsg',
            ...args
        }
    },
    fromSlice(s: c.Slice): JettonMsg {
        return {
            $: 'JettonMsg',
            seqno: s.loadUintBig(32),
            validUntil: s.loadUintBig(32),
            jettonAmount: s.loadCoins(),
            comissionPercentMul: s.loadUintBig(17),
            forwardNanoTonAmount: s.loadCoins(),
            customPayload: s.loadBoolean() ? s.loadRef() : null,
            forwardPayload: s.loadBoolean() ? s.loadRef() : null,
        }
    },
    store(self: JettonMsg, b: c.Builder): void {
        b.storeUint(self.seqno, 32);
        b.storeUint(self.validUntil, 32);
        b.storeCoins(self.jettonAmount);
        b.storeUint(self.comissionPercentMul, 17);
        b.storeCoins(self.forwardNanoTonAmount);
        storeTolkNullable<c.Cell>(self.customPayload, b,
            (v,b) => b.storeRef(v)
        );
        storeTolkNullable<c.Cell>(self.forwardPayload, b,
            (v,b) => b.storeRef(v)
        );
    },
    toCell(self: JettonMsg): c.Cell {
        return makeCellFrom<JettonMsg>(self, JettonMsg.store);
    }
}

/**
 > struct PoolInfo {
 >     index: uint200
 >     collection: address
 > }
 */
export interface PoolInfo {
    readonly $: 'PoolInfo'
    index: uint200
    collection: c.Address
}

export const PoolInfo = {
    create(args: {
        index: uint200
        collection: c.Address
    }): PoolInfo {
        return {
            $: 'PoolInfo',
            ...args
        }
    },
    fromSlice(s: c.Slice): PoolInfo {
        return {
            $: 'PoolInfo',
            index: s.loadUintBig(200),
            collection: s.loadAddress(),
        }
    },
    store(self: PoolInfo, b: c.Builder): void {
        b.storeUint(self.index, 200);
        b.storeAddress(self.collection);
    },
    toCell(self: PoolInfo): c.Cell {
        return makeCellFrom<PoolInfo>(self, PoolInfo.store);
    }
}

/**
 > struct (0x7362d09c) RefundNotification {
 >     queryId: uint64
 > }
 */
export interface RefundNotification {
    readonly $: 'RefundNotification'
    queryId: uint64
}

export const RefundNotification = {
    PREFIX: 0x7362d09c,

    create(args: {
        queryId: uint64
    }): RefundNotification {
        return {
            $: 'RefundNotification',
            ...args
        }
    },
    fromSlice(s: c.Slice): RefundNotification {
        loadAndCheckPrefix32(s, 0x7362d09c, 'RefundNotification');
        return {
            $: 'RefundNotification',
            queryId: s.loadUintBig(64),
        }
    },
    store(self: RefundNotification, b: c.Builder): void {
        b.storeUint(0x7362d09c, 32);
        b.storeUint(self.queryId, 64);
    },
    toCell(self: RefundNotification): c.Cell {
        return makeCellFrom<RefundNotification>(self, RefundNotification.store);
    }
}

/**
 > struct JettonInfo {
 >     comissionPercentMul: uint17
 >     minAmount: coins
 >     ownerWallet: address
 >     forwardNanoTonLimit: coins
 > }
 */
export interface JettonInfo {
    readonly $: 'JettonInfo'
    comissionPercentMul: uint17
    minAmount: coins
    ownerWallet: c.Address
    forwardNanoTonLimit: coins
}

export const JettonInfo = {
    create(args: {
        comissionPercentMul: uint17
        minAmount: coins
        ownerWallet: c.Address
        forwardNanoTonLimit: coins
    }): JettonInfo {
        return {
            $: 'JettonInfo',
            ...args
        }
    },
    fromSlice(s: c.Slice): JettonInfo {
        return {
            $: 'JettonInfo',
            comissionPercentMul: s.loadUintBig(17),
            minAmount: s.loadCoins(),
            ownerWallet: s.loadAddress(),
            forwardNanoTonLimit: s.loadCoins(),
        }
    },
    store(self: JettonInfo, b: c.Builder): void {
        b.storeUint(self.comissionPercentMul, 17);
        b.storeCoins(self.minAmount);
        b.storeAddress(self.ownerWallet);
        b.storeCoins(self.forwardNanoTonLimit);
    },
    toCell(self: JettonInfo): c.Cell {
        return makeCellFrom<JettonInfo>(self, JettonInfo.store);
    }
}

/**
 > struct PoolStorage {
 >     index: uint200
 >     seqno: uint32
 >     collection: address
 >     publicKey: uint256
 >     owner: address
 >     domain: string
 >     serverLink: string
 >     availableJettons: map<address, Cell<JettonInfo>>
 > }
 */
export interface PoolStorage {
    readonly $: 'PoolStorage'
    index: uint200
    seqno: uint32
    collection: c.Address
    publicKey: uint256
    owner: c.Address
    domain: string
    serverLink: string
    availableJettons: c.Dictionary<c.Address, CellRef<JettonInfo>>
}

export const PoolStorage = {
    create(args: {
        index: uint200
        seqno: uint32
        collection: c.Address
        publicKey: uint256
        owner: c.Address
        domain: string
        serverLink: string
        availableJettons: c.Dictionary<c.Address, CellRef<JettonInfo>>
    }): PoolStorage {
        return {
            $: 'PoolStorage',
            ...args
        }
    },
    fromSlice(s: c.Slice): PoolStorage {
        return {
            $: 'PoolStorage',
            index: s.loadUintBig(200),
            seqno: s.loadUintBig(32),
            collection: s.loadAddress(),
            publicKey: s.loadUintBig(256),
            owner: s.loadAddress(),
            domain: s.loadStringRefTail(),
            serverLink: s.loadStringRefTail(),
            availableJettons: c.Dictionary.load<c.Address, CellRef<JettonInfo>>(c.Dictionary.Keys.Address(), createDictionaryValue<CellRef<JettonInfo>>(
                (s) => loadCellRef<JettonInfo>(s, JettonInfo.fromSlice),
                (v,b) => storeCellRef<JettonInfo>(v, b, JettonInfo.store)
            ), s),
        }
    },
    store(self: PoolStorage, b: c.Builder): void {
        b.storeUint(self.index, 200);
        b.storeUint(self.seqno, 32);
        b.storeAddress(self.collection);
        b.storeUint(self.publicKey, 256);
        b.storeAddress(self.owner);
        b.storeStringRefTail(self.domain);
        b.storeStringRefTail(self.serverLink);
        b.storeDict<c.Address, CellRef<JettonInfo>>(self.availableJettons, c.Dictionary.Keys.Address(), createDictionaryValue<CellRef<JettonInfo>>(
            (s) => loadCellRef<JettonInfo>(s, JettonInfo.fromSlice),
            (v,b) => storeCellRef<JettonInfo>(v, b, JettonInfo.store)
        ));
    },
    toCell(self: PoolStorage): c.Cell {
        return makeCellFrom<PoolStorage>(self, PoolStorage.store);
    }
}

// ————————————————————————————————————————————
//    class Openpool
//

interface ExtraSendOptions {
    bounce?: boolean                    // default: false
    sendMode?: SendMode                 // default: SendMode.PAY_GAS_SEPARATELY
    extraCurrencies?: c.ExtraCurrency   // default: empty dict
}

interface DeployedAddrOptions {
    workchain?: number                  // default: 0 (basechain)
    toShard?: { fixedPrefixLength: number; closeTo: c.Address }
    overrideContractCode?: c.Cell
}

function calculateDeployedAddress(code: c.Cell, data: c.Cell, options: DeployedAddrOptions): c.Address {
    const stateInitCell = beginCell().store(c.storeStateInit({
        code,
        data,
        splitDepth: options.toShard?.fixedPrefixLength,
        special: null,
        libraries: null,
    })).endCell();

    let addrHash = stateInitCell.hash();
    if (options.toShard) {
        const shardDepth = options.toShard.fixedPrefixLength;
        addrHash = beginCell()
            .storeBits(new c.BitString(options.toShard.closeTo.hash, 0, shardDepth))
            .storeBits(new c.BitString(stateInitCell.hash(), shardDepth, 256 - shardDepth))
            .endCell()
            .beginParse().loadBuffer(32);
    }

    return new c.Address(options.workchain ?? 0, addrHash);
}

export class Openpool implements c.Contract {
    static CodeCell = c.Cell.fromBase64('te6ccgECCwEAAwQAART/APSkE/S88sgLAQIBIAIDBPTS+JHyQO1E0CDXSsIBjjrTx9Mf+kjR+JIhxwXy4ZUD1ywgAAAABPLgitP/+kjU1PQFBsjLxxXLHxb6UhLL//pSE8wSzPQAye1U4dPH0x/6SNP/+kjU1PQE0QjXLCapk7bckl8J4NcsIDXdl8TjAtcsIIHL2mTjAonXJwQFBgcB9PLtRNAg10rCAfLglPgnbxCCEDuaygC+8uCa08fTH/pI0//6SNTU9ATRKIMI1yIJgwjXIyDIzvkWVBCm+RDy4IcI0x/U1NMf9AVRSrry4IUh0NMfMdMf+gDTEPoAMAP4I7zy4IgubvLQlgXQ0z/6SPpIMAFWEIEBC/QLCACONFtsQviSIccF8uGRAdM/+gAw+CdvEIIQO5rKACKgvvLgmvgnbxCCEDuaygChosjPhQgT+lJY+gKCEHNi0JzPC4rLP8ly+wAAhPiSJMcF8uGR0z8x0xD6APpI+kj6ADAEyMsQUAP6AhL6Ulj6AslAGYEBC/QTBsjLxxXLHxP6Usv/+lLMEsz0AMntVAAINxkcywBkjiz4kiTHBfLhkdM/MfpIMFAIgQEL9FkwBsjLxxXLHxP6Usv/+lLMEsz0AMntVODywIoC/vLgltDTEPoA+kj6ADBQYr7y4JcIuvLgmCSCELP43HW6jkgzNQKCEOSI3bW6k/LAiuH4AIIK+vCA+CgtyMvHUsD6UsnIz5LyHiumF8s/+lIT+lIUzBLMycjPhYgT+lIB+gJxzwtqzMlx+wDjDQakB8jLxxfLHxT6UhLL//pSzBIJCgCENFFSvvLgmfgAggr68IBYoPgoLcjLx1LA+lLJyM+SkUwaphfLP/pSEvpSFMwSzMnIz4WIEvpSWPoCcc8LaszJcfsAAMrMEvQAye1UIG6RMOBwIdc5MI4pINdLwALy4JPAKPLgk9csIHYeQ2zy4JPU1wsHcrDy4InXOTABpCHHABLmMIQHu/Lgk+1F0NcsIHYeQ2zyv9Qx0wfU0cjPkDsPIbYTzMsHzMntVQ==');

    static Errors = {
        'ERROR_INVALID_SEQNO': 133,
        'ERROR_INVALID_SIGNATURE': 135,
        'ERROR_EXPIRED': 136,
        'ERROR_EXTERNAL_SEND_MESSAGE_MUST_HAVE_IGNORE_ERRORS_SEND_MODE': 137,
        'ERROR_INVALID_MESSAGE_OPERATION': 138,
        'ERROR_INVALID_C5': 147,
        'ERROR_NOT_INITIALIZED': 148,
        'ERROR_JETTON_NOT_FOUND': 150,
        'ERROR_JETTON_LESS_THAN_MINIMUM': 151,
        'ERROR_JETTON_NOT_EQUAL_COMMISION': 152,
        'ERROR_JETTON_NANO_TON_GREAT_THAN_MAXIMUM': 153,
        'ERROR_INSUFFICIENT_FUNDS': 154,
        'ERROR_NOT_FROM_OWNER': 401,
        'ERROR_NOT_FROM_COLLECTION': 405,
    }

    readonly address: c.Address
    readonly init: { code: c.Cell, data: c.Cell } | undefined

    protected constructor(address: c.Address, init?: { code: c.Cell, data: c.Cell }) {
        this.address = address;
        this.init = init;
    }

    static fromAddress(address: c.Address) {
        return new Openpool(address);
    }

    static fromStorage(emptyStorage: {
        index: uint200
        seqno: uint32
        collection: c.Address
        publicKey: uint256
        owner: c.Address
        domain: string
        serverLink: string
        availableJettons: c.Dictionary<c.Address, CellRef<JettonInfo>>
    }, deployedOptions?: DeployedAddrOptions) {
        const initialState = {
            code: deployedOptions?.overrideContractCode ?? Openpool.CodeCell,
            data: PoolStorage.toCell(PoolStorage.create(emptyStorage)),
        };
        const address = calculateDeployedAddress(initialState.code, initialState.data, deployedOptions ?? {});
        return new Openpool(address, initialState);
    }

    static createCellOfTopUp(body: {
        queryId: uint64
    }) {
        return TopUp.toCell(TopUp.create(body));
    }

    static createCellOfRefund(body: {
        queryId: uint64
        value: coins
    }) {
        return Refund.toCell(Refund.create(body));
    }

    static createCellOfAddJetton(body: {
        queryId: uint64
        comissionPercentMul: uint17
        minAmount: coins
        minter: c.Address
        ownerWallet: c.Address
        forwardNanoTonLimit: coins
    }) {
        return AddJetton.toCell(AddJetton.create(body));
    }

    static createCellOfRemoveJetton(body: {
        queryId: uint64
        minter: c.Address
    }) {
        return RemoveJetton.toCell(RemoveJetton.create(body));
    }

    async sendDeploy(provider: ContractProvider, via: Sender, msgValue: coins, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: c.Cell.EMPTY,
            ...extraOptions
        });
    }

    async sendTopUp(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        queryId: uint64
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: TopUp.toCell(TopUp.create(body)),
            ...extraOptions
        });
    }

    async sendRefund(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        queryId: uint64
        value: coins
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: Refund.toCell(Refund.create(body)),
            ...extraOptions
        });
    }

    async sendAddJetton(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        queryId: uint64
        comissionPercentMul: uint17
        minAmount: coins
        minter: c.Address
        ownerWallet: c.Address
        forwardNanoTonLimit: coins
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: AddJetton.toCell(AddJetton.create(body)),
            ...extraOptions
        });
    }

    async sendRemoveJetton(provider: ContractProvider, via: Sender, msgValue: coins, body: {
        queryId: uint64
        minter: c.Address
    }, extraOptions?: ExtraSendOptions) {
        return provider.internal(via, {
            value: msgValue,
            body: RemoveJetton.toCell(RemoveJetton.create(body)),
            ...extraOptions
        });
    }
}
