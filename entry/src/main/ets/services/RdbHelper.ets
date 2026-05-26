// 分布式关系型数据库管理器
// 封装 relationalStore，负责建表、分布式表设置、数据库生命周期管理

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';
import type { LocationPoint, HardwareTelemetry, FeedingScheduleItem } from '../models/DataModels';

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

// 位置轨迹表
const SQL_CREATE_LOCATION_TRACK = `
CREATE TABLE IF NOT EXISTS location_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  device_id TEXT DEFAULT '',
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL DEFAULT 0,
  altitude REAL DEFAULT 0,
  speed REAL DEFAULT 0,
  timestamp TEXT NOT NULL,
  created_at TEXT NOT NULL
)`;

// 硬件遥测数据表
const SQL_CREATE_HARDWARE_TELEMETRY = `
CREATE TABLE IF NOT EXISTS hardware_telemetry (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT NOT NULL,
  device_type TEXT NOT NULL,
  metric_type TEXT NOT NULL,
  value REAL NOT NULL,
  unit TEXT DEFAULT '',
  timestamp TEXT NOT NULL,
  created_at TEXT NOT NULL
)`;

// 喂食计划表
const SQL_CREATE_FEEDING_SCHEDULE = `
CREATE TABLE IF NOT EXISTS feeding_schedule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  time TEXT NOT NULL,
  label TEXT NOT NULL,
  amount REAL NOT NULL,
  unit TEXT DEFAULT 'g',
  is_active INTEGER DEFAULT 1,
  is_adaptive INTEGER DEFAULT 0,
  min_amount REAL DEFAULT 0,
  max_amount REAL DEFAULT 0,
  days_of_week TEXT DEFAULT '[0,1,2,3,4,5,6]',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)`;

// 地理围栏表
const SQL_CREATE_GEO_FENCE = `
CREATE TABLE IF NOT EXISTS geo_fence (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  radius REAL NOT NULL,
  is_active INTEGER DEFAULT 1,
  notification_enabled INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)`;

// 自适应投喂规则表
const SQL_CREATE_ADAPTIVE_RULE = `
CREATE TABLE IF NOT EXISTS adaptive_feeding_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  steps_threshold INTEGER NOT NULL,
  amount_adjustment REAL NOT NULL,
  is_reward INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)`;

// 设备信息表
const SQL_CREATE_DEVICE_INFO = `
CREATE TABLE IF NOT EXISTS device_info (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  model TEXT NOT NULL,
  type TEXT NOT NULL,
  icon_symbol TEXT DEFAULT '📱',
  icon_color TEXT DEFAULT '#FF9F43',
  gradient_start TEXT DEFAULT '#FF9F43',
  gradient_end TEXT DEFAULT '#F97316',
  features TEXT DEFAULT '[]',
  extra_info TEXT DEFAULT '',
  is_builtin INTEGER DEFAULT 0,
  is_online INTEGER DEFAULT 1,
  battery INTEGER DEFAULT 100,
  created_at TEXT NOT NULL
)`;

// 分布式表列表
const DISTRIBUTED_TABLES: string[] = [
  'pet_info',
  'motion_record',
  'feed_log',
  'location_track',
  'hardware_telemetry',
  'feeding_schedule',
  'geo_fence',
  'device_info'
];

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
      await this.rdbStore.executeSql(SQL_CREATE_LOCATION_TRACK);
      await this.rdbStore.executeSql(SQL_CREATE_HARDWARE_TELEMETRY);
      await this.rdbStore.executeSql(SQL_CREATE_FEEDING_SCHEDULE);
      await this.rdbStore.executeSql(SQL_CREATE_GEO_FENCE);
      await this.rdbStore.executeSql(SQL_CREATE_ADAPTIVE_RULE);
      await this.rdbStore.executeSql(SQL_CREATE_DEVICE_INFO);
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

  // 批量插入位置点
  // async batchInsertLocationPoints(points: LocationPoint[]): Promise<number[]> {
  //   const store = await this.getStoreAsync();
  //   const rowIds: number[] = [];
  //
  //   try {
  //     await store.beginTransaction();
  //
  //     for (const point of points) {
  //       const rowId = await store.insert('location_track', point);
  //       rowIds.push(rowId);
  //     }
  //
  //     await store.commit();
  //     hilog.info(DOMAIN, TAG, `Batch inserted ${rowIds.length} location points`);
  //     return rowIds;
  //   } catch (err) {
  //     await store.rollback();
  //     hilog.error(DOMAIN, TAG, `Batch insert failed: ${JSON.stringify(err)}`);
  //     throw err;
  //   }
  // }

  // 获取宠物当日轨迹
  async getPetTrajectory(petId: number, date: string): Promise<LocationPoint[]> {
    const store = await this.getStoreAsync();
    const predicates = new relationalStore.RdbPredicates('location_track');
    predicates.equalTo('pet_id', petId);
    predicates.greaterThanOrEqualTo('timestamp', `${date}T00:00:00`);
    predicates.lessThanOrEqualTo('timestamp', `${date}T23:59:59`);
    predicates.orderByAsc('timestamp');

    const resultSet = await store.query(predicates);
    const points: LocationPoint[] = [];

    while (resultSet.goToNextRow()) {
      points.push({
        latitude: resultSet.getDouble(resultSet.getColumnIndex('latitude')),
        longitude: resultSet.getDouble(resultSet.getColumnIndex('longitude')),
        timestamp: resultSet.getString(resultSet.getColumnIndex('timestamp')),
        accuracy: resultSet.getDouble(resultSet.getColumnIndex('accuracy'))
      });
    }

    resultSet.close();
    return points;
  }

  // 获取设备最新遥测数据
  async getLatestTelemetry(deviceId: string, metricType?: string): Promise<HardwareTelemetry[]> {
    const store = await this.getStoreAsync();
    const predicates = new relationalStore.RdbPredicates('hardware_telemetry');
    predicates.equalTo('device_id', deviceId);

    if (metricType) {
      predicates.equalTo('metric_type', metricType);
    }

    predicates.orderByDesc('timestamp');
    predicates.limitAs(10); // 获取最近10条

    const resultSet = await store.query(predicates);
    const telemetry: HardwareTelemetry[] = [];

    while (resultSet.goToNextRow()) {
      telemetry.push({
        deviceId: deviceId,
        deviceType: resultSet.getString(resultSet.getColumnIndex('device_type')) || 'unknown',
        metricType: resultSet.getString(resultSet.getColumnIndex('metric_type')),
        value: resultSet.getDouble(resultSet.getColumnIndex('value')),
        unit: resultSet.getString(resultSet.getColumnIndex('unit')),
        timestamp: resultSet.getString(resultSet.getColumnIndex('timestamp'))
      });
    }

    resultSet.close();
    return telemetry;
  }

  // 获取激活的喂食计划
  async getActiveFeedingSchedules(petId: number): Promise<FeedingScheduleItem[]> {
    const store = await this.getStoreAsync();
    const predicates = new relationalStore.RdbPredicates('feeding_schedule');
    predicates.equalTo('pet_id', petId);
    predicates.equalTo('is_active', 1);
    predicates.orderByAsc('time');

    const resultSet = await store.query(predicates);
    const schedules: FeedingScheduleItem[] = [];

    while (resultSet.goToNextRow()) {
      schedules.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        petId: petId,
        time: resultSet.getString(resultSet.getColumnIndex('time')),
        label: resultSet.getString(resultSet.getColumnIndex('label')),
        amount: resultSet.getDouble(resultSet.getColumnIndex('amount')),
        unit: resultSet.getString(resultSet.getColumnIndex('unit')),
        isActive: true,
        isAdaptive: resultSet.getLong(resultSet.getColumnIndex('is_adaptive')) === 1,
        minAmount: resultSet.getDouble(resultSet.getColumnIndex('min_amount')) || 20,
        maxAmount: resultSet.getDouble(resultSet.getColumnIndex('max_amount')) || 50,
        daysOfWeek: JSON.parse(resultSet.getString(resultSet.getColumnIndex('days_of_week')) || '[0,1,2,3,4,5,6]')
      });
    }

    resultSet.close();
    return schedules;
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
