# Solver Trampoline

A solver trampoline contract that allows solvers to sign settlements, but any account execute them.
This is useful in the context of using transaction relayers (like Gelato or Infura ITX) for doing the actual transaction submission, while ensuring that only solvers are actually allowed to produce settlements.

## Status

Currently, this is just a PoC. Some remaining work:
- [ ] Evaluate wether or not the `nonce` storage is needed, or if another more gas efficient replay protection mechanism can be used.
- [ ] Trampoline contract gas optimizations
    1. Manual `settle` and `isSolver` calls (saves `EXTCODESIZE` check and calldata copy loop)
    2. Manual signing message computation (saves allocations and bytes copy loops)
