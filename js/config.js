/**
 * تطبيق شركة مياه اليرموك - ملف الإعدادات
 * Water Network Configuration
 */

const CONFIG = {
  // الخريطة
  MAP: {
    DEFAULT_CENTER: [32.3499, 35.7483],
    DEFAULT_ZOOM: 13,
    MAX_ZOOM: 20,
    MIN_ZOOM: 8
  },

  // التخزين
  STORAGE: {
    DB_NAME: 'WaterNetworkDB',
    DB_VERSION: 1,
    STORES: {
      SUBSCRIBERS: 'subscribers',
      PUMPS: 'pumps',
      TANKS: 'tanks',
      MANHOLES: 'manholes',
      WATERLINES: 'waterlines',
      SEWERLINES: 'sewerlines',
      GRAVITYLINES: 'gravitylines',
      NEIGHBORHOODS: 'neighborhoods',
      COMPLAINTS: 'complaints',
      WORKERS: 'workers',
      SNAPSHOTS: 'snapshots'
    },
    CACHE_VERSION: 'water-pump-v7'
  },

  // الألوان والرموز
  STYLES: {
    PUMPS: { color: '#FFD54F', icon: '🏭', label: 'دور ضخ' },
    INSPECTION: { color: '#F48FB1', icon: '👁️', label: 'نظارة' },
    PUMPSTOP: { color: '#EF5350', icon: '⛔', label: 'توقف ضخ' },
    TANK: { color: '#4DD0E1', icon: '🚰', label: 'خزان' },
    MANHOLE: { color: '#A1887F', icon: '🕳️', label: 'منهول' },
    WATERLINE: { color: '#29B6F6', icon: '🔵', label: 'خط مياه' },
    SEWERLINE: { color: '#8D6E63', icon: '🟤', label: 'خط صرف' },
    GRAVITYLINE: { color: '#AB47BC', icon: '🟣', label: 'خط جباه' },
    COMPLAINT: { color: '#FF7043', icon: '📋', label: 'بلاغ' }
  },

  // الحدود الزمنية
  TIMEOUTS: {
    ELEVATION_API: 15000,
    SYNC_INTERVAL: 300000,
    AUTO_SAVE_INTERVAL: 30000,
    TOAST_DURATION: 3000
  },

  // الـ API endpoints
  APIS: {
    ELEVATION: 'https://api.open-elevation.com/api/v1/lookup',
    TILES: [
      {
        name: 'شارع',
        url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        maxZoom: 19,
        attr: '© OpenStreetMap'
      }
    ]
  },

  // الحدود القصوى
  LIMITS: {
    MAX_FILE_SIZE: 50 * 1024 * 1024,
    MAX_POINTS_PER_BATCH: 20,
    MAX_ELEVATION_BATCH: 20
  },

  // القرى
  VILLAGES: [
    'عجلون', 'عنجرة', 'صخرة', 'عبين', 'عين جنا',
    'كفرنجة', 'راجب', 'حلاوة', 'وادي الريان', 'إصفت', 'بسطة'
  ]
};

export default CONFIG;
