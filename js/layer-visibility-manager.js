/**
 * مدير الطبقات والتصفية
 * Layer Visibility Manager
 */

import CONFIG from './config.js';
import NotificationManager from './notification-manager.js';

class LayerVisibilityManager {
  constructor() {
    this.layerVisibility = {
      subscribers: false,
      pumps: false,
      tanks: false,
      manholes: false,
      waterlines: false,
      sewerlines: false,
      gravitylines: false,
      neighborhoods: false,
      complaints: false,
      workers: false
    };

    this.loadVisibilityState();
  }

  /**
   * تحميل حالة الطبقات من التخزين المحلي
   */
  loadVisibilityState() {
    const saved = localStorage.getItem('layerVisibility');
    if (saved) {
      try {
        this.layerVisibility = JSON.parse(saved);
      } catch (error) {
        console.warn('فشل تحميل حالة الطبقات');
      }
    }
  }

  /**
   * حفظ حالة الطبقات
   */
  saveVisibilityState() {
    localStorage.setItem('layerVisibility', JSON.stringify(this.layerVisibility));
  }

  /**
   * تبديل ظهور الطبقة
   */
  toggleLayer(layerName, map) {
    if (!this.layerVisibility.hasOwnProperty(layerName)) {
      return;
    }

    const currentState = this.layerVisibility[layerName];
    this.layerVisibility[layerName] = !currentState;
    this.saveVisibilityState();

    return !currentState;
  }

  /**
   * تعيين حالة الطبقة
   */
  setLayerVisibility(layerName, visible) {
    if (this.layerVisibility.hasOwnProperty(layerName)) {
      this.layerVisibility[layerName] = visible;
      this.saveVisibilityState();
    }
  }

  /**
   * الحصول على حالة الطبقة
   */
  isLayerVisible(layerName) {
    return this.layerVisibility[layerName] || false;
  }

  /**
   * إظهار جميع الطبقات
   */
  showAll() {
    Object.keys(this.layerVisibility).forEach(layer => {
      this.layerVisibility[layer] = true;
    });
    this.saveVisibilityState();
  }

  /**
   * إخفاء جميع الطبقات
   */
  hideAll() {
    Object.keys(this.layerVisibility).forEach(layer => {
      this.layerVisibility[layer] = false;
    });
    this.saveVisibilityState();
  }

  /**
   * الحصول على إجمالي الطبقات المرئية
   */
  getVisibleLayerCount() {
    return Object.values(this.layerVisibility).filter(Boolean).length;
  }

  /**
   * إنشاء عنصر التحكم في الطبقات
   */
  createLayerControl() {
    const control = document.createElement('div');
    control.id = 'layer-control-panel';
    control.className = 'layer-control-panel';
    control.innerHTML = `
      <div class="layer-control-header">
        <h3>🔍 إظهار الطبقات</h3>
        <button id="toggleAllLayers" title="إظهار/إخفاء الكل">⚙️</button>
      </div>
      <div class="layer-control-list">
        ${this.createLayerCheckboxes()}
      </div>
    `;

    return control;
  }

  /**
   * إنشاء مربعات الاختيار للطبقات
   */
  createLayerCheckboxes() {
    const layers = [
      { key: 'subscribers', label: '👥 المشتركين', icon: '👥' },
      { key: 'pumps', label: '🏭 دور الضخ', icon: '🏭' },
      { key: 'tanks', label: '🚰 خزانات المياه', icon: '🚰' },
      { key: 'manholes', label: '🕳️ مناهل صرف', icon: '🕳️' },
      { key: 'waterlines', label: '🔵 خطوط مياه', icon: '🔵' },
      { key: 'sewerlines', label: '🟤 خطوط صرف', icon: '🟤' },
      { key: 'gravitylines', label: '🟣 مسارات جباه', icon: '🟣' },
      { key: 'neighborhoods', label: '🏘️ الأحياء', icon: '🏘️' },
      { key: 'complaints', label: '📋 بلاغات', icon: '📋' },
      { key: 'workers', label: '👤 الموظفون', icon: '👤' }
    ];

    return layers.map(layer => `
      <label class="layer-checkbox">
        <input type="checkbox" name="layer-${layer.key}" 
               data-layer="${layer.key}"
               ${this.isLayerVisible(layer.key) ? 'checked' : ''}>
        <span>${layer.icon} ${layer.label}</span>
      </label>
    `).join('');
  }
}

export default LayerVisibilityManager;
