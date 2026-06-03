// 定位服务
// 使用鸿蒙原生定位能力获取设备位置，支持连续定位和轨迹记录

import { geoLocationManager } from '@kit.LocationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import type { LocationPoint } from '../models/DataModels';
import type { LocationServiceStatus } from '../models/LocationModels';
import type { BleGpsData } from '../models/BleModels';

const TAG: string = 'LocationService';
const DOMAIN: number = 0x0000;

// 定位配置（显式类型声明，满足 arkts-no-untyped-obj-literals）
interface LocationConfig {
  priority: geoLocationManager.LocationRequestPriority;
  scenario: geoLocationManager.LocationRequestScenario;
  maxAccuracy: number;
  timeInterval: number;
  distanceInterval: number;
}
const LOCATION_CONFIG: LocationConfig = {
  priority: geoLocationManager.LocationRequestPriority.FIRST_FIX, // 首次定位优先
  scenario: geoLocationManager.LocationRequestScenario.NAVIGATION, // 导航场景
  maxAccuracy: 50, // 最大精度（米）
  timeInterval: 30000, // 时间间隔30秒
  distanceInterval: 50, // 距离间隔50米
};

// 定位监听器
type LocationCallback = (location: LocationPoint) => void;
type ErrorCallback = (error: Error) => void;

class LocationServiceClass {
  private isTracking: boolean = false;
  private locationCallbacks: LocationCallback[] = [];
  private errorCallbacks: ErrorCallback[] = [];
  private currentPetId: number = -1;
  private currentDeviceId: string = '';
  private lastLocation: LocationPoint | null = null;
  private locationRequest: geoLocationManager.LocationRequest | null = null;

  // 开始定位跟踪
  async startTracking(petId: number, deviceId: string = ''): Promise<void> {
    if (this.isTracking) {
      hilog.warn(DOMAIN, TAG, 'Location tracking already started');
      return;
    }

    try {
      // 检查定位权限
      const hasPermission = await this.checkLocationPermission();
      if (!hasPermission) {
        throw new Error('Location permission not granted');
      }

      this.currentPetId = petId;
      this.currentDeviceId = deviceId;

      // 创建定位请求
      this.locationRequest = {
        priority: LOCATION_CONFIG.priority,
        scenario: LOCATION_CONFIG.scenario,
        maxAccuracy: LOCATION_CONFIG.maxAccuracy,
        timeInterval: LOCATION_CONFIG.timeInterval,
        distanceInterval: LOCATION_CONFIG.distanceInterval,
      };

      // 注册位置监听器
      geoLocationManager.on('locationChange', this.locationRequest, this.handleLocationChange.bind(this));

      this.isTracking = true;
      hilog.info(DOMAIN, TAG, `Location tracking started for pet ${petId}, device ${deviceId}`);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to start location tracking: ${errorMessage}`);
      throw new Error(`启动定位跟踪失败: ${errorMessage}`);
    }
  }

  // 停止定位跟踪
  async stopTracking(): Promise<void> {
    if (!this.isTracking) {
      return;
    }

    try {
      geoLocationManager.off('locationChange');
      this.locationRequest = null;

      this.isTracking = false;
      this.currentPetId = -1;
      this.currentDeviceId = '';
      hilog.info(DOMAIN, TAG, 'Location tracking stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to stop location tracking: ${JSON.stringify(err)}`);
      const stopMsg = err instanceof Error ? err.message : JSON.stringify(err);
      throw new Error(stopMsg);
    }
  }

  // 处理位置变化
  private async handleLocationChange(location: geoLocationManager.Location): Promise<void> {
    try {
      const locationPoint: LocationPoint = {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude,
        speed: location.speed,
        timestamp: new Date(Date.now()).toISOString(),
      };

      this.lastLocation = locationPoint;

      // 保存到数据库
      await this.saveLocationPoint(locationPoint);

      // 通知回调
      this.notifyLocationCallbacks(locationPoint);

      hilog.debug(DOMAIN, TAG, `Location updated: ${location.latitude}, ${location.longitude}, accuracy: ${location.accuracy}m`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error handling location change: ${JSON.stringify(err)}`);
      this.notifyErrorCallbacks(err instanceof Error ? err : new Error(JSON.stringify(err)));
    }
  }

  // 保存位置点到数据库
  private async saveLocationPoint(location: LocationPoint): Promise<void> {
    try {
      const userId = await this.getCurrentUserId();
      if (userId === -1) {
        hilog.warn(DOMAIN, TAG, 'Cannot save location: user not logged in');
        return;
      }

      const values: relationalStore.ValuesBucket = {
        pet_id: this.currentPetId,
        user_id: userId,
        device_id: this.currentDeviceId,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude || 0,
        speed: location.speed || 0,
        timestamp: location.timestamp,
        created_at: new Date().toISOString(),
      };

      await RdbHelper.insert('location_track', values);
      hilog.debug(DOMAIN, TAG, 'Location point saved to database');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to save location point: ${JSON.stringify(err)}`);
    }
  }

  // 获取当前位置（单次）
  async getCurrentLocation(): Promise<LocationPoint> {
    try {
      const hasPermission = await this.checkLocationPermission();
      if (!hasPermission) {
        throw new Error('Location permission not granted');
      }

      const location = await geoLocationManager.getCurrentLocation({
        priority: LOCATION_CONFIG.priority,
        scenario: LOCATION_CONFIG.scenario,
        maxAccuracy: LOCATION_CONFIG.maxAccuracy,
        timeoutMs: 10000, // 10秒超时
      });

      const locationPoint: LocationPoint = {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude,
        speed: location.speed,
        timestamp: new Date(Date.now()).toISOString(),
      };

      this.lastLocation = locationPoint;
      return locationPoint;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to get current location: ${errorMessage}`);
      throw new Error(`获取当前位置失败: ${errorMessage}`);
    }
  }

  // 获取最后已知位置
  getLastKnownLocation(): LocationPoint | null {
    return this.lastLocation;
  }

  // 获取宠物当日轨迹
  async getPetTrajectory(petId: number, date: string): Promise<LocationPoint[]> {
    try {
      return await RdbHelper.getPetTrajectory(petId, date);
    } catch (err) {
      const trajMsg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to get pet trajectory: ${trajMsg}`);
      throw new Error(trajMsg);
    }
  }

  // 计算轨迹距离
  calculateTrajectoryDistance(points: LocationPoint[]): number {
    if (points.length < 2) {
      return 0;
    }

    let totalDistance = 0;
    for (let i = 1; i < points.length; i++) {
      const distance = this.calculateDistance(points[i - 1], points[i]);
      totalDistance += distance;
    }

    return totalDistance;
  }

  // 计算两点间距离（Haversine公式）
  private calculateDistance(point1: LocationPoint, point2: LocationPoint): number {
    const R = 6371000; // 地球半径（米）
    const lat1 = point1.latitude * Math.PI / 180;
    const lat2 = point2.latitude * Math.PI / 180;
    const deltaLat = (point2.latitude - point1.latitude) * Math.PI / 180;
    const deltaLon = (point2.longitude - point1.longitude) * Math.PI / 180;

    const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
              Math.cos(lat1) * Math.cos(lat2) *
              Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // 返回米
  }

  // 检查定位权限
  private async checkLocationPermission(): Promise<boolean> {
    try {
      // 这里应该检查实际权限，简化实现返回true
      // 实际应用中应该使用权限管理API
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to check location permission: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 获取当前用户ID（简化实现）
  private async getCurrentUserId(): Promise<number> {
    // 这里应该从用户服务获取当前用户ID
    // 简化实现，返回1
    return 1;
  }

  // 注册位置回调
  onLocationUpdate(callback: LocationCallback): void {
    this.locationCallbacks.push(callback);
  }

  // 移除位置回调
  offLocationUpdate(callback: LocationCallback): void {
    const index = this.locationCallbacks.indexOf(callback);
    if (index >= 0) {
      this.locationCallbacks.splice(index, 1);
    }
  }

  // 注册错误回调
  onError(callback: ErrorCallback): void {
    this.errorCallbacks.push(callback);
  }

  // 移除错误回调
  offError(callback: ErrorCallback): void {
    const index = this.errorCallbacks.indexOf(callback);
    if (index >= 0) {
      this.errorCallbacks.splice(index, 1);
    }
  }

  // 通知位置回调
  private notifyLocationCallbacks(location: LocationPoint): void {
    for (const callback of this.locationCallbacks) {
      try {
        callback(location);
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Error in location callback: ${JSON.stringify(err)}`);
      }
    }
  }

  // 通知错误回调
  private notifyErrorCallbacks(error: Error): void {
    for (const callback of this.errorCallbacks) {
      try {
        callback(error);
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Error in error callback: ${JSON.stringify(err)}`);
      }
    }
  }

  // 获取服务状态
  getStatus(): LocationServiceStatus {
    return {
      isTracking: this.isTracking,
      currentPetId: this.currentPetId,
      currentDeviceId: this.currentDeviceId,
      lastLocation: this.lastLocation,
      callbackCount: this.locationCallbacks.length,
      errorCallbackCount: this.errorCallbacks.length,
    };
  }

  // ==========================================================================
  // BLE GPS 数据接收（由 BleDataBridge 调用）
  // ==========================================================================

  /**
   * 接收来自 BLE 开发板的 GPS 定位数据
   * @param gps 开发板 AT6558 上报的 GPS/北斗定位结果
   */
  receiveBleGpsLocation(gps: BleGpsData): void {
    const locationPoint: LocationPoint = {
      latitude: gps.lat,
      longitude: gps.lon,
      accuracy: gps.sats > 0 ? 10 : 50,  // 卫星数越多精度越高
      altitude: gps.alt,
      speed: 0,
      timestamp: new Date().toISOString(),
    };

    this.lastLocation = locationPoint;

    // 异步保存到数据库
    this.saveLocationPoint(locationPoint).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, `Failed to save BLE GPS point: ${err.message}`);
    });

    // 通知 UI 回调
    this.notifyLocationCallbacks(locationPoint);

    hilog.debug(DOMAIN, TAG,
      `BLE GPS: ${gps.lat.toFixed(6)}, ${gps.lon.toFixed(6)}, alt=${gps.alt}m, fix=${gps.fix}, sats=${gps.sats}`);
  }

  // 清除所有回调
  clearAllCallbacks(): void {
    this.locationCallbacks = [];
    this.errorCallbacks = [];
    hilog.info(DOMAIN, TAG, 'All callbacks cleared');
  }
}

// 单例导出
export const LocationService = new LocationServiceClass();