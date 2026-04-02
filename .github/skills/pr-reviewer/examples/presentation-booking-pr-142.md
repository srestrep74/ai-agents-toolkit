# Example: PR #142 - Instant Upgrade Implementation (Changes Required)

### PR Review: #142 - feat: add instant upgrade flow

| Field | Value |
|-------|-------|
| **Verdict** | ❌ CHANGES REQUIRED |
| **Repository** | booking-service |
| **Branch** | `feature/instant-upgrade` -> `develop` |
| **Work Item** | #3821 - Instant Upgrade - Core Flow |
| **Status** | ACTIVE |

---

#### Functional Mission
The goal of this story is to enable passengers to perform an "Instant Upgrade" directly from the booking confirmation page. This requires the system to validate seat availability in real-time, calculate the price in both miles and cash, and process the transaction without redirecting to a full checkout flow.

---

#### Functional Alignment

| Requirement Source | Status | Observation & Evidence |
|--------------------|--------|------------------------|
| **Story Description** | ❌ Gaps | The description requires an availability check *before* processing `UpgradeHandler.scala:L45`. This check is missing in the current implementation. |
| **Acceptance Criteria** | ⚠️ Partial | **AC1 (Select upgrade)**: Met via `UpgradeController.scala:L22`. <br> **AC2 (Validate availability)**: ❌ Missing from `core/UpgradeHandler.scala`. <br> **AC3 (Price display)**: Met via `UpgradeResponseDTO.scala:L12`. |

---

#### Agent Findings & Code Proposals

| Category | File:Line | Finding | Proposal |
|----------|-----------|---------|----------|
| BUG | `core/UpgradeHandler.scala:L45` | Missing call to `AvailabilityClient`. The upgrade might fail later if seats were taken. | See Code Block Below |
| ARCHITECTURE | `ports/UpgradeAdapter.scala:L5` | Infrastructure layer importing `domain.commands.UpgradeCommand` directly. | See Code Block Below |

**Proposed Improvement for `core/UpgradeHandler.scala:L45`**
```scala
// Before:
def processUpgrade(cmd: UpgradeCommand): Future[UpgradeResult] = {
  repository.save(cmd.toEntity) // Savinig without validation
}

// After:
def processUpgrade(cmd: UpgradeCommand): Future[UpgradeResult] = {
  for {
    isAvailable <- availabilityClient.check(cmd.flightId, cmd.seatClass)
    result <- if (isAvailable) repository.save(cmd.toEntity) 
              else Future.failed(new AvailabilityException("No seats available"))
  } yield result
}
```

**Proposed Improvement for `ports/UpgradeAdapter.scala:L5`**
```scala
// Before:
import com.copa.booking.domain.commands.UpgradeCommand

// After:
// Define an 'UpgradePort' interface in the core/application layer 
// and implement it here to avoid direct domain dependency.
trait UpgradePort {
  def execute(data: UpgradeRequest): Future[UpgradeResponse]
}
```

---

#### Team Discussion Review (Azure Threads)
| Discussion | Status | Note |
|------------|--------|------|
| Price Calculation logic | ✅ Resolved | Anibal suggested using `BigDecimal` for currency. Developer implemented in `L32`. |
| Logger implementation  | ⚠️ Open | Emilio suggested replacing `println`. Still present in `UpgradeController.scala:L50`. |

---

#### Summary
The PR implements the basic UI-to-DB flow but skips a critical business validation (Availability). It also introduces a hexagonal architecture violation. **Changes are required for merge.**