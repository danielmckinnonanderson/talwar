# Talwar

A chess engine written in Zig.

This application requires Zig `0.13.0`.

Run the app with
```
zig build run
```

Run the tests with
```
zig build test --summary all
```

## Todo's
### Bitboard representation
- More ergonomic API for getting legal moves for a piece at position (that accounts for being pinned)
- Better error reporting
- En passant
- Promotion
- Castling
- [Zobrist hashing](https://www.chessprogramming.org/Zobrist_Hashing) of board states

### UCI protocol
- Implement handlers for all commands, updating engine behavior and responding via output accordingly
- Consider running the interface process on its own thread, so that engine process
  can run and be controlled independently. Protocol needs to respond to commands immediately,
  for example if "stop" command is received search needs to end ASAP and return best move it has found.
    - Figure out how to communicate between interface and engine, ideally without locking

### Move evaluation
- Given a gamestate, determine the best move
- Probably start with simplest possible evaluation algorithm - Minimax?

