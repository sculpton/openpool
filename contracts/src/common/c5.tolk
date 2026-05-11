const ERROR_INVALID_C5 = 147
const ERROR_EXTERNAL_SEND_MESSAGE_MUST_HAVE_IGNORE_ERRORS_SEND_MODE = 137

type OutActionsCell = cell

/// transform an ordinary or exotic cell into a slice, as if it were an ordinary cell
fun OutActionsCell.beginParseAllowExotic(self): slice
    asm "XCTOS" "DROP"

/// verify a cell containing OutActionList that it contains only "send message" actions
fun OutActionsCell.verifyC5Actions(self, isExternal: bool): self {
    var count = 0;

    var cs = self.beginParseAllowExotic();
    do {
        // these checks could be cheaper in terms of gas if we just try to parse cs;
        // but we want to throw exactly `ERROR_INVALID_C5` (not `9` "cell underflow")
        var (nBits, nRefs) = cs.remainingBitsAndRefsCount();
        assert (nRefs == 2) throw ERROR_INVALID_C5;
        assert (nBits == 32 + 8) throw ERROR_INVALID_C5;

        val outAction = lazy OutActionWithSendMessageOnly.fromSlice(
            cs,
            { throwIfOpcodeDoesNotMatch: ERROR_INVALID_C5 },
        );

        if (isExternal) {
            assert (
                (outAction.sendMode & SEND_MODE_IGNORE_ERRORS) != 0
            ) throw ERROR_EXTERNAL_SEND_MESSAGE_MUST_HAVE_IGNORE_ERRORS_SEND_MODE;
        }

        cs = outAction.prev.beginParseAllowExotic();
        count += 1;
    } while (!cs.isEmpty());

    assert (count <= 255) throw ERROR_INVALID_C5;

    return self;
}

/// For instance, it contains "send message" actions (the only we allow)
/// see block.tlb: https://github.com/ton-blockchain/ton/blob/5c392e0f2d946877bb79a09ed35068f7b0bd333a/crypto/block/block.tlb#L380
struct (0x0ec3c86d) OutActionWithSendMessageOnly {
    prev: OutActionsCell
    sendMode: uint8
    outMsg: cell
}

fun getC5(): Cell<OutActionWithSendMessageOnly>
    asm "c5 PUSH"

/// put a raw list of OutActions to C5 register
fun setTvmRegisterC5(actionList: cell): void
    asm "c5 POP"

fun updateC5(actionList: cell): void {
    var c5 = getC5().load();
    c5.prev = actionList;

    setTvmRegisterC5(c5.toCell());
}
