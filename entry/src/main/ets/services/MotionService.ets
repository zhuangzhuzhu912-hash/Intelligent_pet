// 运动记录服务层
// 负责每日运动数据的 CRUD，按 pet_id + user_id 隔离

import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { UserService } from './UserService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'MotionService';
const DOMAIN: number = 0x0000;

// 运动记录实体
export interface MotionEntity {
  id: number;
  petId: number;
  userId: number;
  recordDate: string;
  steps: number;
  distance: number;
  calories: number;
  goalSteps: number;
  durationMinutes: number;
  createdAt: string;
}

class MotionServiceClass {
  // 添加运动记录
  async addRecord(petId: number, record: Partial<MotionEntity>): Promise<number> {
    const userId = UserService.getCurrentUserId();
    if (userId <= 0) {
      throw new Error('请先登录');
    }
    const now = new Date().toISOString();
    const today = now.split('T')[0];
    const values: relationalStore.ValuesBucket = {
      pet_id: petId,
      user_id: userId,
      record_date: record.recordDate || today,
      steps: record.steps || 0,
      distance: record.distance || 0,
      calories: record.calories || 0,
      goal_steps: record.goalSteps || 8000,
      duration_minutes: record.durationMinutes || 0,
      created_at: now
    };
    return await RdbHelper.insert('motion_record', values);
  }

  // 获取某宠物今日运动记录
  async getTodayRecord(petId: number): Promise<MotionEntity | null> {
    const today = new Date().toISOString().split('T')[0];
    const predicates = new relationalStore.RdbPredicates('motion_record');
    predicates.equalTo('pet_id', petId);
    predicates.equalTo('user_id', UserService.getCurrentUserId());
    predicates.equalTo('record_date', today);
    const resultSet = await RdbHelper.query('motion_record', predicates);
    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResult(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  // 获取某宠物最近 N 天运动记录
  async getRecentRecords(petId: number, days: number = 7): Promise<MotionEntity[]> {
    const userId = UserService.getCurrentUserId();
    const predicates = new relationalStore.RdbPredicates('motion_record');
    predicates.equalTo('pet_id', petId);
    predicates.equalTo('user_id', userId);
    predicates.orderByDesc('record_date');
    predicates.limitAs(days);
    const resultSet = await RdbHelper.query('motion_record', predicates);
    const records: MotionEntity[] = [];
    try {
      while (resultSet.goToNextRow()) {
        records.push(this.mapResult(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  // 更新今日运动数据（累加步数等）
  async updateTodayRecord(petId: number, steps: number, distance: number,
    calories: number): Promise<void> {
    const existing = await this.getTodayRecord(petId);
    if (existing) {
      const predicates = new relationalStore.RdbPredicates('motion_record');
      predicates.equalTo('id', existing.id);
      const values: relationalStore.ValuesBucket = {
        steps: steps,
        distance: distance,
        calories: calories
      };
      await RdbHelper.update(values, predicates);
    } else {
      await this.addRecord(petId, { steps, distance, calories });
    }
  }

  // 删除某宠物所有运动记录
  async deleteByPetId(petId: number): Promise<number> {
    const predicates = new relationalStore.RdbPredicates('motion_record');
    predicates.equalTo('pet_id', petId);
    return await RdbHelper.deleteData(predicates);
  }

  private mapResult(rs: relationalStore.ResultSet): MotionEntity {
    return {
      id: rs.getLong(rs.getColumnIndex('id')),
      petId: rs.getLong(rs.getColumnIndex('pet_id')),
      userId: rs.getLong(rs.getColumnIndex('user_id')),
      recordDate: rs.getString(rs.getColumnIndex('record_date')),
      steps: rs.getLong(rs.getColumnIndex('steps')),
      distance: rs.getDouble(rs.getColumnIndex('distance')),
      calories: rs.getDouble(rs.getColumnIndex('calories')),
      goalSteps: rs.getLong(rs.getColumnIndex('goal_steps')),
      durationMinutes: rs.getLong(rs.getColumnIndex('duration_minutes')),
      createdAt: rs.getString(rs.getColumnIndex('created_at'))
    };
  }
}

export const MotionService = new MotionServiceClass();
