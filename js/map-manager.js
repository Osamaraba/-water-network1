/**
 * مدير الخرائط والطبقات
 * Map Manager
 */

import CONFIG from './config.js';
import GeospatialUtils from './geospatial-utils.js';

class MapManager {
  constructor(containerId = 'map') {
    this.map = null;
    this.containerId = containerId;
    this.layers = {};
    this.currentTileIndex = 0;
  }

  /**
   * تهيئة الخريطة
   */
  async initialize() {
    if (typeof L === 'undefined') {
      throw new Error('مكتبة Leaflet غير محملة');
    }

    const config = CONFIG.MAP;
    this.map = L.map(this.containerId, {
      center: config.DEFAULT_CENTER,
      zoom: config.DEFAULT_ZOOM,
      zoomControl: false,
      attributionControl: false
    });

    // إضافة عناصر التحكم
    L.control.zoom({ position: 'topright' }).addTo(this.map);

    // تحميل الطبقات الأساسية
    this.initializeLayers();
    this.loadTileLayer(0);

    return this.map;
  }

  /**
   * تهيئة طبقات البيانات
   */
  initializeLayers() {
    const layerNames = [
      'subscribers', 'pumps', 'tanks', 'manholes',
      'waterlines', 'sewerlines', 'gravitylines',
      'neighborhoods', 'complaints', 'workers', 'drawings'
    ];

    layerNames.forEach(name => {
      this.layers[name] = L.layerGroup().addTo(this.map);
    });
  }

  /**
   * تحميل طبقة الخريطة الأساسية
   */
  loadTileLayer(index) {
    if (this.layers.baseTile) {
      this.map.removeLayer(this.layers.baseTile);
    }

    const tileConfig = CONFIG.APIS.TILES[index];
    this.layers.baseTile = L.tileLayer(tileConfig.url, {
      maxZoom: tileConfig.maxZoom,
      attribution: tileConfig.attr
    }).addTo(this.map);

    this.currentTileIndex = index;
  }

  /**
   * التبديل بين طبقات الخرائط
   */
  switchTileLayer() {
    const nextIndex = (this.currentTileIndex + 1) % CONFIG.APIS.TILES.length;
    this.loadTileLayer(nextIndex);
    return CONFIG.APIS.TILES[nextIndex].name;
  }

  /**
   * إضافة علامة نقطة
   */
  addMarker(lat, lng, options = {}) {
    const {
      icon = '📍',
      title = '',
      color = '#42A5F5',
      size = 26,
      popup = '',
      layerName = 'subscribers'
    } = options;

    const marker = L.marker([lat, lng], {
      icon: L.divIcon({
        className: 'custom-marker',
        html: `<div style="
          width: ${size}px;
          height: ${size}px;
          background: ${color};
          border: 3px solid white;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: ${size * 0.6}px;
          box-shadow: 0 0 8px rgba(0,0,0,0.3);
        ">${icon}</div>`,
        iconSize: [size, size],
        iconAnchor: [size / 2, size / 2]
      }),
      title
    });

    if (popup) {
      marker.bindPopup(popup);
    }

    if (this.layers[layerName]) {
      this.layers[layerName].addLayer(marker);
    }

    return marker;
  }

  /**
   * إضافة خط (polyline)
   */
  addPolyline(coordinates, options = {}) {
    const {
      color = '#29B6F6',
      weight = 4,
      opacity = 0.8,
      popup = '',
      layerName = 'waterlines'
    } = options;

    const polyline = L.polyline(coordinates, {
      color,
      weight,
      opacity
    });

    if (popup) {
      polyline.bindPopup(popup);
    }

    if (this.layers[layerName]) {
      this.layers[layerName].addLayer(polyline);
    }

    return polyline;
  }

  /**
   * إضافة مضلع (polygon)
   */
  addPolygon(coordinates, options = {}) {
    const {
      color = '#3366FF',
      fillColor = '#3366FF',
      fillOpacity = 0.2,
      popup = '',
      layerName = 'neighborhoods'
    } = options;

    const polygon = L.polygon(coordinates, {
      color,
      fillColor,
      fillOpacity,
      weight: 3
    });

    if (popup) {
      polygon.bindPopup(popup);
    }

    if (this.layers[layerName]) {
      this.layers[layerName].addLayer(polygon);
    }

    return polygon;
  }

  /**
   * تركيز الخريطة على موقع معين
   */
  fitBounds(bounds, padding = 50) {
    this.map.fitBounds(bounds, { padding: [padding, padding] });
  }

  /**
   * تركيز الخريطة على نقطة معينة
   */
  panTo(lat, lng, zoom = null) {
    this.map.setView([lat, lng], zoom || this.map.getZoom());
  }

  /**
   * الحصول على الموقع الحالي
   */
  getCurrentLocation() {
    const center = this.map.getCenter();
    return {
      lat: center.lat,
      lng: center.lng
    };
  }

  /**
   * الحصول على حدود الخريطة الحالية
   */
  getBounds() {
    const bounds = this.map.getBounds();
    return {
      north: bounds.getNorth(),
      south: bounds.getSouth(),
      east: bounds.getEast(),
      west: bounds.getWest()
    };
  }

  /**
   * إظهار/إخفاء الطبقة
   */
  toggleLayer(layerName, visible) {
    if (this.layers[layerName]) {
      if (visible) {
        this.layers[layerName].addTo(this.map);
      } else {
        this.map.removeLayer(this.layers[layerName]);
      }
    }
  }

  /**
   * مسح الطبقة
   */
  clearLayer(layerName) {
    if (this.layers[layerName]) {
      this.layers[layerName].clearLayers();
    }
  }

  /**
   * مسح جميع الطبقات
   */
  clearAllLayers() {
    Object.values(this.layers).forEach(layer => {
      if (layer && layer.clearLayers) {
        layer.clearLayers();
      }
    });
  }

  /**
   * الاستجابة لنقرة المستخدم على الخريطة
   */
  onClick(callback) {
    this.map.on('click', (e) => {
      callback({
        lat: e.latlng.lat,
        lng: e.latlng.lng
      });
    });
  }

  /**
   * الاستجابة للنقر بالزر الأيمن
   */
  onContextMenu(callback) {
    this.map.on('contextmenu', (e) => {
      callback({
        lat: e.latlng.lat,
        lng: e.latlng.lng
      });
    });
  }

  /**
   * الحصول على عدد العناصر في الطبقة
   */
  getLayerCount(layerName) {
    if (this.layers[layerName]) {
      return this.layers[layerName].getLayers().length;
    }
    return 0;
  }
}

export default MapManager;
