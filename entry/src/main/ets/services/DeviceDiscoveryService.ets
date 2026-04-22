// 软总线设备发现服务
// 使用 deviceManager 实现项圈、喂食器、手机间的无感自发现与消息传递

import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DeviceDiscoveryService';
const DOMAIN: number = 0x0000;

// 发现的设备信息
export interface DiscoveredDevice {
  deviceId: string;
  deviceName: string;
  deviceType: number;
  networkId: string;
}

// 设备变更回调
export type DeviceChangeCallback = (devices: DiscoveredDevice[]) => void;

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
      this.trustedDevices = devices.map((d): DiscoveredDevice => ({
        deviceId: d.deviceId,
        deviceName: d.deviceName,
        deviceType: typeof d.deviceType === 'number' ? d.deviceType : parseInt(d.deviceType) || 0,
        networkId: d.networkId || ''
      }));
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
