"""
Dataclass models for ECS skill data.

These are plain data containers — no AWS logic here.
"""

from dataclasses import dataclass, field


@dataclass(frozen=True)
class EnvVar:
    name: str
    value: str


@dataclass(frozen=True)
class ServiceData:
    cluster: str
    service: str
    image: str
    version: str
    environment: tuple[EnvVar, ...]

    @classmethod
    def from_raw(cls, cluster: str, service: str, image: str, raw_env: list[dict]) -> "ServiceData":
        version = image.split(":")[-1] if ":" in image else "unknown"
        env_vars = tuple(
            sorted(
                (EnvVar(name=e["name"], value=e["value"]) for e in raw_env),
                key=lambda e: e.name,
            )
        )
        return cls(cluster=cluster, service=service, image=image, version=version, environment=env_vars)

    def as_env_map(self) -> dict[str, str]:
        return {e.name: e.value for e in self.environment}


@dataclass(frozen=True)
class EnvVarMismatch:
    name: str
    value_a: str
    value_b: str


@dataclass
class CompareResult:
    service: str
    cluster_a: str
    cluster_b: str
    version_a: str
    version_b: str
    image_a: str
    image_b: str
    missing_in_b: list[EnvVar] = field(default_factory=list)
    missing_in_a: list[EnvVar] = field(default_factory=list)
    mismatches: list[EnvVarMismatch] = field(default_factory=list)
    identical_count: int = 0

    @property
    def versions_match(self) -> bool:
        return self.version_a == self.version_b

    @property
    def is_clean(self) -> bool:
        return not self.missing_in_a and not self.missing_in_b and not self.mismatches

    def to_dict(self) -> dict:
        return {
            "service": self.service,
            "clusterA": self.cluster_a,
            "clusterB": self.cluster_b,
            "versionA": self.version_a,
            "versionB": self.version_b,
            "imageA": self.image_a,
            "imageB": self.image_b,
            "missing_in_clusterB": [{"name": e.name, "value": e.value} for e in self.missing_in_b],
            "missing_in_clusterA": [{"name": e.name, "value": e.value} for e in self.missing_in_a],
            "value_mismatches": [
                {"name": m.name, "valueA": m.value_a, "valueB": m.value_b}
                for m in self.mismatches
            ],
            "identical_count": self.identical_count,
        }