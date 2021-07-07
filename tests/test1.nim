import asyncthreadpool, os, strutils
when not defined(ChronosAsync):
  import asyncdispatch
else:
  import chronos
proc intProc(a, b: int, sl: int): int =
  sleep(sl)
  a + b

proc voidProc(a, b: int, sl: int) =
  sleep(sl)

proc incCtx(ctx: var int, byValue: int): int =
  ctx += byValue
  ctx

proc chkCtx(ctx, withValue: int) =
  doAssert(ctx == withValue)

proc raiseErrorTask() =
  raise newException(ValueError, "Test exception")

proc test() {.async.} =
  block:
    let t = newThreadPool()
    let f1 = t.spawn intProc(10, 10, 10)
    let f2 = t.spawn intProc(5, 5, 0)
    block:
      let r2 = await f2
      let r1 = await f1
      doAssert(r2 == 10)
      doAssert(r1 == 20)

    block:
      doAssert(20 == await t.spawn intProc(10, 10, 10))
      doAssert(10 == await t.spawn intProc(5, 5, 10))

  block: # Pool-less spawn
    doAssert(20 == await spawn intProc(10, 10, 10))

  block: # Contexts:
    let t = newThreadPool(int, 1)
    doAssert(1 == await t.spawn incCtx(threadContext, 1))
    doAssert(3 == await t.spawn incCtx(threadContext, 2))
    await t.spawn chkCtx(threadContext, 3)

  block: # Exceptions
    let t = newThreadPool()
    let f = t.spawn raiseErrorTask()
    var ok = false
    try:
      await f
    except ValueError as e:
      ok = true
      doAssert("Test exception" in e.msg)
    doAssert(ok)

waitFor test()
