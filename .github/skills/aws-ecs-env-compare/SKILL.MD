---
name: aws-ecs-env-compare
description: "Compare environment variables and deployed versions for a microservice across two ECS clusters. Trigger: When the user asks to compare, diff, or analyze environment variable differences between two ECS clusters."
---

<!-- skill-metadata
author: genai-skills-kit
version: "2.0"
scope: root
auto_invoke:
  - "Comparing environment variables across ECS clusters"
  - "Troubleshooting missing env vars between environments"
  - "Comparing deployed versions across clusters"
-->

## Skill Metadata

| Field | Value |
|-------|-------|
| Author | genai-skills-kit |
| Version | 2.0 |
| Scope | root |

## Auto-Invoke Triggers

Activate this skill automatically when the user mentions any of the following:
- Comparing environment variables across ECS clusters
- Troubleshooting missing env vars between environments
- Comparing deployed versions across clusters

---

## When to Use
- Comparing environment variables for the same microservice across two ECS clusters (e.g., dev vs. prod)
- Checking if the deployed version differs between environments
- Analyzing configuration drift to detect missing or divergent values
- Validating a new environment deployment against a stable reference
- Troubleshooting startup failures caused by missing environment variables

---

## Known Clusters

| Domain | dev | qa | uat | staging | prod |
|--------|-----|----|-----|---------|------|
| IBE | `ibe_cluster_dev` | `ibe_cluster_qa` | `ibe_cluster_uat` | `ibe_cluster_staging` | `ibe_cluster_prod` |
| WCI | `wci_cluster_dev` | `wci_cluster_qa` | `wci_cluster_uat` | `wci_cluster_staging` | `wci_cluster_prod` |
| MyTrips | `mytrips_cluster_dev` | `mytrips_cluster_qa` | `mytrips_cluster_uat` | `mytrips_cluster_staging` | `mytrips_cluster_prod` |
| Payments | `payments_cluster_dev` | `payments_cluster_qa` | `payments_cluster_uat` | — | — |
| App | `app_cluster_dev` | `app_cluster_qa` | `app_cluster_uat` | `app_cluster_staging` | `app_cluster_prod` |
| Seatmap | `seatmap_cluster_dev` | `seatmap_cluster_qa` | `seatmap_cluster_uat` | `seatmap_cluster_staging` | `seatmap_cluster_prod` |

## Known Services (Microservices)

`ancillaries` · `booking` · `triphub` · `boardingpass` · `catalog` · `contents` · `documents` · `flightmap` · `payment` · `loyalty` · `rebooking` · `refund` · `reservation` · `session`

---

## Critical Rules

- ALWAYS require three inputs: `clusterA`, `clusterB`, and `microservice`
- ALWAYS validate inputs against the known clusters and services listed above
- ALWAYS use the comparison script to fetch and diff real data — NEVER fabricate values
- ALWAYS extract the deployed version from the `image` field by parsing the tag after the colon (e.g., `345556555012.dkr.ecr.us-east-1.amazonaws.com/copa-booking:1.29.1-dev` → `1.29.1-dev`)
- ALWAYS show both deployed versions prominently at the top of the diff report
- NEVER include Secrets Manager ARNs or SSM Parameter Store references
- ALWAYS normalize env var arrays into key-value maps before comparing (array order may differ)
- ALWAYS present results in three sections: Missing in B, Missing in A, Value Mismatches
- If the user says environment names (e.g., "dev vs prod") without the full cluster name, ask which domain (IBE, WCI, MyTrips, etc.)

---

## Decision Tree

```
User asks to compare env vars?
├── All three inputs provided (clusterA, clusterB, microservice)?
│   ├── Yes → validate against known values → execute script
│   └── No → ask for missing input(s)
│       ├── User said "dev vs prod"? → ask: which domain? (IBE, WCI, etc.)
│       └── User said domain without envs? → ask: which two environments?
├── Script succeeded (exit code 0)?
│   ├── Yes → parse JSON from stdout
│   │   ├── Extract versions from versionA / versionB fields
│   │   ├── Show versions prominently (highlight if different)
│   │   └── Present structured diff report
│   └── No → read JSON error from stderr
│       ├── error = "auth" (exit 2) → ask user to re-authenticate (MFA/SSO)
│       └── error = "ecs"  (exit 1) → report cluster or service not found
└── Done
```

---

## Commands

```bash
# Compare env vars between two clusters
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py <clusterA> <clusterB> <service>

# Examples
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py ibe_cluster_dev ibe_cluster_prod booking
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py wci_cluster_qa wci_cluster_uat reservation
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py payments_cluster_dev payments_cluster_qa payment

# Optional: specify a non-default AWS region
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py ibe_cluster_dev ibe_cluster_prod booking --region us-west-2
```

---

## Expected Output

stdout — JSON on success:

```json
{
  "service": "booking",
  "clusterA": "ibe_cluster_dev",
  "clusterB": "ibe_cluster_prod",
  "versionA": "1.31.0-dev",
  "versionB": "1.29.1",
  "imageA": "123456789.dkr.ecr.us-east-1.amazonaws.com/copa-booking:1.31.0-dev",
  "imageB": "123456789.dkr.ecr.us-east-1.amazonaws.com/copa-booking:1.29.1",
  "missing_in_clusterB": [{ "name": "NEW_FEATURE_FLAG", "value": "true" }],
  "missing_in_clusterA": [],
  "value_mismatches": [
    { "name": "API_URL", "valueA": "https://api.dev.example.com", "valueB": "https://api.example.com" }
  ],
  "identical_count": 42
}
```

stderr — JSON on error:

```json
{ "error": "AuthError", "message": "AWS credentials expired. Please re-authenticate (MFA/SSO)." }
{ "error": "ServiceNotFoundError", "message": "Service 'booking' not found in cluster 'ibe_cluster_dev'." }
```

Exit codes: `0` = success · `1` = ECS/AWS error · `2` = auth error

---

## Resources

- **Script**: [`aws-ecs-env-compare/scripts/compare_envvars.py`](scripts/compare_envvars.py)
- **Depends on**: [`_shared/aws/ecs_client.py`](../shared/aws/ecs/ecs_client.py) · [`_shared/models/ecs_models.py`](../shared/aws/ecs/ecs_models.py)
- **Examples**: See [`examples/`](examples/) for sample JSON outputs and presentation templates:

  | File | Description |
  |------|-------------|
  | `output-booking-dev-vs-prod.json` | Raw JSON — booking dev↔prod (1 missing, 10 mismatches) |
  | `output-reservation-qa-vs-uat.json` | Raw JSON — reservation qa↔uat (1 new var in uat) |
  | `output-payment-dev-vs-qa.json` | Raw JSON — payment dev↔qa (healthy, no missing vars) |
  | `presentation-booking-dev-vs-prod.md` | Presentation template — worst case |
  | `presentation-reservation-qa-vs-uat.md` | Presentation template — new feature flag |
  | `presentation-payment-dev-vs-qa.md` | Presentation template — healthy environments |