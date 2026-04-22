// 分布式关系型数据库管理器
// 封装 relationalStore，负责建表、分布式表设置、数据库生命周期管理

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';

const TAG: string = 'RdbHelper';
const DOMAIN: number = 0x0000;
const DB_NAME: string = 'pet_hub.db';
const DB_SECURITY_LEVEL: relationalStore.SecurityLevel = relationalStore.SecurityLevel.S1;

// ---- 建表 SQL ----

const SQL_CREATE_USER = `
CREATE TABLE IF NOT EXISTS user_info (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  nickname TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  avatar TEXT DEFAULT '',
  is_vip INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)`;

const SQL_CREATE_PET = `
CREATE TABLE IF NOT EXISTS pet_info (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  breed TEXT DEFAULT '',
  age REAL DEFAULT 0,
  gender TEXT DEFAULT '未知',
  weight REAL DEFAULT 0,
  avatar TEXT DEFAULT '',
  temperature REAL DEFAULT 0,
  heart_rate INTEGER DEFAULT 0,
  vaccine_status TEXT DEFAULT 'pending',
  is_neutered INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)`;

const SQL_CREATE_MOTION = `
CREATE TABLE IF NOT EXISTS motion_record (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  record_date TEXT NOT NULL,
  steps INTEGER DEFAULT 0,
  distance REAL DEFAULT 0,
  calories REAL DEFAULT 0,
  goal_steps INTEGER DEFAULT 8000,
  duration_minutes INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
)`;

const SQL_CREATE_FEED = `
CREATE TABLE IF NOT EXISTS feed_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  feed_time TEXT NOT NULL,
  feed_type TEXT NOT NULL,
  amount REAL DEFAULT 0,
  unit TEXT DEFAULT 'g',
  label TEXT DEFAULT '',
  is_highlight INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
)`;

// 分布式表列表
const DISTRIBUTED_TABLES: string[] = ['pet_info', 'motion_record', 'feed_log'];

class RdbHelperClass {
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  // 初始化 Promise，用于让其他操作等待数据库就绪
  private initPromise: Promise<void> | null = null;
  // 保存 context 引用，用于在 getStoreAsync 中自动重试初始化
  private appContext: Context | null = null;

  // 初始化数据库
  async initDb(context: Context): Promise<void> {
    // 保存 context 以便后续重试
    this.appContext = context;
    if (this.isInitialized && this.rdbStore) {
      return;
    }
    // 如果已经在初始化中，返回同一个 Promise 避免重复初始化
    if (this.initPromise) {
      return this.initPromise;
    }
    this.initPromise = this.doInit(context);
    return this.initPromise;
  }

  private async doInit(context: Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: DB_SECURITY_LEVEL
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      hilog.info(DOMAIN, TAG, 'RdbStore obtained successfully');

      // 建表
      await this.rdbStore.executeSql(SQL_CREATE_USER);
      await this.rdbStore.executeSql(SQL_CREATE_PET);
      await this.rdbStore.executeSql(SQL_CREATE_MOTION);
      await this.rdbStore.executeSql(SQL_CREATE_FEED);
      hilog.info(DOMAIN, TAG, 'All tables created');

      // 设置分布式表
      for (const table of DISTRIBUTED_TABLES) {
        try {
          await this.rdbStore.setDistributedTables([table]);
          hilog.info(DOMAIN, TAG, `Distributed table set: ${table}`);
        } catch (e) {
          hilog.warn(DOMAIN, TAG, `Failed to set distributed table ${table}: ${JSON.stringify(e)}`);
        }
      }

      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'Database initialization complete');
    } catch (err) {
      // 初始化失败时清除 Promise，允许重试
      this.initPromise = null;
      const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to init DB: ${errorMessage}`);
      throw new Error(`数据库初始化失败: ${errorMessage}`);
    }
  }

  // 等待数据库就绪后获取 RdbStore 实例
  // 所有数据库操作都应通过此方法获取 store，确保 DB 已初始化
  async getStoreAsync(): Promise<relationalStore.RdbStore> {
    // 如果已初始化，直接返回
    if (this.isInitialized && this.rdbStore) {
      return this.rdbStore;
    }
    // 如果正在初始化，等待完成
    if (this.initPromise) {
      await this.initPromise;
      if (this.rdbStore) {
        return this.rdbStore;
      }
    }
    // 如果有保存的 context，尝试自动重新初始化
    if (this.appContext) {
      hilog.warn(DOMAIN, TAG, 'Database not initialized, attempting auto re-init...');
      await this.initDb(this.appContext);
      if (this.isInitialized && this.rdbStore) {
        return this.rdbStore;
      }
    }
    throw new Error('数据库未初始化，请确保应用启动时已调用 initDb()');
  }

  // 同步获取（仅在确定已初始化时使用）
  getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    return this.rdbStore;
  }

  // 插入数据
  async insert(table: string, values: relationalStore.ValuesBucket): Promise<number> {
    const store = await this.getStoreAsync();
    const rowId = await store.insert(table, values);
    hilog.info(DOMAIN, TAG, `Insert into ${table}, rowId=${rowId}`);
    return rowId;
  }

  // 查询数据
  async query(table: string, predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet> {
    const store = await this.getStoreAsync();
    return await store.query(predicates, columns);
  }

  // 更新数据
  async update(values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates): Promise<number> {
    const store = await this.getStoreAsync();
    return await store.update(values, predicates);
  }

  // 删除数据
  async deleteData(predicates: relationalStore.RdbPredicates): Promise<number> {
    const store = await this.getStoreAsync();
    return await store.delete(predicates);
  }

  // 跨设备同步
  async syncDistributed(table: string, mode: relationalStore.SyncMode): Promise<void> {
    const store = await this.getStoreAsync();
    const predicates = new relationalStore.RdbPredicates(table);
    try {
      await store.sync(mode, predicates);
      hilog.info(DOMAIN, TAG, `Sync completed for table: ${table}`);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `Sync failed for table ${table}: ${JSON.stringify(e)}`);
    }
  }

  // 关闭数据库
  async close(): Promise<void> {
    if (this.rdbStore) {
      this.rdbStore = null;
      this.isInitialized = false;
      this.initPromise = null;
      hilog.info(DOMAIN, TAG, 'Database closed');
    }
  }
}

// 单例导出
export const RdbHelper = new RdbHelperClass();
