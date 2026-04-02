# Example: `booking` — `ibe_cluster_dev` vs `ibe_cluster_prod`

## Command

```bash
python .github/skills/aws-ecs-env-compare/scripts/compare_envvars.py ibe_cluster_dev ibe_cluster_prod booking
```

## Raw Output (`stdout`)

```json
{
  "service": "booking",
  "clusterA": "ibe_cluster_dev",
  "clusterB": "ibe_cluster_prod",
  "versionA": "1.31.0-dev",
  "versionB": "1.29.1",
  "imageA": "123456789012.dkr.ecr.us-east-1.amazonaws.com/copa-booking:1.31.0-dev",
  "imageB": "123456789012.dkr.ecr.us-east-1.amazonaws.com/copa-booking:1.29.1",
  "missing_in_clusterB": [
    { "name": "ENABLE_INSTANT_UPGRADE", "value": "true" }
  ],
  "missing_in_clusterA": [],
  "value_mismatches": [
    { "name": "DB_CONNECTION_TIMEOUT",      "valueA": "5000",                                        "valueB": "10000" },
    { "name": "DB_HOST",                    "valueA": "booking-db.dev.internal",                     "valueB": "booking-db.prod.internal" },
    { "name": "DB_NAME",                    "valueA": "booking_dev",                                 "valueB": "booking_prod" },
    { "name": "DB_POOL_SIZE",               "valueA": "10",                                          "valueB": "50" },
    { "name": "ENABLE_FEATURE_MILES_BOOSTER","valueA": "true",                                       "valueB": "false" },
    { "name": "KAFKA_BROKERS",              "valueA": "kafka-dev-1:9092,kafka-dev-2:9092",           "valueB": "kafka-prod-1:9092,kafka-prod-2:9092,kafka-prod-3:9092" },
    { "name": "LOG_LEVEL",                  "valueA": "DEBUG",                                       "valueB": "WARN" },
    { "name": "NEW_RELIC_APP_NAME",         "valueA": "booking-api-dev",                             "valueB": "booking-api-prod" },
    { "name": "OSL_BASE_URL",               "valueA": "https://osl-dev.internal.api/v1",             "valueB": "https://osl.internal.api/v1" },
    { "name": "OSL_TIMEOUT_DEFAULT",        "valueA": "30000",                                       "valueB": "15000" }
  ],
  "identical_count": 4
}
```

---

## Expected Presentation

### Environment Diff: `booking`

| | `ibe_cluster_dev` | `ibe_cluster_prod` |
|---|---|---|
| **Version** | `1.31.0-dev` | `1.29.1` |
| **Total vars** | 16 | 15 |

> Versions differ. `ibe_cluster_dev` is ahead by 2 minor versions.

---

### Missing in `ibe_cluster_prod` (1)

| Variable | Value in `ibe_cluster_dev` |
|----------|----------------------------|
| `ENABLE_INSTANT_UPGRADE` | `true` |

> `ENABLE_INSTANT_UPGRADE` exists in dev but not in prod. Likely an unreleased feature flag — confirm before promoting to production.

---

### Missing in `ibe_cluster_dev` (0)

None. All variables present in `ibe_cluster_prod` also exist in `ibe_cluster_dev`.

---

### Value Mismatches (10)

| Variable | `ibe_cluster_dev` | `ibe_cluster_prod` |
|----------|--------------------|--------------------|
| `DB_CONNECTION_TIMEOUT` | `5000` | `10000` |
| `DB_HOST` | `booking-db.dev.internal` | `booking-db.prod.internal` |
| `DB_NAME` | `booking_dev` | `booking_prod` |
| `DB_POOL_SIZE` | `10` | `50` |
| `ENABLE_FEATURE_MILES_BOOSTER` | `true` | `false` |
| `KAFKA_BROKERS` | `kafka-dev-1:9092,kafka-dev-2:9092` | `kafka-prod-1:9092,kafka-prod-2:9092,kafka-prod-3:9092` |
| `LOG_LEVEL` | `DEBUG` | `WARN` |
| `NEW_RELIC_APP_NAME` | `booking-api-dev` | `booking-api-prod` |
| `OSL_BASE_URL` | `https://osl-dev.internal.api/v1` | `https://osl.internal.api/v1` |
| `OSL_TIMEOUT_DEFAULT` | `30000` | `15000` |

Notable mismatches:
- `DB_POOL_SIZE` is `10` in dev vs `50` in prod — expected for load differences, but worth validating in load tests.
- `ENABLE_FEATURE_MILES_BOOSTER` is `true` in dev and `false` in prod — feature is enabled in dev only.
- `OSL_TIMEOUT_DEFAULT` is higher in dev (`30000`) than in prod (`15000`) — prod is more aggressive; confirm this is intentional.

---

### Identical (4)

`APP_NAME` · `APP_PORT` · `DB_PORT` · `NEW_RELIC_ENABLED`

---

### Summary

| | Count |
|---|---|
| Missing in `ibe_cluster_prod` | 1 |
| Missing in `ibe_cluster_dev` | 0 |
| Value mismatches | 10 |
| Identical | 4 |
| **Total** | **15 / 16** |

**Action required:** Review `ENABLE_INSTANT_UPGRADE` before promoting dev configuration to production.