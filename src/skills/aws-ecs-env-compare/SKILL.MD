---
name: aws-ecs-env-compare
description: "Compare environment variables and deployed versions for a microservice across two ECS clusters."
---

# ☁️ AWS ECS Environment Compare

Compare environment variables and deployed versions for a microservice across two ECS clusters. 

## When to Use
- Comparing environment variables for the same microservice across two ECS clusters (e.g., dev vs. prod).
- Checking if the deployed version differs between environments.
- Analyzing configuration drift to detect missing or divergent values.

---

## Critical Rules
- ALWAYS require three inputs: `clusterA`, `clusterB`, and `microservice`.
- ALWAYS validate inputs against known clusters and services.
- ALWAYS extract the deployed version from the `image` field.
- NEVER include Secrets Manager ARNs or SSM Parameter Store references.
- ALWAYS present results in three sections: Missing in B, Missing in A, Value Mismatches.

---

## Commands

```bash
# Compare env vars between two clusters
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py <clusterA> <clusterB> <service>
```

---

## Resources
- **Script**: [`aws-ecs-env-compare/scripts/compare_envvars.py`](scripts/compare_envvars.py)
