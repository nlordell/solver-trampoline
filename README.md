# Solver Trampoline

A solver trampoline contract that allows solvers to sign settlements, but any account execute them.
This is useful in the context of using transaction relayers (like Gelato or Infura ITX) for doing the actual transaction submission, while ensuring that only solvers are actually allowed to produce settlements.
