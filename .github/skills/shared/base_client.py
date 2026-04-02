import logging
from typing import Any, Callable

import boto3
from botocore.exceptions import (
    ClientError,
    EndpointResolutionError,
    NoCredentialsError,
    NoRegionError,
    TokenRetrievalError,
)

from .exceptions import AuthError, AWSSkillError

logger = logging.getLogger(__name__)

_AUTH_ERROR_CODES = frozenset({
    "ExpiredTokenException",
    "InvalidClientTokenId",
    "AuthFailure",
    "AccessDeniedException",
    "UnauthorizedOperation",
})


class AWSBaseClient:
    """
    Base class for all AWS service clients used in skills.

    Subclasses must define:
        SERVICE: str  — the boto3 service name (e.g. "ecs", "logs", "secretsmanager")

    Subclasses should use `self._call()` for all boto3 invocations to get
    consistent error handling and logging for free.
    """

    SERVICE: str = ""

    def __init__(self, region: str = "us-east-1", profile: str | None = None) -> None:
        if not self.SERVICE:
            raise NotImplementedError(f"{self.__class__.__name__} must define SERVICE.")

        self._region = region
        self._profile = profile
        self._client = self._build_client()

    @property
    def region(self) -> str:
        return self._region

    def _build_client(self) -> Any:
        try:
            session = boto3.Session(profile_name=self._profile)
            client = session.client(self.SERVICE, region_name=self._region)
            return client
        except NoCredentialsError as e:
            raise AuthError(
                "AWS credentials not found. Configure ~/.aws/credentials or set "
                "AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY environment variables.",
                details=str(e),
            ) from e
        except NoRegionError as e:
            raise AuthError(
                f"No AWS region specified. Pass --region or set AWS_DEFAULT_REGION.",
                details=str(e),
            ) from e

    def _call(self, method: Callable, **kwargs: Any) -> dict:
        method_name = getattr(method, "__name__", str(method))
        logger.debug("Calling %s.%s with %s", self.SERVICE, method_name, kwargs)

        try:
            response = method(**kwargs)
            logger.debug("%s.%s succeeded", self.SERVICE, method_name)
            return response

        except (NoCredentialsError, TokenRetrievalError) as e:
            raise AuthError(
                "AWS credentials expired or missing. Please re-authenticate (MFA/SSO).",
                details=str(e),
            ) from e

        except ClientError as e:
            code = e.response["Error"]["Code"]
            message = e.response["Error"]["Message"]

            if code in _AUTH_ERROR_CODES:
                raise AuthError(
                    f"AWS permission denied ({code}): {message}",
                    details=str(e),
                ) from e

            raise AWSSkillError(
                f"AWS error calling {self.SERVICE}.{method_name} [{code}]: {message}",
                details=str(e),
            ) from e

        except EndpointResolutionError as e:
            raise AWSSkillError(
                f"Could not resolve AWS endpoint for service '{self.SERVICE}' "
                f"in region '{self._region}'. Check region and network connectivity.",
                details=str(e),
            ) from e