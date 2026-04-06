import json
import sys

from shared.aws.ecs.ecs_client import ECSClient
from shared.aws.exceptions import AWSSkillError, AuthError
from shared.aws.ecs.ecs_models import CompareResult, EnvVar, EnvVarMismatch, ServiceData


class EnvComparer:
    def __init__(
        self,
        cluster_a: str,
        cluster_b: str,
        service: str,
        region: str = "us-east-1",
    ) -> None:
        self.cluster_a = cluster_a
        self.cluster_b = cluster_b
        self.service = service
        self._client = ECSClient(region=region)

    def compare(self) -> CompareResult:
        data_a = self._client.get_service_data(cluster=self.cluster_a, service=self.service)
        data_b = self._client.get_service_data(cluster=self.cluster_b, service=self.service)
        return self._diff(data_a, data_b)

    def run(self) -> None:
        try:
            result = self.compare()
        except AuthError as e:
            print(json.dumps(e.to_dict()), file=sys.stderr)
            sys.exit(2)
        except AWSSkillError as e:
            print(json.dumps(e.to_dict()), file=sys.stderr)
            sys.exit(1)

        print(json.dumps(result.to_dict(), indent=2))

    @staticmethod
    def _diff(data_a: ServiceData, data_b: ServiceData) -> CompareResult:
        map_a = data_a.as_env_map()
        map_b = data_b.as_env_map()

        keys_a, keys_b = set(map_a), set(map_b)

        missing_in_b = sorted(
            [EnvVar(name=k, value=map_a[k]) for k in keys_a - keys_b],
            key=lambda e: e.name,
        )
        missing_in_a = sorted(
            [EnvVar(name=k, value=map_b[k]) for k in keys_b - keys_a],
            key=lambda e: e.name,
        )
        mismatches = sorted(
            [
                EnvVarMismatch(name=k, value_a=map_a[k], value_b=map_b[k])
                for k in keys_a & keys_b
                if map_a[k] != map_b[k]
            ],
            key=lambda m: m.name,
        )
        identical_count = len(keys_a & keys_b) - len(mismatches)

        return CompareResult(
            service=data_a.service,
            cluster_a=data_a.cluster,
            cluster_b=data_b.cluster,
            version_a=data_a.version,
            version_b=data_b.version,
            image_a=data_a.image,
            image_b=data_b.image,
            missing_in_b=missing_in_b,
            missing_in_a=missing_in_a,
            mismatches=mismatches,
            identical_count=identical_count,
        )


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(json.dumps({"error": "usage", "message": "Usage: compare_envvars.py <clusterA> <clusterB> <service> [--region <region>]"}), file=sys.stderr)
        sys.exit(1)

    _region = "us-east-1"
    if "--region" in sys.argv:
        _region = sys.argv[sys.argv.index("--region") + 1]

    EnvComparer(cluster_a=sys.argv[1], cluster_b=sys.argv[2], service=sys.argv[3], region=_region).run()