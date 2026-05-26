// 设备服务层
// 负责设备 CRUD、内置设备初始化、按 user_id 数据隔离

import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import { UserService } from './UserService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DeviceService';
const DOMAIN: number = 0x0000;

// 设备数据库实体
export interface DeviceEntity {
  id: number;
  userId: number;
  name: string;
  model: string;
  type: string;
  iconSymbol: string;
  iconColor: string;
  gradientStart: string;
  gradientEnd: string;
  features: string;
  extraInfo: string;
  isBuiltin: boolean;
  isOnline: boolean;
  battery: number;
  createdAt: string;
}

class DeviceServiceClass {
  // 添加设备
  async addDevice(device: Partial<DeviceEntity>): Promise<number> {
    const userId = UserService.getCurrentUserId();
    if (userId <= 0) {
      throw new Error('请先登录');
    }
    const now = new Date().toISOString();
    const values: relationalStore.ValuesBucket = {
      user_id: userId,
      name: device.name || '新设备',
      model: device.model || '',
      type: device.type || 'other',
      icon_symbol: device.iconSymbol || '📱',
      icon_color: device.iconColor || '#FF9F43',
      gradient_start: device.gradientStart || '#FF9F43',
      gradient_end: device.gradientEnd || '#F97316',
      features: device.features || '[]',
      extra_info: device.extraInfo || '',
      is_builtin: device.isBuiltin ? 1 : 0,
      is_online: device.isOnline !== undefined ? (device.isOnline ? 1 : 0) : 1,
      battery: device.battery || 100,
      created_at: now
    };
    const rowId = await RdbHelper.insert('device_info', values);
    hilog.info(DOMAIN, TAG, `Device added: ${device.name}, id=${rowId}`);
    return rowId;
  }

  // 获取当前用户的所有设备
  async getDevicesByCurrentUser(): Promise<DeviceEntity[]> {
    const userId = UserService.getCurrentUserId();
    if (userId <= 0) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates('device_info');
    predicates.equalTo('user_id', userId);
    predicates.orderByAsc('is_builtin');
    predicates.orderByAsc('created_at');
    const resultSet = await RdbHelper.query('device_info', predicates);
    const devices: DeviceEntity[] = [];
    try {
      while (resultSet.goToNextRow()) {
        devices.push(this.mapResultToDevice(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return devices;
  }

  // 删除设备
  async deleteDevice(deviceId: number): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates('device_info');
    predicates.equalTo('id', deviceId);
    const rows = await RdbHelper.deleteData(predicates);
    if (rows > 0) {
      hilog.info(DOMAIN, TAG, `Device deleted: id=${deviceId}`);
    }
    return rows > 0;
  }

  // 获取设备总数
  async getDeviceCount(): Promise<number> {
    const devices = await this.getDevicesByCurrentUser();
    return devices.length;
  }

  // 初始化内置设备（首次登录时调用，检查是否已有内置设备）
  async initBuiltInDevices(): Promise<void> {
    const devices = await this.getDevicesByCurrentUser();
    const hasCollar = devices.some((d: DeviceEntity) => d.type === 'collar' && d.isBuiltin);
    const hasFeeder = devices.some((d: DeviceEntity) => d.type === 'feeder' && d.isBuiltin);
    const hasWater = devices.some((d: DeviceEntity) => d.type === 'water' && d.isBuiltin);

    if (!hasCollar) {
      await this.addDevice({
        name: '智能项圈', model: 'PetCollar Pro', type: 'collar',
        iconSymbol: '🐕', iconColor: '#FF9F43',
        gradientStart: '#FF9F43', gradientEnd: '#F97316',
        features: '["GPS","运动","语音"]', extraInfo: '电量 87%',
        isBuiltin: true, isOnline: true, battery: 87
      });
    }
    if (!hasFeeder) {
      await this.addDevice({
        name: '智能喂食器', model: 'AutoFeeder X1', type: 'feeder',
        iconSymbol: '🍽️', iconColor: '#00B4D8',
        gradientStart: '#00B4D8', gradientEnd: '#3B82F6',
        features: '["定时","智能","远程"]', extraInfo: '余粮 68%',
        isBuiltin: true, isOnline: true, battery: 100
      });
    }
    if (!hasWater) {
      await this.addDevice({
        name: '智能饮水机', model: 'WaterFlow Plus', type: 'water',
        iconSymbol: '💧', iconColor: '#3B82F6',
        gradientStart: '#60A5FA', gradientEnd: '#06B6D4',
        features: '[]', extraInfo: '水量 64%',
        isBuiltin: true, isOnline: true, battery: 100
      });
    }
  }

  // ResultSet 映射
  private mapResultToDevice(rs: relationalStore.ResultSet): DeviceEntity {
    return {
      id: rs.getLong(rs.getColumnIndex('id')),
      userId: rs.getLong(rs.getColumnIndex('user_id')),
      name: rs.getString(rs.getColumnIndex('name')),
      model: rs.getString(rs.getColumnIndex('model')),
      type: rs.getString(rs.getColumnIndex('type')),
      iconSymbol: rs.getString(rs.getColumnIndex('icon_symbol')),
      iconColor: rs.getString(rs.getColumnIndex('icon_color')),
      gradientStart: rs.getString(rs.getColumnIndex('gradient_start')),
      gradientEnd: rs.getString(rs.getColumnIndex('gradient_end')),
      features: rs.getString(rs.getColumnIndex('features')),
      extraInfo: rs.getString(rs.getColumnIndex('extra_info')),
      isBuiltin: rs.getLong(rs.getColumnIndex('is_builtin')) === 1,
      isOnline: rs.getLong(rs.getColumnIndex('is_online')) === 1,
      battery: rs.getLong(rs.getColumnIndex('battery')),
      createdAt: rs.getString(rs.getColumnIndex('created_at'))
    };
  }
}

export const DeviceService = new DeviceServiceClass();
