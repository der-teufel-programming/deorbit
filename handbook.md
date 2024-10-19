# Deorbit Assembly Syntax

Deorbit Assembly syntax (also called Devil Assembly syntax) is an assembly syntax for Aphelion.
Main differences from the main Luna Orbit Systems syntax are described later in this document.

## Notation

### Numbers:
Integer literals are base 10 by default. You can specify different bases using a prefix:
- `0x` for hexadecimal (base 16)
- `0o` for octal (base 8)
- `0b` for binary (base 2)
- `0q` for quaternary (base 4)
- `0d` for explicit decimal (base 10)
- `0s` for seximal (base 6)

Deorbit supports decimal float literals.

### Registers:
Registers names are prefixed with `%`, for example to use Aphelion's `ra` register you'd type `%ra`.
Aphelion has following 64-bit registers:
- `rz` always 0
- `ra`, `rb`, `rc`, `rd`, `re`, `rf`, `rg`, `rh`, `ri`, `rj`, `rk` general purpose
- `ip` instruction pointer (program counter)
- `sp` stack pointer
- `fp` frame pointer
- `st` status register

`st` is not a valid write destinations for almost all instructions (comparison instructions change parts of it).

### Labels:
Labels are introduced by name followed by `:`
```
label_name:
```
To use the label in an instruction prefix its name with `$` like this:
```
bra $label_name
```
<!-- Labels are local to the scope they are defined in. You can define scopes with `.scope` and `.endscope` macros.
To export a label from a scope use `.export label_name` macro. If you enable auto-scoping (by using `.autoscopes` at the beginning of the file) all labels will introduce a scope depending on indentation. -->

### Comments
Deorbit comments start with `;` and end with the line.

### Assembly-time constants
You can define assembly-time constants using your favourite `#define name value`

### Pseudoinstructions for defining values
Deorbit supports additional pseudoinstructions prefixed with `@` for defining values.
- Numbers
  - `@u8`, `@i8`, `@u16`, `@i16`, `@u32`, `@i32`, `@u64`, `@i64`
    - Define integer constants of particular bitwidth, i signifies signed, u unsigned
  - `@f16`, `@f32`, `@f64`
    - Define float constant of particular bitwidth
- Strings
  - `@ascii`, `@asciiz`
    - 8-bit ASCII string (followed by 0 byte for `@asciiz`)
  - `@utf8`, `@utf8z`
    - UTF-8 encoded Unicode string (followed by 0 byte for `@utf8z`)
  - `@utf32`, `@utf32z`
    - UTF-32 encoded Unicode string (followed by 0 byte for `@utf32z`)

All number constants take an optional second argument to define a memory area filled with a particular value

Examples:
```
STD_OUT:
    @u8 10

some_string:
    @asciiz "Hello, World!"
some_string_2:
    @utf8 "Zażółć gęślą jaźń"

ten_i32_minus_ones:
    @i32 -1, 10
```
## System Control

| Mnemonic   | Description |
| ---------- | ----------- |
| `nop`      | no operation, expands to `add rz, rz, rz`,
| `inv`      | invalid opcode, expands to `int 2`,
| `int imm8` | trigger interrupt number `imm8`,
| `iret`     | return from interrupt,
| `ires`     | resolve interrupt,
| `usr rd`   | enter user mode and jump to address in `rd`. `rd` should hold a virtual address.,

## Input & Output

| Mnemonic            | Description                      |
| ------------------- | -------------------------------- |
| `out  rd/imm16, rs` | Assembler alias for outr, outi,  |
| `in   rd, rs/imm16` | Assembler alias for inr,  ini,   |
| `outr rd, rs`       | output data in rs to port rd,    |
| `outi imm16, rs`    | output data in rs to port imm16, |
| `inr  rd, rs`       | read data from port rs to rd,    |
| `ini  rd, imm16`    | read data from port imm16 to rd, |


## Control Flow

| Mnemonic | Description |
| -------- | ----------- |
|call rs, label      | call function, expands to `li rs, label; jal rs, 0`
|callr rs, label, rd | call function, expands to `li rs, label; jalr rs, 0, rd`
|jal  rs, imm16      | `push ip, ip <- rs + 4 * (i64)imm16`
|jalr rs, imm16, rd  | `rd <- ip, ip <- rs + 4 * (i64)imm16`
|ret                 | `pop ip`
|retr  rs            | `ip <- rs`
|b(cc) imm20         | `ip <- pc + 4*(i64)imm20`, branch on condition (see [Branch Conditions](#branch-conditions) below)


### Branch Conditions
| Mnemonic | cmpr A, B | Condition |
| -------- | --------- | --------- |
| bra      | `always`           | `(true)` |
| beq      | `A == B`           | `EQUAL` |
| bez      | `A == 0`           | `ZERO` |
| blt      | `A < B`            | `LESS` |
| ble      | `A <= B`           | `LESS \|\| EQUAL` |
| bltu     | `(u64)A < (u64)B`  | `LESS_UNSIGNED` |
| bleu     | `(u64)A <= (u64)B` | `LESS_UNSIGNED \|\| EQUAL` |
| bne      | `!(A == B)`        | `!EQUAL` |
| bnz      | `!(A == 0)`        | `!ZERO` |
| bge      | `A >= B`           | `!LESS` |
| bgt      | `A > B`            | `!(LESS \|\| EQUAL)` |
| bgeu     | `(u64)A >= (u64)B` | `!(LESS_UNSIGNED)` |
| bgtu     | `(u64)A > (u64)B`  | `!(LESS_UNSIGNED \|\| EQUAL)` |

## Stack Operations <stack_ops>

#text(font: "Fira Code", weight: 450)[#table(
  columns: (auto,auto,0.2fr,1fr),
  align: left,
  Mnemonic, Encoding, Format, Description,
  "push  rs",        "-- rs ----- 0x0b", "M", "sp <- sp - 8, mem[sp] <- rs",
  "pop   rd",        "rd -- ----- 0x0c", "M", "rd <- mem[sp], sp <- sp + 8",
  "enter",           "-- -------- 0x0d", "B", "push fp, fp = sp; enter stack frame",
  "leave",           "-- -------- 0x0e", "B", "sp = fp, pop fp; leave stack frame",
)] 

## Data Flow <data_flow>
Note: Parameters denoted with parenthesis are optional in the assembly syntax.
#text(font: "Fira Code", weight: 450)[#table(
  columns: (auto,auto,0.2fr,1fr), 
  align: left,
  Mnemonic, Encoding, Format, Description,
  "mov   rd, rs",         "",                  "",  "rd <- rs, expands to 'or rd, rs, rz'",
  "li    rd, imm",        "",                  "",  "rd <- imm64, expands to li-family as needed",
  "lli   rd, imm",        "rd  0  imm 0x10", "F", "rd[15..0]  <- imm",
  "llis  rd, imm",        "rd  1  imm 0x10", "F", "rd         <- (i64)imm",
  "lui   rd, imm",        "rd  2  imm 0x10", "F", "rd[31..16] <- imm",
  "luis  rd, imm",        "rd  3  imm 0x10", "F", "rd         <- (i64)imm << 16",
  "lti   rd, imm",        "rd  4  imm 0x10", "F", "rd[47..32] <- imm",
  "ltis  rd, imm",        "rd  5  imm 0x10", "F", "rd         <- (i64)imm << 32",
  "ltui  rd, imm",        "rd  6  imm 0x10", "F", "rd[63..48] <- imm",
  "ltuis rd, imm",        "rd  7  imm 0x10", "F", "rd         <- (i64)imm << 48",
  "lw    rd, rs, off, (rn, sh)", "rd rs rn sh off 0x11", "E", "rd        <- mem[rs + (i64)off + rn << sh]",
  "lh    rd, rs, off, (rn, sh)", "rd rs rn sh off 0x12", "E", "rd[31..0] <- mem[rs + (i64)off + rn << sh]",
  "lhs   rd, rs, off, (rn, sh)", "rd rs rn sh off 0x13", "E", "rd        <- mem[rs + (i64)off + rn << sh]",
  "lq    rd, rs, off, (rn, sh)", "rd rs rn sh off 0x14", "E", "rd[15..0] <- mem[rs + (i64)off + rn << sh]",
  "lqs   rd, rs, off, (rn, sh)", "rd rs rn sh off 0x15", "E", "rd        <- mem[rs + (i64)off + rn << sh]",
  "lb    rd, rs, off, (rn, sh)", "rd rs rn sh off 0x16", "E", "rd[7..0]  <- mem[rs + (i64)off + rn << sh]",
  "lbs   rd, rs, off, (rn, sh)", "rd rs rn sh off 0x17", "E", "rd        <- mem[rs + (i64)off + rn << sh]",
  "sw    rs, off, (rn, sh), rd", "rd rs rn sh off 0x18", "E", "mem[rs + off + rn << sh] <- (i64)rd",
  "sh    rs, off, (rn, sh), rd", "rd rs rn sh off 0x19", "E", "mem[rs + off + rn << sh] <- (i32)rd",
  "sq    rs, off, (rn, sh), rd", "rd rs rn sh off 0x1a", "E", "mem[rs + off + rn << sh] <- (i16)rd",
  "sb    rs, off, (rn, sh), rd", "rd rs rn sh off 0x1b", "E", "mem[rs + off + rn << sh] <- (i8)rd",
)]

## Comparisons

#text(font: "Fira Code", weight: 450)[#table(
  columns: (auto,auto,0.2fr,1fr),  align: left,
  Mnemonic, Encoding, Format, Description,
  "cmp  r1/imm, r2/imm", "", "", "Alias for cmpr, cmpi",
  "cmpr r1, r2",       "r1 r2 ---- 1e", "M", "compare and set flags (see " + link(label("reg_st)[_status register_] + ",
  "cmpi r1/imm, r1/imm",    "r1 [s] imm 1f", "F", "compare and set flags (see " + link(label("reg_st)[_status register_] + . imm is sign-extended. if the immediate value is first, [s] is set to 1, else 0.",
  
)]

## Arithmetic Operations

//#figure(
#text(font: "Fira Code", weight: 450)[#table(
  columns: (auto,auto,0.2fr,1fr),  align: left,
  Mnemonic, Encoding, Format, Description,
  "add   rd, r1, r2/imm16", "",               "",  "Integer addition; alias for addr, addi",
  "sub   rd, r1, r2/imm16", "",               "",  "Integer subtraction; alias for subr, subi",
  "imul  rd, r1, r2/imm16", "",               "",  "Signed integer multiplication; alias for imulr, imuli",
  "umul  rd, r1, r2/imm16", "",               "",  "Unsigned integer multiplication; alias for umulr, umuli",
  "idiv  rd, r1, r2/imm16", "",               "",  "Signed integer division; alias for idivr, idivi",
  "udiv  rd, r1, r2/imm16", "",               "",  "Unsigned integer division; alias for udivr, udivi",
  "rem   rd, r1, r2/imm16", "",               "",  "Integer remainder (truncated); alias for remr, remi",
  "mod   rd, r1, r2/imm16", "",               "",  "Integer modulus (floored); alias for modr, modi",
  "addr  rd, r1, r2",      "rd r1 r2 -- 0x20", "R", "rd <- r1 + r2",
  "addi  rd, r1, imm16",   "rd r1 imm16 0x21", "M", "rd <- r1 + (i64)imm16",
  "subr  rd, r1, r2",      "rd r1 r2 -- 0x22", "R", "rd <- r1 - r2",
  "subi  rd, r1, imm16",   "rd r1 imm16 0x23", "M", "rd <- r1 - (i64)imm16",
  "imulr rd, r1, r2",      "rd r1 r2 -- 0x24", "R", "rd <- r1 * r2           (signed)",
  "imuli rd, r1, imm16",   "rd r1 imm16 0x25", "M", "rd <- r1 * (i64)imm16   (signed)",
  "idivr rd, r1, r2",      "rd r1 r2 -- 0x26", "R", "rd <- r1 / r2           (signed)",
  "idivi rd, r1, imm16",   "rd r1 imm16 0x27", "M", "rd <- r1 / (i64)imm16   (signed)",
  "umulr rd, r1, r2",      "rd r1 r2 -- 0x28", "R", "rd <- r1 * r2           (unsigned)",
  "umuli rd, r1, imm16",   "rd r1 imm16 0x29", "M", "rd <- r1 * (u64)imm16   (unsigned)",
  "udivr rd, r1, r2",      "rd r1 r2 -- 0x2a", "R", "rd <- r1 / r2           (unsigned)",
  "udivi rd, r1, imm16",   "rd r1 imm16 0x2b", "M", "rd <- r1 / (u64)imm16   (unsigned)",
  "remr  rd, r1, r2",      "rd r1 r2 -- 0x2c", "R", "rd <- r1 % r2",
  "remi  rd, r1, imm16",   "rd r1 imm16 0x2d", "M", "rd <- r1 % (i64)imm16",
  "modr  rd, r1, r2",      "rd r1 r2 -- 0x2e", "R", "rd <- r1 % r2",
  "modi  rd, r1, imm16",   "rd r1 imm16 0x2f", "M", "rd <- r1 % (i64)imm16",
)]

## Bitwise Operations
For bitwise operations, assume all immediates zero-extended unless otherwise specified.

#text(font: "Fira Code", weight: 450)[#table(
  columns: (auto,auto,0.2fr,1fr),
  align: left,
  Mnemonic, Encoding, Format, Description,
  "and  rd, r1, r2/imm16", "",              "",  "Bitwise AND, alias for andr, andi",
  "or   rd, r1, r2/imm16", "",              "",  "Bitwise OR, alias for orr, ori",
  "nor  rd, r1, r2/imm16", "",              "",  "Bitwise NOR, alias for norr, nori",
  "not  rd, rs",           "",              "",  "Bitwise NOT, expand to 'nor rd, rs, rz'",
  "xor  rd, r1, r2/imm16", "",              "",  "Bitwise XOR, alias for xorr, xori",
  "shl  rd, r1, r2/imm16", "",              "",  "Shift left, alias for shlr, shli",
  "asr  rd, r1, r2/imm16", "",              "",  "Arithmetic shift right, alias for asrr, asri",
  "lsr  rd, r1, r2/imm16", "",              "",  "Logical shift right, alias for asrr, asri",
  "bit  rd, r1, r2/imm16", "",              "",  "Extract single bit, alias for bitr, biti.",
  "andr rd, r1, r2",    "rd r1 r2 -- 0x30", "R", "rd <- r1 & r2",
  "andi rd, r1, imm16", "rd r1 imm16 0x31", "M", "rd <- r1 & (u64)imm16",
  "orr  rd, r1, r2",    "rd r1 r2 -- 0x32", "R", "rd <- r1 | r2",
  "ori  rd, r1, imm16", "rd r1 imm16 0x33", "M", "rd <- r1 | (u64)imm16",
  "norr rd, r1, r2",    "rd r1 r2 -- 0x34", "R", "rd <- !(r1 | r2)",
  "nori rd, r1, imm16", "rd r1 imm16 0x35", "M", "rd <- !(r1 | (u64)imm16",
  "xorr rd, r1, r2",    "rd r1 r2 -- 0x36", "R", "rd <- r1 ^ r2",
  "xori rd, r1, imm16", "rd r1 imm16 0x37", "M", "rd <- r1 ^ (u64)imm16",
  "shlr rd, r1, r2",    "rd r1 r2 -- 0x38", "R", "rd <- r1 << r2",
  "shli rd, r1, imm16", "rd r1 imm16 0x39", "M", "rd <- r1 << (u64)imm16",
  "asrr rd, r1, r2",    "rd r1 r2 -- 0x3a", "R", "rd <- (i64)r1 >> r2",
  "asri rd, r1, imm16", "rd r1 imm16 0x3b", "M", "rd <- (i64)r1 >> (u64)imm16",
  "lsrr rd, r1, r2",    "rd r1 r2 -- 0x3c", "R", "rd <- (u64)r1 >> r2",
  "lsri rd, r1, imm16", "rd r1 imm16 0x3d", "M", "rd <- (u64)r1 >> (u64)imm16",
  "bitr rd, r1, r2",    "rd r1 r2 -- 0x3e", "R", "rd <- (r2 in 0..63) ? r1[r2] : 0",
  "biti rd, r1, imm16", "rd r1 imm16 0x3f", "M", "rd <- (imm16 in 0..63) ? r1[imm16] : 0",
  "setfs   rd", "",              "",  "rd <- 'SIGN' flag, expands to \n'biti rd, st, 0'",
  "setfz   rd", "",              "",  "rd <- 'ZERO' flag, expands to \n'biti rd, st, 1'",
  "setfcb  rd", "",              "",  "rd <- 'CARRY_BORROW' flag, expands to \n'biti rd, st, 2'",
  "setfcbu rd", "",              "",  "rd <- 'CARRY_BORROW_UNSIGNED' flag, expands to 'biti rd, st, 3'",
  "setfe   rd", "",              "",  "rd <- 'EQUAL' flag, expands to \n'biti rd, st, 4'",
  "setfl   rd", "",              "",  "rd <- 'LESS' flag, expands to \n'biti rd, st, 5'",
  "setflu  rd", "",              "",  "rd <- 'LESS_UNSIGNED' flag, expands to \n'biti rd, st, 6'",
)]

## Extension F - Floating-Point Operations
_Aphelion Extension F - Floating-Point Operations_ implements hardware support for floating-point formats as specified in the IEEE 754-2008 standard. The extension implements every operation for half-precision (16-bit), single-precision (32-bit), and double-precision (64-bit) formats. To specify, the instruction name must be appended with `.16`, `.32`, or `.64` for half, single, or double-precision, with the instruction's `func` field set to `0`, `1`, and `2` respectively.

#text(font: "Fira Code", weight: 450)[#table(
  columns: (auto,auto,0.2fr,1fr),  align: left,
  Mnemonic, Encoding, Format, Description,
  "fcmp  r1, r2",     "-- r1 r2 [p] -- 0x40",    "E",  "rd <- compare r1 and r2",
  "fto   rd, rs",     "rd rs -- [p] -- 0x41",    "E",  "rd <- (f[]) rs",
  "ffrom rd, rs",     "rd rs -- [p] -- 0x42",    "E",  "rd <- (i64) rs",
  "fneg  rd, rs",     "rd rs -- [p] -- 0x43",    "E",  "rd <- -rs",
  "fabs  rd, rs",     "rd rs -- [p] -- 0x44",    "E",  "rd <- |rs|",
  "fadd  rd, r1, r2", "rd r1 r2 [p] -- 0x45",    "E",  "rd <- r1 + r2",
  "fsub  rd, r1, r2", "rd r1 r2 [p] -- 0x46",    "E",  "rd <- r1 - r2",
  "fmul  rd, r1, r2", "rd r1 r2 [p] -- 0x47",    "E",  "rd <- r1 * r2",
  "fdiv  rd, r1, r2", "rd r1 r2 [p] -- 0x48",    "E",  "rd <- r1 / r2",
  "fma   rd, r1, r2", "rd r1 r2 [p] -- 0x49",    "E",  "rd <- rd + (r1 * r2)",
  "fsqrt rd, r1",     "rd r1 -- [p] -- 0x4a",    "E",  "rd <- squareroot(r1)",
  "fmin  rd, r1, r2", "rd r1 r2 [p] -- 0x4b",    "E",  "rd <- min(r1, r2)",
  "fmax  rd, r1, r2", "rd r1 r2 [p] -- 0x4c",    "E",  "rd <- max(r1, r2)",
  "fsat  rd, r1",     "rd r1 -- [p] -- 0x4d",    "E",  "rd <- smallest integer greater than or equal to r1 (basically ceil)",
  "fcnv  rd, r1",     "rd r1 -- [p] -- 0x4e",    "E",  "rd <- cast(r1); convert between precisions",
  "fnan  rd, r1",     "rd r1 -- [p] -- 0x4f",    "E",  "rd <- isnan(r1);",
)]

The instruction `fcnv` is a special case. `fcnv` takes two precision tags, the first tag occupying the lower two bits of `func` and the second occupying the higher two bits of `func`. The first tag specifies the format being converted to, and the second tag specifies the format being converted from. For example, the instruction `fcnv.64.32 rb, ra` would convert a single-precision value in `ra` to the nearest double-precision value and store it in `rb`. Conversions where the source precision and destination precision are equal are invalid instructions.