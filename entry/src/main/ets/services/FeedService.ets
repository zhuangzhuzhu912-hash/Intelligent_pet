// 喂食记录服务层
// 负责喂食日志的 CRUD，按 pet_id + user_id 隔离

import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { UserService } from './UserService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'FeedService';
const DOMAIN: number = 0x0000;

// 喂食记录实体
export interface FeedEntity {
  id: number;
  petId: number;
  userId: number;
  feedTime: string;
  feedType: string;  // scheduled | exercise_reward | manual
  amount: number;
  unit: string;
  label: string;
  isHighlight: boolean;
  createdAt: string;
}

class FeedServiceClass {
  // 添加喂食记录
  async addRecord(petId: number, record: Partial<FeedEntity>): Promise<number> {
    const userId = UserService.getCurrentUserId();
    if (userId <= 0) {
      throw new Error('请先登录');
    }
    const now = new Date().toISOString();
    const values: relationalStore.ValuesBucket = {
      pet_id: petId,
      user_id: userId,
      feed_time: record.feedTime || now,
      feed_type: record.feedType || 'manual',
      amount: record.amount || 0,
      unit: record.unit || 'g',
      label: record.label || '',
      is_highlight: record.isHighlight ? 1 : 0,
      created_at: now
    };
    return await RdbHelper.insert('feed_log', values);
  }

  // 获取某宠物今日喂食记录
  async getTodayRecords(petId: number): Promise<FeedEntity[]> {
    const today = new Date().toISOString().split('T')[0];
    const userId = UserService.getCurrentUserId();
    const predicates = new relationalStore.RdbPredicates('feed_log');
    predicates.equalTo('pet_id', petId);
    predicates.equalTo('user_id', userId);
    predicates.like('feed_time', `${today}%`);
    predicates.orderByAsc('feed_time');
    const resultSet = await RdbHelper.query('feed_log', predicates);
    const records: FeedEntity[] = [];
    try {
      while (resultSet.goToNextRow()) {
        records.push(this.mapResult(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  // 获取某宠物最近 N 条喂食记录
  async getRecentRecords(petId: number, limit: number = 20): Promise<FeedEntity[]> {
    const userId = UserService.getCurrentUserId();
    const predicates = new relationalStore.RdbPredicates('feed_log');
    predicates.equalTo('pet_id', petId);
    predicates.equalTo('user_id', userId);
    predicates.orderByDesc('feed_time');
    predicates.limitAs(limit);
    const resultSet = await RdbHelper.query('feed_log', predicates);
    const records: FeedEntity[] = [];
    try {
      while (resultSet.goToNextRow()) {
        records.push(this.mapResult(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  // 获取今日总投喂量
  async getTodayTotalAmount(petId: number): Promise<number> {
    const records = await this.getTodayRecords(petId);
    let total = 0;
    for (const r of records) {
      total += r.amount;
    }
    return total;
  }

  // 删除某宠物所有喂食记录
  async deleteByPetId(petId: number): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('feed_log');
    predicates.equalTo('pet_id', petId);
    return await RdbHelper.deleteData(predicates);
  }

  private mapResult(rs: relationalStore.ResultSet): FeedEntity {
    return {
      id: rs.getLong(rs.getColumnIndex('id')),
      petId: rs.getLong(rs.getColumnIndex('pet_id')),
      userId: rs.getLong(rs.getColumnIndex('user_id')),
      feedTime: rs.getString(rs.getColumnIndex('feed_time')),
      feedType: rs.getString(rs.getColumnIndex('feed_type')),
      amount: rs.getDouble(rs.getColumnIndex('amount')),
      unit: rs.getString(rs.getColumnIndex('unit')),
      label: rs.getString(rs.getColumnIndex('label')),
      isHighlight: rs.getLong(rs.getColumnIndex('is_highlight')) === 1,
      createdAt: rs.getString(rs.getColumnIndex('created_at'))
    };
  }
}

export const FeedService = new FeedServiceClass();
