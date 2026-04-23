// 软总线设备发现服务
// 使用 deviceManager 实现项圈、喂食器、手机间的无感自发现与消息传递

import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DeviceDiscoveryService';
const DOMAIN: number = 0x0000;

// 设备类型枚举
export enum DeviceType {
  UNKNOWN = 0,
  COLLAR = 1,    // 智能项圈
  FEEDER = 2,    // 智能喂食器
  PHONE = 3      // 手机
}

// 硬件命令接口
export interface HardwareCommand {
  commandType: string;      // 命令类型，如 "FIND_PET", "FEED", "GET_STATUS"
  payload?: any;            // 命令负载数据
  timestamp: number;        // 时间戳
}

// 发现的设备信息
export interface DiscoveredDevice {
  deviceId: string;
  deviceName: string;
  deviceType: number;       // 原始设备类型数字
  deviceTypeStr: DeviceType; // 解析后的设备类型枚举
  networkId: string;
}

// 设备变更回调
export type DeviceChangeCallback = (devices: DiscoveredDevice[]) => void;

// 设备类型解析函数
function parseDeviceType(deviceType: number, deviceName: string): DeviceType {
  // 根据设备类型数字或设备名称解析设备类型
  switch (deviceType) {
    case 1: // 智能穿戴设备
    case 2: // 智能手表
      return DeviceType.COLLAR;
    case 3: // 智能家居设备
    case 4: // IoT设备
      return DeviceType.FEEDER;
    case 0: // 手机
    case 5: // 平板
      return DeviceType.PHONE;
    default:
      // 根据设备名称关键词进一步识别
      const name = deviceName.toLowerCase();
      if (name.includes('collar') || name.includes('项圈') || name.includes('pet') || name.includes('tracker')) {
        return DeviceType.COLLAR;
      } else if (name.includes('feeder') || name.includes('喂食器') || name.includes('food') || name.includes('dispenser')) {
        return DeviceType.FEEDER;
      } else if (name.includes('phone') || name.includes('手机') || name.includes('mobile')) {
        return DeviceType.PHONE;
      } else {
        return DeviceType.UNKNOWN;
      }
  }
}

class DeviceDiscoveryServiceClass {
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private trustedDevices: DiscoveredDevice[] = [];
  private callbacks: DeviceChangeCallback[] = [];

  // 初始化设备管理器
  init(): void {
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.pethub.intelligent_pet');
      hilog.info(DOMAIN, TAG, 'DeviceManager created');
      this.loadTrustedDevices();
      this.startListening();
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to create DeviceManager: ${JSON.stringify(err)}`);
    }
  }

  // 获取已信任的设备列表（同一组网内）
  private loadTrustedDevices(): void {
    if (!this.deviceManager) {
      return;
    }
    try {
      const devices = this.deviceManager.getAvailableDeviceListSync();
      this.trustedDevices = devices.map((d): DiscoveredDevice => {
        const deviceTypeNum = typeof d.deviceType === 'number' ? d.deviceType : parseInt(d.deviceType) || 0;
        return {
          deviceId: d.deviceId,
          deviceName: d.deviceName,
          deviceType: deviceTypeNum,
          deviceTypeStr: parseDeviceType(deviceTypeNum, d.deviceName),
          networkId: d.networkId || ''
        };
      });
      hilog.info(DOMAIN, TAG, `Found ${this.trustedDevices.length} trusted devices`);
      this.notifyCallbacks();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, `Failed to get trusted devices: ${JSON.stringify(err)}`);
    }
  }

  // 监听设备上下线
  private startListening(): void {
    if (!this.deviceManager) {
      return;
    }
    try {
      this.deviceManager.on('deviceStateChange', (data) => {
        hilog.info(DOMAIN, TAG, `Device state changed: ${JSON.stringify(data)}`);
        this.loadTrustedDevices();
      });
    } catch (err) {
      hilog.warn(DOMAIN, TAG, `Failed to register device listener: ${JSON.stringify(err)}`);
    }
  }

  // 获取当前可用设备
  getAvailableDevices(): DiscoveredDevice[] {
    return [...this.trustedDevices];
  }

  // 获取设备数量
  getDeviceCount(): number {
    return this.trustedDevices.length;
  }

  // 注册设备变更回调
  onDeviceChange(callback: DeviceChangeCallback): void {
    this.callbacks.push(callback);
  }

  // 移除回调
  offDeviceChange(callback: DeviceChangeCallback): void {
    const index = this.callbacks.indexOf(callback);
    if (index >= 0) {
      this.callbacks.splice(index, 1);
    }
  }

  // 通知所有回调
  private notifyCallbacks(): void {
    for (const cb of this.callbacks) {
      cb(this.getAvailableDevices());
    }
  }

  // 按设备类型获取设备
  getDevicesByType(deviceType: DeviceType): DiscoveredDevice[] {
    return this.trustedDevices.filter(device => device.deviceTypeStr === deviceType);
  }

  // 获取智能项圈设备
  getCollarDevices(): DiscoveredDevice[] {
    return this.getDevicesByType(DeviceType.COLLAR);
  }

  // 获取智能喂食器设备
  getFeederDevices(): DiscoveredDevice[] {
    return this.getDevicesByType(DeviceType.FEEDER);
  }

  // 发送命令到指定设备
  // 注意：实际的设备间通信需要通过分布式数据库或RPC实现
  // DeviceManager本身不提供sendMessage接口
  async sendCommandToDevice(deviceId: string, command: HardwareCommand): Promise<void> {
    if (!this.deviceManager) {
      throw new Error('DeviceManager not initialized');
    }

    try {
      // 查找目标设备
      const device = this.trustedDevices.find(d => d.deviceId === deviceId);
      if (!device) {
        throw new Error(`Device ${deviceId} not found`);
      }

      // 构建消息
      const message = {
        command: command.commandType,
        payload: command.payload || {},
        timestamp: command.timestamp,
        source: 'app'
      };

      // 通过日志记录命令（实际应用中应通过分布式数据库同步或RPC调用）
      hilog.info(DOMAIN, TAG, `Command ${command.commandType} prepared for device ${deviceId}: ${JSON.stringify(message)}`);

      // 模拟命令发送延迟
      await new Promise<void>(resolve => setTimeout(resolve, 200));

      hilog.info(DOMAIN, TAG, `Command ${command.commandType} sent to device ${deviceId}`);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to send command to device ${deviceId}: ${errorMsg}`);
      throw err;
    }
  }

  // 释放资源
  release(): void {
    if (this.deviceManager) {
      try {
        this.deviceManager.off('deviceStateChange');
      } catch (e) {
        hilog.warn(DOMAIN, TAG, `Failed to unregister listener: ${JSON.stringify(e)}`);
      }
      this.deviceManager = null;
    }
    this.callbacks = [];
    this.trustedDevices = [];
    hilog.info(DOMAIN, TAG, 'DeviceDiscoveryService released');
  }
}

export const DeviceDiscoveryService = new DeviceDiscoveryServiceClass();
