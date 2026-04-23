// 运动记录服务层
// 负责每日运动数据的 CRUD，按 pet_id + user_id 隔离
// 扩展：集成传感器数据，支持实时运动监测

import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { UserService } from './UserService';
import { SensorService } from './SensorService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AccelerometerData, SensorData } from '../models/DataModels';
import { MotionRecord, SensorServiceStatus } from '../models/SensorModels';

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

  // ===== 扩展：传感器集成方法 =====

  // 开始实时运动监测
  async startRealTimeMonitoring(petId: number, deviceId: string = '', useSimulation: boolean = false): Promise<void> {
    try {
      await SensorService.startMonitoring(petId, deviceId, useSimulation);
      hilog.info(DOMAIN, TAG, `Real-time monitoring started for pet ${petId}, simulation: ${useSimulation}`);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to start real-time monitoring: ${errorMessage}`);
      throw new Error(`启动实时监测失败: ${errorMessage}`);
    }
  }

  // 停止实时运动监测
  async stopRealTimeMonitoring(): Promise<void> {
    try {
      await SensorService.stopMonitoring();
      hilog.info(DOMAIN, TAG, 'Real-time monitoring stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to stop real-time monitoring: ${JSON.stringify(err)}`);
      throw new Error('停止实时监测失败');
    }
  }

  // 获取实时运动数据
  getRealTimeData(): SensorData {
    try {
      return SensorService.getCurrentData();
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to get real-time data: ${JSON.stringify(err)}`);
      return {
        timestamp: new Date().toISOString(),
        accelerometer: ({ x: 0, y: 0, z: 0 }) as AccelerometerData,
        steps: 0,
        distance: 0,
        calories: 0,
      };
    }
  }

  // 获取实时步数统计
  getRealTimeStats(): MotionRecord | null{
    try {
      return SensorService.getStepStats();
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to get real-time stats: ${JSON.stringify(err)}`);
      return null;
    }
  }

  // 同步传感器数据到数据库
  async syncSensorData(): Promise<void> {
    try {
      const stats = SensorService.getStepStats();
      const petId = await this.getCurrentPetId();

      if (petId > 0 && (stats.steps > 0 || stats.distance > 0 || stats.calories > 0)) {
        await this.updateTodayRecord(petId, stats.steps, stats.distance, stats.calories);
        hilog.info(DOMAIN, TAG, `Sensor data synced: steps=${stats.steps}, distance=${stats.distance}m, calories=${stats.calories}kcal`);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to sync sensor data: ${JSON.stringify(err)}`);
    }
  }

  // 计算运动达成率
  calculateGoalAchievement(steps: number, goalSteps: number = 8000): number {
    if (goalSteps <= 0) {
      return 0;
    }
    const percentage = (steps / goalSteps) * 100;
    return Math.min(100, Math.round(percentage));
  }

  // 根据运动量计算建议喂食量
  calculateSuggestedFeedingAmount(steps: number, baseAmount: number = 30): number {
    // 基础公式：每1000步增加1克食物，最多增加50%
    const stepsPerGram = 1000;
    const maxIncrease = 0.5; // 50%

    const additionalAmount = Math.floor(steps / stepsPerGram);
    const maxAdditional = baseAmount * maxIncrease;

    return baseAmount + Math.min(additionalAmount, maxAdditional);
  }

  // 检查是否达到奖励零食条件
  checkRewardCondition(steps: number, rewardThreshold: number = 5000): boolean {
    return steps >= rewardThreshold;
  }

  // 获取当前宠物ID（简化实现）
  private async getCurrentPetId(): Promise<number> {
    // 这里应该从宠物服务获取当前宠物ID
    // 简化实现，返回1
    return 1;
  }

  // 获取监测状态
  getMonitoringStatus(): SensorServiceStatus |null {
    try {
      return SensorService.getStatus();
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to get monitoring status: ${JSON.stringify(err)}`);
      return null;
    }
  }
}

export const MotionService = new MotionServiceClass();
