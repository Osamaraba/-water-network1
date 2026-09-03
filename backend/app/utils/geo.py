from typing import Optional
from geoalchemy2 import Geometry
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


def make_point(lng: float, lat: float) -> str:
    return f"SRID=4326;POINT({lng} {lat})"


def haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    import math
    R = 6371000
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
