"""
Shared exception hierarchy for all AWS skills.

Usage:
    from _shared.aws.exceptions import AWSSkillError, AuthError, ECSError
"""


class AWSSkillError(Exception):
    def __init__(self, message: str, details: str | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.details = details

    def to_dict(self) -> dict:
        result = {"error": self.__class__.__name__, "message": self.message}
        if self.details:
            result["details"] = self.details
        return result


class AuthError(AWSSkillError):
    """AWS credentials missing, expired, or insufficient (MFA / SSO)."""


class ECSError(AWSSkillError):
    """Base exception for ECS operations."""


class ClusterNotFoundError(ECSError):
    """ECS cluster does not exist or is not accessible."""


class ServiceNotFoundError(ECSError):
    """ECS service not found inside the given cluster."""


class TaskDefinitionError(ECSError):
    """Could not retrieve or parse the task definition."""
 