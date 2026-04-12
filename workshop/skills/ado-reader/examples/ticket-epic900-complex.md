# EPIC-900: Overhaul the Payment Gateway Integration (Stripe v3)

## Metadata
- **Type**: Epic
- **State**: Doing
- **Sprint**: Q1-Release
- **Assignee**: Andrea Lead
- **Story Points**: 21

## Description
Our current Stripe integration uses deprecated v2 APIs, leading to failed 3D Secure authentications in European markets. We need to upgrade the entire backend payment flow to Stripe API v3 (PaymentIntents). This epic covers the core orchestration, webhook handling, and database schema updates required to store intent IDs instead of raw transaction references. 

This must be fully backward-compatible with our existing frontend until the new UI is deployed.

## Acceptance Criteria
- 1. Stripe PaymentIntents API must be used for all new transactions.
- 2. Webhooks must asynchronously verify `payment_intent.succeeded` events.
- 3. Database schema for `transactions` table must include a nullable `stripe_intent_id` VARCHAR(255).
- 4. Graceful fallback to legacy processing must be disabled via an environment variable flag.
- 5. No customer card data must touch our servers directly (PCI compliance).

## Tasks / Child Items
- [ ] 901: Update `pom.xml` dependencies for latest Stripe Java SDK
- [ ] 902: Create Database Migration script for `transactions` table
- [ ] 903: Implement `PaymentIntentService` orchestration logic
- [ ] 904: Create `StripeWebhookController` for async confirmations
- [ ] 905: Conduct Security and PCI Compliance review

## Relevant Comments
- **Andrea Lead (2025-11-10)**: Let's make sure we do not drop the existing Webhook handler yet. We need both v2 and v3 handlers running in parallel during the migration window.
- **David DBA (2025-11-12)**: The DB migration script is approved, but note that the table lock will take approx 3 minutes in production. I've scheduled it for the midnight maintenance window.
- **Andrea Lead (2025-11-15)**: Please check with Frontend team regarding AC #1. They need to pass the `client_secret` back to us. I linked their PR to task 903.
