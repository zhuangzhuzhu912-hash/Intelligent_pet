// 宠物服务层
// 负责宠物档案 CRUD、多宠物绑定、按 user_id 数据隔离

import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { UserService } from './UserService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PetService';
const DOMAIN: number = 0x0000;

// 宠物数据库实体
export interface PetEntity {
  id: number;
  userId: number;
  name: string;
  breed: string;
  age: number;
  gender: string;
  weight: number;
  avatar: string;
  temperature: number;
  heartRate: number;
  vaccineStatus: string;
  isNeutered: boolean;
  createdAt: string;
  updatedAt: string;
}

class PetServiceClass {
  // 添加宠物（绑定到当前用户）
  async addPet(pet: Partial<PetEntity>): Promise<number> {
    const userId = UserService.getCurrentUserId();
    if (userId <= 0) {
      throw new Error('请先登录');
    }
    const now = new Date().toISOString();
    const values: relationalStore.ValuesBucket = {
      user_id: userId,
      name: pet.name || '未命名',
      breed: pet.breed || '',
      age: pet.age || 0,
      gender: pet.gender || '未知',
      weight: pet.weight || 0,
      avatar: pet.avatar || '',
      temperature: pet.temperature || 0,
      heart_rate: pet.heartRate || 0,
      vaccine_status: pet.vaccineStatus || 'pending',
      is_neutered: pet.isNeutered ? 1 : 0,
      created_at: now,
      updated_at: now
    };
    const rowId = await RdbHelper.insert('pet_info', values);
    hilog.info(DOMAIN, TAG, `Pet added: ${pet.name}, id=${rowId}`);
    return rowId;
  }

  // 获取当前用户的所有宠物（数据隔离）
  async getPetsByCurrentUser(): Promise<PetEntity[]> {
    const userId = UserService.getCurrentUserId();
    if (userId <= 0) {
      return [];
    }
    return this.getPetsByUserId(userId);
  }

  // 根据 userId 获取宠物列表
  async getPetsByUserId(userId: number): Promise<PetEntity[]> {
    const predicates = new relationalStore.RdbPredicates('pet_info');
    predicates.equalTo('user_id', userId);
    predicates.orderByAsc('created_at');
    const resultSet = await RdbHelper.query('pet_info', predicates);
    const pets: PetEntity[] = [];
    try {
      while (resultSet.goToNextRow()) {
        pets.push(this.mapResultToPet(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return pets;
  }

  // 根据 ID 获取单个宠物
  async getPetById(petId: number): Promise<PetEntity | null> {
    const predicates = new relationalStore.RdbPredicates('pet_info');
    predicates.equalTo('id', petId);
    const resultSet = await RdbHelper.query('pet_info', predicates);
    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultToPet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  // 更新宠物信息
  async updatePet(petId: number, pet: Partial<PetEntity>): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates('pet_info');
    predicates.equalTo('id', petId);
    const values: relationalStore.ValuesBucket = {
      updated_at: new Date().toISOString()
    };
    if (pet.name !== undefined) {
      values['name'] = pet.name;
    }
    if (pet.breed !== undefined) {
      values['breed'] = pet.breed;
    }
    if (pet.age !== undefined) {
      values['age'] = pet.age;
    }
    if (pet.gender !== undefined) {
      values['gender'] = pet.gender;
    }
    if (pet.weight !== undefined) {
      values['weight'] = pet.weight;
    }
    if (pet.avatar !== undefined) {
      values['avatar'] = pet.avatar;
    }
    if (pet.temperature !== undefined) {
      values['temperature'] = pet.temperature;
    }
    if (pet.heartRate !== undefined) {
      values['heart_rate'] = pet.heartRate;
    }
    if (pet.vaccineStatus !== undefined) {
      values['vaccine_status'] = pet.vaccineStatus;
    }
    if (pet.isNeutered !== undefined) {
      values['is_neutered'] = pet.isNeutered ? 1 : 0;
    }
    const rows = await RdbHelper.update(values, predicates);
    return rows > 0;
  }

  // 删除宠物
  async deletePet(petId: number): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates('pet_info');
    predicates.equalTo('id', petId);
    const rows = await RdbHelper.deleteData(predicates);
    if (rows > 0) {
      // 同时清理该宠物的运动和喂食记录
      const motionPred = new relationalStore.RdbPredicates('motion_record');
      motionPred.equalTo('pet_id', petId);
      await RdbHelper.deleteData(motionPred);
      const feedPred = new relationalStore.RdbPredicates('feed_log');
      feedPred.equalTo('pet_id', petId);
      await RdbHelper.deleteData(feedPred);
      hilog.info(DOMAIN, TAG, `Pet deleted: id=${petId}`);
    }
    return rows > 0;
  }

  // 获取当前用户宠物数量
  async getPetCount(): Promise<number> {
    const pets = await this.getPetsByCurrentUser();
    return pets.length;
  }

  // 设置当前选中的宠物
  setCurrentPet(petId: number): void {
    AppStorage.setOrCreate<number>('currentPetId', petId);
  }

  // 获取当前选中的宠物 ID
  getCurrentPetId(): number {
    return AppStorage.get<number>('currentPetId') ?? -1;
  }

  // ResultSet 映射
  private mapResultToPet(rs: relationalStore.ResultSet): PetEntity {
    return {
      id: rs.getLong(rs.getColumnIndex('id')),
      userId: rs.getLong(rs.getColumnIndex('user_id')),
      name: rs.getString(rs.getColumnIndex('name')),
      breed: rs.getString(rs.getColumnIndex('breed')),
      age: rs.getDouble(rs.getColumnIndex('age')),
      gender: rs.getString(rs.getColumnIndex('gender')),
      weight: rs.getDouble(rs.getColumnIndex('weight')),
      avatar: rs.getString(rs.getColumnIndex('avatar')),
      temperature: rs.getDouble(rs.getColumnIndex('temperature')),
      heartRate: rs.getLong(rs.getColumnIndex('heart_rate')),
      vaccineStatus: rs.getString(rs.getColumnIndex('vaccine_status')),
      isNeutered: rs.getLong(rs.getColumnIndex('is_neutered')) === 1,
      createdAt: rs.getString(rs.getColumnIndex('created_at')),
      updatedAt: rs.getString(rs.getColumnIndex('updated_at'))
    };
  }
}

export const PetService = new PetServiceClass();
