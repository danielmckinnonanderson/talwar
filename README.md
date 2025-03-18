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
- En passant
- Castling

### UCI protocol
- Implement protocol to connect to GUI

### Move evaluation
- Given a gamestate, determine the best move
- Probably start with simplest possible evaluation algorithm

