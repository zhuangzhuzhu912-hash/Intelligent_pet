// 健康记录服务 — 体重、疫苗、就诊记录的 CRUD
import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { UserService } from './UserService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { WeightRecord, VaccineRecord, MedicalRecord } from '../models/DataModels';
import { VaccineStatus } from '../models/DataModels';

const TAG: string = 'HealthService';
const DOMAIN: number = 0x0000;

class HealthServiceClass {

  // ==========================================================================
  // 体重记录
  // ==========================================================================

  async addWeightRecord(petId: number, weight: number, date?: string): Promise<number> {
    const userId = UserService.getCurrentUserId();
    const now = new Date().toISOString();
    const recordDate = date || new Date().toISOString().split('T')[0];
    const values: relationalStore.ValuesBucket = {
      pet_id: petId,
      user_id: userId,
      weight: weight,
      record_date: recordDate,
      created_at: now,
    };
    return await RdbHelper.insert('weight_record', values);
  }

  async getWeightRecords(petId: number, limit: number = 30): Promise<WeightRecord[]> {
    const predicates = new relationalStore.RdbPredicates('weight_record');
    predicates.equalTo('pet_id', petId);
    predicates.orderByDesc('record_date');
    if (limit > 0) {
      predicates.limitAs(limit);
    }
    const rs = await RdbHelper.query('weight_record', predicates);
    const records: WeightRecord[] = [];
    try {
      while (rs.goToNextRow()) {
        records.push({
          id: rs.getLong(rs.getColumnIndex('id')),
          petId: petId,
          weight: rs.getDouble(rs.getColumnIndex('weight')),
          recordDate: rs.getString(rs.getColumnIndex('record_date')),
        });
      }
    } finally {
      rs.close();
    }
    return records;
  }

  // ==========================================================================
  // 疫苗记录
  // ==========================================================================

  async addVaccineRecord(petId: number, name: string, date?: string,
    status: VaccineStatus = VaccineStatus.PENDING): Promise<number> {
    const userId = UserService.getCurrentUserId();
    const now = new Date().toISOString();
    const recordDate = date || now.split('T')[0];
    const values: relationalStore.ValuesBucket = {
      pet_id: petId,
      user_id: userId,
      name: name,
      record_date: recordDate,
      status: status,
      created_at: now,
    };
    return await RdbHelper.insert('vaccine_record', values);
  }

  async getVaccineRecords(petId: number): Promise<VaccineRecord[]> {
    const predicates = new relationalStore.RdbPredicates('vaccine_record');
    predicates.equalTo('pet_id', petId);
    predicates.orderByAsc('created_at');
    const rs = await RdbHelper.query('vaccine_record', predicates);
    const records: VaccineRecord[] = [];
    try {
      while (rs.goToNextRow()) {
        records.push({
          id: rs.getLong(rs.getColumnIndex('id')),
          petId: petId,
          name: rs.getString(rs.getColumnIndex('name')),
          date: rs.getString(rs.getColumnIndex('record_date')),
          status: rs.getString(rs.getColumnIndex('status')) as VaccineStatus,
        });
      }
    } finally {
      rs.close();
    }
    return records;
  }

  async updateVaccineStatus(id: number, status: VaccineStatus): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('vaccine_record');
    predicates.equalTo('id', id);
    const values: relationalStore.ValuesBucket = {
      status: status,
    };
    await RdbHelper.update(values, predicates);
  }

  // ==========================================================================
  // 就诊记录
  // ==========================================================================

  async addMedicalRecord(petId: number, title: string, date: string,
    description: string, hospital: string): Promise<number> {
    const userId = UserService.getCurrentUserId();
    const now = new Date().toISOString();
    const values: relationalStore.ValuesBucket = {
      pet_id: petId,
      user_id: userId,
      title: title,
      record_date: date,
      description: description,
      hospital: hospital,
      created_at: now,
    };
    return await RdbHelper.insert('medical_record', values);
  }

  async getMedicalRecords(petId: number): Promise<MedicalRecord[]> {
    const predicates = new relationalStore.RdbPredicates('medical_record');
    predicates.equalTo('pet_id', petId);
    predicates.orderByDesc('record_date');
    const rs = await RdbHelper.query('medical_record', predicates);
    const records: MedicalRecord[] = [];
    try {
      while (rs.goToNextRow()) {
        records.push({
          id: rs.getLong(rs.getColumnIndex('id')),
          petId: petId,
          title: rs.getString(rs.getColumnIndex('title')),
          date: rs.getString(rs.getColumnIndex('record_date')),
          description: rs.getString(rs.getColumnIndex('description')),
          hospital: rs.getString(rs.getColumnIndex('hospital')),
        });
      }
    } finally {
      rs.close();
    }
    return records;
  }
}

export const HealthService = new HealthServiceClass();
