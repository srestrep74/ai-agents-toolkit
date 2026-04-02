"""
ECSClient — all ECS operations needed by skills.

Inherits session management and error handling from AWSBaseClient.
Each public method maps to one clear ECS responsibility.

Usage:
    client = ECSClient(region="us-east-1")
    data = client.get_service_data(cluster="ibe_cluster_dev", service="booking")
"""

import logging

from botocore.exceptions import ClientError

from ..base_client import AWSBaseClient
from ..exceptions import (
    AWSSkillError,
    ClusterNotFoundError,
    ServiceNotFoundError,
    TaskDefinitionError,
)
from ..ecs.ecs_models import ServiceData

logger = logging.getLogger(__name__)


class ECSClient(AWSBaseClient):
    """
    High-level ECS client for skills.

    Wraps boto3 ECS calls into domain-meaningful methods that return
    typed models instead of raw dicts.
    """

    SERVICE = "ecs"

    def get_task_definition_arn(self, cluster: str, service: str) -> str:
        try:
            response = self._call(
                self._client.describe_services,
                cluster=cluster,
                services=[service],
            )
        except AWSSkillError as e:
            if "ClusterNotFoundException" in str(e.details or ""):
                raise ClusterNotFoundError(
                    f"Cluster '{cluster}' not found.", details=e.details
                ) from e
            raise

        services = response.get("services", [])
        task_def = services[0].get("taskDefinition") if services else None

        if not services or not task_def or task_def in ("None", ""):
            raise ServiceNotFoundError(
                f"Service '{service}' not found in cluster '{cluster}'."
            )

        logger.debug("Resolved task definition: %s", task_def)
        return task_def

    def get_container_definition(self, task_def_arn: str, container_index: int = 0) -> dict:
        try:
            response = self._call(
                self._client.describe_task_definition,
                taskDefinition=task_def_arn,
            )
        except AWSSkillError as e:
            raise TaskDefinitionError(
                f"Could not retrieve task definition '{task_def_arn}'.",
                details=e.details,
            ) from e

        containers = response.get("taskDefinition", {}).get("containerDefinitions", [])

        if not containers:
            raise TaskDefinitionError(
                f"Task definition '{task_def_arn}' has no container definitions."
            )

        if container_index >= len(containers):
            raise TaskDefinitionError(
                f"Container index {container_index} out of range "
                f"(task definition has {len(containers)} container(s))."
            )

        return containers[container_index]

    def get_service_data(self, cluster: str, service: str, container_index: int = 0) -> ServiceData:
        task_def_arn = self.get_task_definition_arn(cluster, service)
        container = self.get_container_definition(task_def_arn, container_index)

        return ServiceData.from_raw(
            cluster=cluster,
            service=service,
            image=container.get("image", ""),
            raw_env=container.get("environment", []),
        )

    def list_services(self, cluster: str) -> list[str]:
        try:
            paginator = self._client.get_paginator("list_services")
            pages = paginator.paginate(cluster=cluster)
            return [arn for page in pages for arn in page.get("serviceArns", [])]
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code == "ClusterNotFoundException":
                raise ClusterNotFoundError(
                    f"Cluster '{cluster}' not found.", details=str(e)
                ) from e
            raise AWSSkillError(
                f"Error listing services in cluster '{cluster}': {e}"
            ) from e