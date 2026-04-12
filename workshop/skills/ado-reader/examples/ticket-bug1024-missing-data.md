# BUG-1024: NullPointerException in CheckoutController During Guest Checkout Submit

## Metadata
- **Type**: Bug
- **State**: New
- **Sprint**: Unassigned
- **Assignee**: Unassigned
- **Story Points**: Not estimated

---

## Description

A recurring `NullPointerException` has been reported in production logs originating from `CheckoutController` when a user attempts to submit a payment using a **guest profile** (no authenticated session). The issue was introduced after the deployment of release **v2.10.4** on 2026-03-10.

Stack trace indicates the NPE is thrown in `UserService.enrichProfileData()` when called without a valid session token, as it attempts to dereference profile attributes that are null for guest users.

**Affected release:** v2.10.4  
**Environment:** Production  
**Frequency:** ~30 occurrences/hour per monitoring alerts

---

## Acceptance Criteria

*(No Acceptance Criteria provided in ADO — this is normal for a hot bug. Derive from bug description.)*

Based on the description, the implicit expectations are:
- Guest users must be able to complete the checkout flow without a `NullPointerException`.
- `UserService.enrichProfileData()` must handle null or empty session gracefully.
- No regression on authenticated user checkout flows.

---

## Stack Trace (from ticket body)

```
java.lang.NullPointerException
  at com.copa.digital.UserService.enrichProfileData(UserService.java:145)
  at com.copa.digital.CheckoutController.submitPayment(CheckoutController.java:88)
  at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
  ...
```

---

## Tasks / Child Items

*(No child tasks found — this is common for newly created bugs)*

---

## Relevant Comments

*(No comments found — ticket was just created)*
