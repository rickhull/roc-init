# Suspicious Items in Roc Language References

Items in the roc-language skill reference docs that conflict with compiler behavior
observed during SeatZero development. The mini-tutorial (`mini-tutorial-new-compiler.md`)
is from Richard Feldman and is considered authoritative — only LANGREF and AUGMENTS are
flagged here.

---

## ROC_LANGREF_TUTORIAL.md

### 1. Module headers — CONFIRMED DEPRECATED

**Location:** Line 1686-1688

**What it says:**
```roc
module [public_fn, PublicType]
```
Listed as a valid module header type for "Reusable library code."

**What the compiler says:** Explicit rejection:
> MODULE HEADER DEPRECATED. Type modules (headerless files with a top-level type
> matching the filename) are now the preferred way to define modules.
> Remove the `module` header and ensure your file defines a type that matches the filename.

**Impact:** Any guidance about structuring reusable library code via `module [...]` headers
is pointing at a dead mechanism. The actual pattern is: headerless file, define a type
matching the filename (e.g. `ParseUtil.roc` must define `ParseUtil`), methods go in `.{}`.

---

### 2. "Headerless Application Modules" — MISLEADING

**Location:** Line 1706-1708

**What it says:**
> Simple scripts can omit the header if they only use standard features.

**Reality:** Headerless is not a simplification for scripts — it is the *only* way.
Type modules are always headerless. App modules use `app [main!] { pf: ... }` (which is
itself a header, just not `module [...]`). There is no opt-in/opt-out; the `module`
header simply does not exist anymore.

---

### 3. `exposing` in imports — UNVERIFIED, LIKELY DEAD

**Location:** Lines 1727-1744

**What it says:**
```roc
import pf.Stdout exposing [line!, write!]
import pkg.Something exposing [Custom.*]
```

**Why suspicious:** Our project gotchas (ROC_GOTCHAS.md) note that `import ParseUtil exposing [parse_sexp]`
does not work for type module methods. We have not tested whether `exposing` works for
platform modules specifically. It may be platform-only syntax, or it may be entirely dead.
Needs empirical verification before trusting.

---

### 4. Module Types [WIP] — INCOMPLETE, NEEDS REWRITING

**Location:** Line 893-898

**What it says:**
```
- Type Modules: Export types
- Package Modules: Group related modules
- Platform Modules: Define platform interface
- Application Modules: Entry point with main!
```

**Reality:** Marked [WIP] and doesn't describe the actual mechanism. "Type Modules"
in particular is the critical one — the actual rule is "headerless file with a top-level
type matching the filename, methods in `.{}`." The description "Export types" is too vague
to be useful.

---

## MINI_TUTORIAL_AUGMENTS.md

### 5. `=>` in effectful lambda bodies — SYSTEMATIC ERROR

**Location:** All 5 practical examples (lines 686, 732, 778, 815, 856)

**What it shows:**
```roc
main! = |_args| => {
    ...
    Ok({})
}
```

**What actually works** (per mini-tutorial and every working file in this project):
```roc
main! = |_args| {
    ...
    Ok({})
}
```

`=>` is for type *signatures* only (`main! : List(Str) => Try({}, [..])`). It does not
appear in lambda definitions. The mini-tutorial correctly omits it; AUGMENTS repeats
the error in every example.

---

### 6. `::` opaque type description — SELF-CONTRADICTORY

**Location:** Lines 93-112 (Type Definition Variants section)

**What it says (contradictory claims):**
- Line 110: "Module-private: Can only be used within the defining module"
- Line 112: "Users can pass it around but can't inspect its contents"

These cannot both be true. Evidence from basic-cli: `Cmd :: { ... }.{ ... }` is defined
in `platform/Cmd.roc` and used externally via `import pf.Cmd` — callers invoke its methods
freely. The type is *not* module-private.

**Correct characterization:** `::` hides the internal *structure* of a type from external
modules (you can't pattern match on it or access fields directly), but the type itself and
its `.{}` methods are fully accessible externally. The "module-private" claim is wrong.

---

## Notes

- Items are ordered by confidence. Items 1 and 5 are confirmed by direct compiler feedback.
  Items 2-4 and 6 are inferred from observed behavior and may warrant further verification.
- The mini-tutorial (`mini-tutorial-new-compiler.md`) is from Richard Feldman and is
  considered 99.9% correct. Nothing from it is flagged here.
- AUGMENTS Example 5 (`is_eq` on nominal types) is confirmed correct and useful — it
  shows exactly how to add equality support to nominal types, which `==` requires.
