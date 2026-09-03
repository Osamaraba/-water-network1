from typing import Any, Optional


def success_response(data: Any = None, message: str = "Success") -> dict:
    return {
        "success": True,
        "message": message,
        "data": data,
        "errors": None,
    }


def error_response(message: str = "Error", errors: Any = None) -> dict:
    return {
        "success": False,
        "message": message,
        "data": None,
        "errors": errors,
    }


def paginated_response(items: list, total: int, skip: int, limit: int) -> dict:
    return {
        "success": True,
        "message": "Success",
        "data": {
            "items": items,
            "total": total,
            "skip": skip,
            "limit": limit,
        },
        "errors": None,
    }
