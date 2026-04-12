# US-4821: Multi-city Search — Implement Layover Duration Filter for PTY Connections

## Metadata
- **Type**: User Story
- **State**: Active
- **Sprint**: Sprint 42
- **Assignee**: Sebastian
- **Story Points**: 5

---

## Description

As a customer searching for multi-city itineraries, I should only see flight options where the PTY (Panama City) connection layover is between 12 and 24 hours, so that I am not presented with operationally unfeasible or extremely long connection times.

**Context:**
The multi-city search engine currently returns all itineraries regardless of layover duration at PTY. The business rule is specific to this hub. Other hubs (BOG, SAL, etc.) must **not** be affected by this filter. Filtering is applied silently — rejected itineraries are removed from results with no warning code returned to the client.

---

## Acceptance Criteria

- A PTY layover of **exactly 12 hours** must be **accepted** and appear in results.
- A PTY layover of **exactly 24 hours** must be **accepted** and appear in results.
- A PTY layover of **more than 24 hours** must be **rejected** and removed from results.
- A PTY layover of **less than 12 hours** must be **rejected** and removed from results.
- Rejected itineraries must **not** trigger an error response — HTTP status remains **200** with a filtered result set.
- This rule applies **only** to PTY. No other hubs should be filtered by this logic.

---

## Endpoint Under Modification

| Field | Value |
|---|---|
| **Endpoint** | `GET /flights/multicity/search` |
| **Filter Applied** | Post-processing on response, before returning to client |
| **Success Response** | HTTP 200 — filtered `ItineraryListResponse` |
| **No match Response** | HTTP 200 — empty `itineraries: []` |

---

## Business Rules

| Condition | Result |
|---|---|
| PTY layover >= 12h AND <= 24h | Included in results |
| PTY layover < 12h | Filtered out silently |
| PTY layover > 24h | Filtered out silently |
| Non-PTY connection | Not affected, always passed through |

---

## Tasks / Child Items
- [ ] 4822: Update `FlightSearchService` to apply the layover duration filter for PTY connections
- [ ] 4823: Write unit tests covering all boundary conditions (11h, 12h, 24h, 25h, non-PTY hub)
- [ ] 4824: Update Swagger documentation to document the implicit filter behavior

---

## Relevant Comments
- **Carlos Reviewer (2026-03-18)**: Please make sure that this rule only applies to PTY. Other hubs like BOG or SAL should not be affected by this specific timing rule.
- **Maria QA (2026-03-19)**: Are we sending a specific warning code when itineraries are filtered out, or just silently removing them? Let me know for test cases.
- **Sebastian Dev (2026-03-19)**: Confirmed with Carlos — silent removal, no warning code. HTTP 200 always. Will reflect this in the unit tests.
