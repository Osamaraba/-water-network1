/**
 * قاعدة البيانات المحلية - IndexedDB
 * Local Database Management
 */

class DatabaseManager {
  constructor() {
    this.db = null;
    this.dbName = 'WaterNetworkDB';
    this.version = 1;
  }

  /**
   * تهيئة قاعدة البيانات
   */
  async initialize() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;

        const stores = [
          'subscribers', 'pumps', 'tanks', 'manholes',
          'waterlines', 'sewerlines', 'gravitylines',
          'neighborhoods', 'complaints', 'workers', 'snapshots'
        ];

        stores.forEach(store => {
          if (!db.objectStoreNames.contains(store)) {
            db.createObjectStore(store, { keyPath: 'id' });
          }
        });
      };
    });
  }

  /**
   * حفظ البيانات
   */
  async save(storeName, data) {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.put(data);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  /**
   * استرجاع البيانات
   */
  async get(storeName, id) {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.get(id);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  /**
   * الحصول على جميع البيانات من مستودع
   */
  async getAll(storeName) {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.getAll();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  /**
   * حذف البيانات
   */
  async delete(storeName, id) {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.delete(id);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  /**
   * مسح جميع البيانات من مستودع
   */
  async clear(storeName) {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.clear();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  /**
   * العد الإجمالي للعناصر
   */
  async count(storeName) {
    if (!this.db) await this.initialize();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.count();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  /**
   * البحث بحسب الخاصية
   */
  async findByProperty(storeName, property, value) {
    const all = await this.getAll(storeName);
    return all.filter(item => item[property] === value);
  }
}

export default new DatabaseManager();
