# Research: Alternative R Implementations and Fork Cost

## 1. Alternative R Implementations Landscape (2026)

### Status Summary
| Implementation | Platform | Status | Viability for Syntax Changes |
| :--- | :--- | :--- | :--- |
| **GNU R** | C/Fortran | **Active** (Reference) | Very low (requires R-Core consensus) |
| **Renjin** | JVM | **Hibernating** | Low (last major updates ~2022) |
| **FastR** | GraalVM | **Experimental/Active** | Medium (built for extensibility/research) |
| **CXXR** | C++ | **Dead** | Zero (no updates in years) |
| **Riposte** | C++ | **Dead** | Zero |
| **miniR** | Rust | **Incubating** (Active) | High (modern, built for research) |
| **webR** | Wasm | **Active** | Low (tracks GNU R closely) |
| **radian** | Python | **Active** (REPL only) | N/A (not an implementation) |

### Detailed Breakdown
*   **FastR (GraalVM):** Built by Oracle Labs. Uses the Truffle framework. It is the most viable "alternative" that is still actively maintained for performance research. However, its goal is strict fidelity to GNU R; differences are considered bugs.
*   **miniR:** A recent (2026) implementation in Rust by `cgmossa`. It includes a modern parser and aims to run real-world CRAN packages. It is the most "hackable" for syntax experimentation due to its fresh codebase and Rust's tooling.
*   **Renjin:** Once promising for JVM integration, development has stalled. It struggles with many modern CRAN packages that rely heavily on C/Fortran extensions.
*   **CXXR:** An attempt to refactor R into C++. It provided better encapsulation but failed to keep pace with GNU R's evolution.

## 2. Maintaining a GNU R Fork

### Codebase and Complexity
*   **Size:** ~930k lines of code (Source: Open Hub 2026).
*   **Composition:** ~36% C, ~21% R, ~15% Fortran, ~28% other (Headers, Yacc, etc.).
*   **Release Cadence:** Major `x.y.0` releases annually in Spring (e.g., 4.6.0 on 2026-04-24). Patch releases `x.y.z` as needed.
*   **Fork Cost:** High. Maintaining a fork requires tracking the `trunk` (SVN) and merging annual upstream changes across a polyglot codebase. The parser (Yacc/Bison) is particularly sensitive to syntax changes.

## 3. R-Core and Syntax Proposals

### The "REP" Process
R does not have a formal "R Enhancement Proposal" (REP) process like Python's PEP. Proposals happen via:
1.  **R-devel Mailing List:** Discussions often start here (e.g., Antoine Fabri's 2019 pipe query).
2.  **R-syntax Branch:** R-Core creates experimental SVN branches for major syntax changes (e.g., the `R-syntax` branch for `|>` and `\(x)`).
3.  **Core Keynotes:** Major features are often debuted at `useR!` conferences (e.g., Luke Tierney's 2020 keynote).

### Precedent: The Native Pipe (`|>`)
*   **Timeline:** Suggested in 2017 (Jim Hester), discussed on r-devel in 2019, implemented in 2020, released in 2021 (R 4.1.0).
*   **Path:** Community demand (magrittr) -> r-devel debate -> R-Core experimentation -> Syntax transformation in the parser (not a function).
*   **Stance:** R-Core is extremely conservative. They prefer "syntax transformations" in the parser over changing the underlying evaluator to minimize performance hits and compatibility issues.

## 4. Findings & Recommendations
*   **Direct Fork:** Only viable for a well-funded organization. The cost of syncing annual GNU R releases is prohibitive for a single package project.
*   **Alternative Implementation:** `miniR` (Rust) or `FastR` are the best targets for a "typed R" proof-of-concept, but they lack the user base of GNU R.
*   **Syntax Extensions:** Adding `x: int` to GNU R would require a patch to `src/main/gram.y`. R-Core is unlikely to accept this unless it is proved non-breaking and has massive community backing.

*Sources: R-project.org, r-devel mailing list archives, GitHub (oracle/fastr, cgmossa/miniR, bedatadriven/renjin), Open Hub.*
