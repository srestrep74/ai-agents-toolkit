# Example: PR #155 - Miles Rounding Fix (Approved)

### PR Review: #155 - fix: correct miles calculation on redemption

| Field | Value |
|-------|-------|
| **Verdict** | ✅ APPROVED |
| **Repository** | booking-service |
| **Branch** | `fix/miles-calculation` -> `develop` |
| **Work Item** | #3901 - Fix miles rounding on redemption checkout |
| **Status** | COMPLETED |

---

#### Functional Mission
This fix addresses a rounding discrepancy in the redemption flow where miles were being truncated instead of rounded to the nearest integer. This ensures financial consistency between the frontend display and the backend transaction.

---

#### Functional Alignment

| Requirement Source | Status | Observation & Evidence |
|--------------------|--------|------------------------|
| **Story Description** | ✅ Aligned | Correctly implemented `HALF_UP` rounding logic in `RedemptionCalculator.scala:L85`. This matches the business rule for financial accuracy mentioned in the description. |
| **Acceptance Criteria** | ✅ Met | **AC1 (Nearest integer)**: Verified in `L87`. <br> **AC2 (Flow coverage)**: Both cash and miles paths updated. <br> **AC3 (Tests)**: Unit tests updated in `RedemptionCalculatorSpec.scala:L102`. |

---

#### Agent Findings & Code Proposals

| Category | File:Line | Finding | Proposal |
|----------|-----------|---------|----------|
| OPTIMIZE | `RedemptionCalculator.scala:L90` | Redundant calculation of miles sum in the loop. | See Code Block Below |

**Proposed Improvement for `RedemptionCalculator.scala:L90`**
```scala
// Before:
parts.map(p => calculate(p)).sum // Calculation repeated inside map and sum

// After:
// Use foldLeft or pre-calculate totals to reduce complexity if the parts list grows.
val totals = parts.foldLeft(Miles.Zero)(_ + calculate(_))
```

---

#### Team Discussion Review (Azure Threads)
| Discussion | Status | Note |
|------------|--------|------|
| Rounding strategy | ✅ Resolved | Team agreed on `HALF_UP` over `CEIL` to keep it fair for the passenger. |

---

#### Summary
The code change is clean, solves the reported bug, and includes necessary test coverage. The optimization suggested is minor and doesn't block the merge.