// BLE 数据桥接服务 — 将 BleService 的 JSON 传感器数据路由到下游服务
// 连接 BleService（BLE 通信层）↔ SensorService / LocationService（业务层）

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BleService } from './BleService';
import { SensorService } from './SensorService';
import { LocationService } from './LocationService';
import type { BleSensorData, BleGpsData, BleMotionData } from '../models/BleModels';

const TAG: string = 'BleDataBridge';
const DOMAIN: number = 0x0000;

class BleDataBridgeClass {
  private isBridged: boolean = false;

  /** 建立 BLE 数据 → 下游服务的桥接 */
  bridge(): void {
    if (this.isBridged) {
      hilog.warn(DOMAIN, TAG, 'Bridge already established');
      return;
    }

    BleService.onSensorData((data: BleSensorData) => {
      try {
        this.routeData(data);
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Error routing BLE data: ${JSON.stringify(err)}`);
      }
    });

    this.isBridged = true;
    hilog.info(DOMAIN, TAG, 'BLE data bridge established');
  }

  /** 拆除桥接 */
  unbridge(): void {
    // 注意：回调由 BleService.release() 统一清理
    this.isBridged = false;
    hilog.info(DOMAIN, TAG, 'BLE data bridge removed');
  }

  /** 路由一条完整的传感器数据到对应服务 */
  private routeData(data: BleSensorData): void {
    // GPS → LocationService
    if (data.gps) {
      this.routeGps(data.gps);
    } else if (data.gpsError) {
      hilog.debug(DOMAIN, TAG, `GPS not available: ${data.gpsError}`);
    }

    // 运动 → SensorService
    if (data.motion) {
      this.routeMotion(data.motion);
    }

    // 温湿度 → SensorService（作为遥测数据存入数据库）
    if (data.temp !== undefined) {
      SensorService.receiveBleTelemetry('temperature', data.temp, '°C');
    }
    if (data.hum !== undefined) {
      SensorService.receiveBleTelemetry('humidity', data.hum, '%');
    }
  }

  /** 路由 GPS 数据到 LocationService */
  private routeGps(gps: BleGpsData): void {
    // 仅在有有效定位时写入
    if (gps.fix > 0) {
      LocationService.receiveBleGpsLocation(gps);
    } else {
      hilog.debug(DOMAIN, TAG, `GPS fix=0, skipping location update`);
    }
  }

  /** 路由运动数据到 SensorService */
  private routeMotion(motion: BleMotionData): void {
    SensorService.receiveBleMotionData(motion);
  }

  // ==========================================================================
  // 便捷操作
  // ==========================================================================

  /** 一键启动 BLE 数据监测
   * @param deviceId BLE 设备 ID（来自扫描结果）
   * @param petId    关联的宠物 ID
   */
  async startMonitoring(deviceId: string, petId: number): Promise<void> {
    try {
      // 1) 建立数据桥接
      this.bridge();

      // 2) 连接 BLE 设备
      await BleService.connect(deviceId);

      // 3) 开始 BLE 模式下的传感器监测
      await SensorService.startMonitoring(petId, deviceId, false, true);

      // 4) 开始定位跟踪（数据由 BLE GPS 提供）
      // 注意：不调用 LocationService.startTracking()，因为它会尝试使用手机 GPS。
      // BLE GPS 数据由 BleDataBridge.routeGps() 直接写入。

      // 5) 开始轮询传感器数据
      BleService.startPolling(5000);

      hilog.info(DOMAIN, TAG, `BLE monitoring started for pet ${petId}, device ${deviceId}`);
    } catch (err) {
      const msg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to start BLE monitoring: ${msg}`);
      throw new Error(msg);
    }
  }

  /** 一键停止 BLE 数据监测 */
  async stopMonitoring(): Promise<void> {
    try {
      BleService.stopPolling();
      BleService.disconnect();
      this.unbridge();
      await SensorService.stopMonitoring();
      hilog.info(DOMAIN, TAG, 'BLE monitoring stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error stopping BLE monitoring: ${JSON.stringify(err)}`);
    }
  }
}

// 单例导出
export const BleDataBridge = new BleDataBridgeClass();
