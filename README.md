# Talwar

A chess engine written in Zig.

This application requires Zig `0.14.0`.

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
- Bitboard can determine if king is in check
- Bitboard prevents moving into check (pinning), restricts moves in check to moving
  out of check only

### UCI protocol
- Implement protocol to connect to GUI

### Move evaluation
- Given a gamestate, determine the best move
- Probably start with simplest possible evaluation algorithm

