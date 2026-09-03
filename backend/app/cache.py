"""
Redis Caching Layer for Yarmouk Water Management Pro
Provides caching for frequently accessed data like org tree, permissions, templates.

Usage:
    from app.cache import cache
    
    # Get cached value
    value = await cache.get("org_tree")
    
    # Set cached value with TTL (in seconds)
    await cache.set("org_tree", org_tree_data, ttl=300)
    
    # Delete cached value
    await cache.delete("org_tree")
    
    # Clear all cache
    await cache.clear()
"""
import json
import logging
from typing import Any, Optional
from app.config import settings

logger = logging.getLogger(__name__)


class RedisCache:
    """Redis cache wrapper with fallback to in-memory cache."""
    
    def __init__(self):
        self._redis = None
        self._memory_cache = {}
        self._connected = False
    
    async def connect(self):
        """Connect to Redis (optional - falls back to memory cache)."""
        try:
            import redis.asyncio as aioredis
            self._redis = await aioredis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=5,
            )
            await self._redis.ping()
            self._connected = True
            logger.info("Redis connected successfully")
        except Exception as e:
            logger.warning(f"Redis not available, using memory cache: {e}")
            self._connected = False
    
    async def disconnect(self):
        """Disconnect from Redis."""
        if self._redis:
            await self._redis.close()
            self._connected = False
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if self._connected and self._redis:
            try:
                value = await self._redis.get(key)
                if value:
                    return json.loads(value)
                return None
            except Exception as e:
                logger.error(f"Redis get error: {e}")
                return self._memory_cache.get(key)
        return self._memory_cache.get(key)
    
    async def set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """Set value in cache with TTL in seconds."""
        try:
            serialized = json.dumps(value, default=str)
            
            if self._connected and self._redis:
                await self._redis.setex(key, ttl, serialized)
            else:
                self._memory_cache[key] = value
            
            return True
        except Exception as e:
            logger.error(f"Redis set error: {e}")
            self._memory_cache[key] = value
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete value from cache."""
        try:
            if self._connected and self._redis:
                await self._redis.delete(key)
            
            self._memory_cache.pop(key, None)
            return True
        except Exception as e:
            logger.error(f"Redis delete error: {e}")
            return False
    
    async def clear(self) -> bool:
        """Clear all cache."""
        try:
            if self._connected and self._redis:
                await self._redis.flushdb()
            
            self._memory_cache.clear()
            return True
        except Exception as e:
            logger.error(f"Redis clear error: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        if self._connected and self._redis:
            try:
                return await self._redis.exists(key) > 0
            except Exception:
                return key in self._memory_cache
        return key in self._memory_cache
    
    @property
    def is_connected(self) -> bool:
        return self._connected


# Global cache instance
cache = RedisCache()


# =============================================================================
# Cache Keys
# =============================================================================

class CacheKeys:
    """Cache key constants."""
    ORG_TREE = "yarmouk:org_tree"
    PERMISSIONS_PREFIX = "yarmouk:permissions:"
    EMPLOYEE_PREFIX = "yarmouk:employee:"
    REPORTS_DASHBOARD = "yarmouk:reports:dashboard"
    ATTENDANCE_SUMMARY = "yarmouk:attendance:summary"


# =============================================================================
# Cache Decorator
# =============================================================================

def cached(prefix: str, ttl: int = 300):
    """
    Decorator for caching async function results.
    
    Usage:
        @cached(prefix="org_tree", ttl=600)
        async def get_org_tree():
            # expensive database query
            return org_tree
    """
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            key = f"{prefix}:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # Try to get from cache
            result = await cache.get(key)
            if result is not None:
                return result
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            await cache.set(key, result, ttl)
            return result
        
        return wrapper
    return decorator
