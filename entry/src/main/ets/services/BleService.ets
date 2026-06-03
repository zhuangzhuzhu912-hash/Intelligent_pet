// BLE 中心管理器 — 负责扫描、连接、GATT 操作、JSON 指令交互与数据接收
// 与 Hi3863 开发板 cmd_handler.c 的 BLE + JSON 协议对齐

import ble from '@ohos.bluetooth.ble';
import { hilog } from '@kit.PerformanceAnalysisKit';

import type {
  BleScanDevice, BleSensorData, BleGpsData, BleMotionData,
  BleDeviceCallback, BleConnectionCallback, BleSensorDataCallback,
} from '../models/BleModels';
import {
  BleConnectionState, BleCommand,
  BLE_SERVICE_UUID, CHAR_CMD_DATA_UUID,
} from '../models/BleModels';

const TAG: string = 'BleService';
const DOMAIN: number = 0x0000;

// ==========================================================================
// BLE 状态常量（代替 constant 模块 — 避免 SDK 版本差异）
// ==========================================================================

/** 蓝牙开关状态 */
const BT_STATE_OFF: number = 13;
const BT_STATE_ON: number = 10;

/** Profile 连接状态 */
const PROFILE_STATE_DISCONNECTED: number = 0;
const PROFILE_STATE_CONNECTED: number = 2;

// ==========================================================================
// 扫描/重连/轮询配置
// ==========================================================================

const SCAN_TIMEOUT_MS: number = 10000;
const MAX_SCAN_RESULTS: number = 50;
const MAX_RECONNECT_ATTEMPTS: number = 3;
const RECONNECT_BACKOFF_MS: number[] = [1000, 2000, 4000];
const DEFAULT_POLL_INTERVAL_MS: number = 5000;

// ==========================================================================
// 工具函数
// ==========================================================================

/** ArrayBuffer → UTF-8 字符串 */
function bufToString(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf);
  let result = '';
  for (let i = 0; i < bytes.length; i++) {
    result += String.fromCharCode(bytes[i]);
  }
  return result;
}

/**
 * 构建 JSON 指令字符串
 * 注意：不使用解构参数 (arkts-no-destruct-params)
 */
function buildCommandJson(cmd: string, params?: Record<string, Object>): string {
  if (params) {
    const entries = Object.entries(params);
    const parts: string[] = [];
    for (let i = 0; i < entries.length; i++) {
      const key = entries[i][0];
      const value = entries[i][1];
      const val = typeof value === 'string' ? `"${value}"` : String(value);
      parts.push(`"${key}":${val}`);
    }
    const paramsStr = parts.join(',');
    return `{"cmd":"${cmd}","params":{${paramsStr}}}`;
  }
  return `{"cmd":"${cmd}"}`;
}

/** 构建 BLE 特征对象（用于 write / setNotification 操作） */
function makeCharacteristic(
  serviceUuid: string,
  charUuid: string,
  value?: ArrayBuffer
): ble.BLECharacteristic {
  return {
    serviceUuid: serviceUuid,
    characteristicUuid: charUuid,
    characteristicValue: value ?? new ArrayBuffer(0),
    descriptors: [],
    properties: undefined,
  };
}

// ==========================================================================
// BleServiceClass（单例）
// ==========================================================================

class BleServiceClass {
  private gattClient: ble.GattClientDevice | null = null;
  private connectionState: BleConnectionState = BleConnectionState.IDLE;
  private scanResults: Map<string, BleScanDevice> = new Map();
  private scanTimeoutId: number = 0;

  private pollIntervalId: number = 0;
  private pollIntervalMs: number = DEFAULT_POLL_INTERVAL_MS;

  private reconnectAttempts: number = 0;
  private reconnectDeviceId: string = '';
  private reconnectTimerId: number = 0;

  private deviceFoundCallbacks: BleDeviceCallback[] = [];
  private connectionCallbacks: BleConnectionCallback[] = [];
  private sensorDataCallbacks: BleSensorDataCallback[] = [];

  // ==========================================================================
  // 初始化与释放
  // ==========================================================================

  /** 初始化 BLE 服务（注册 BLE 设备发现事件） */
  init(): void {
    try {
      ble.on('BLEDeviceFind', (data: Array<ble.ScanResult>) => {
        if (this.connectionState !== BleConnectionState.SCANNING) {
          return;
        }
        const results: ble.ScanResult[] = data;
        for (let i = 0; i < results.length; i++) {
          if (this.scanResults.size >= MAX_SCAN_RESULTS) {
            break;
          }
          const result = results[i];
          const uuids: string[] = result.serviceUuids ?? [];
          const hasTargetService = uuids.length === 0 ||
            uuids.some((uuid: string) => uuid.toUpperCase() === BLE_SERVICE_UUID.toUpperCase());
          if (!hasTargetService) {
            continue;
          }
          const device: BleScanDevice = {
            deviceId: result.deviceId,
            deviceName: result.deviceName.length > 0 ? result.deviceName : 'PetHub-Device',
            rssi: result.rssi,
          };
          this.scanResults.set(result.deviceId, device);
          this.notifyDeviceFound(device);
        }
      });

      this.connectionState = BleConnectionState.IDLE;
      hilog.info(DOMAIN, TAG, 'BleService initialized');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `BleService init failed: ${JSON.stringify(err)}`);
    }
  }

  /** 释放所有资源 */
  release(): void {
    this.stopPolling();
    this.stopScan();
    this.disconnect();
    this.cancelReconnect();
    this.scanResults.clear();

    try {
      ble.off('BLEDeviceFind');
    } catch (_err) {
      // 忽略卸载错误
    }

    this.deviceFoundCallbacks = [];
    this.connectionCallbacks = [];
    this.sensorDataCallbacks = [];

    this.connectionState = BleConnectionState.IDLE;
    hilog.info(DOMAIN, TAG, 'BleService released');
  }

  // ==========================================================================
  // BLE 扫描
  // ==========================================================================

  /** 开始扫描 BLE 设备 */
  startScan(): void {
    if (this.connectionState === BleConnectionState.SCANNING) {
      hilog.warn(DOMAIN, TAG, 'Already scanning');
      return;
    }

    try {
      this.scanResults.clear();
      // 使用简化扫描参数，避免 ScanDuty/MatchMode 常量版本差异
      ble.startBLEScan(null, {
        interval: 0,
        dutyMode: 0,   // SCAN_MODE_LOW_POWER
        matchMode: 1,  // MATCH_MODE_AGGRESSIVE
      });
      this.updateConnectionState(BleConnectionState.SCANNING);
      hilog.info(DOMAIN, TAG, 'BLE scan started');

      this.scanTimeoutId = setTimeout(() => {
        if (this.connectionState === BleConnectionState.SCANNING) {
          this.stopScan();
          hilog.info(DOMAIN, TAG, 'BLE scan auto-stopped (timeout)');
        }
      }, SCAN_TIMEOUT_MS);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Start scan failed: ${JSON.stringify(err)}`);
      this.updateConnectionState(BleConnectionState.IDLE);
    }
  }

  /** 停止扫描 */
  stopScan(): void {
    if (this.connectionState !== BleConnectionState.SCANNING) {
      return;
    }
    try {
      ble.stopBLEScan();
      if (this.scanTimeoutId) {
        clearTimeout(this.scanTimeoutId);
        this.scanTimeoutId = 0;
      }
      hilog.info(DOMAIN, TAG, `Scan stopped, ${this.scanResults.size} device(s) found`);
      this.updateConnectionState(BleConnectionState.IDLE);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Stop scan failed: ${JSON.stringify(err)}`);
    }
  }

  /** 获取扫描结果列表 */
  getScanResults(): BleScanDevice[] {
    const results: BleScanDevice[] = [];
    const values = this.scanResults.values();
    let entry = values.next();
    while (!entry.done) {
      results.push(entry.value);
      entry = values.next();
    }
    return results;
  }

  // ==========================================================================
  // BLE 连接
  // ==========================================================================

  /** 连接到指定设备 */
  async connect(deviceId: string): Promise<void> {
    if (this.gattClient &&
      (this.connectionState === BleConnectionState.CONNECTED ||
        this.connectionState === BleConnectionState.READY)) {
      hilog.warn(DOMAIN, TAG, 'Already connected, disconnecting first');
      this.disconnect();
    }

    this.reconnectDeviceId = deviceId;
    this.reconnectAttempts = 0;

    return this.performConnect(deviceId);
  }

  /** 执行连接逻辑 */
  private async performConnect(deviceId: string): Promise<void> {
    try {
      this.updateConnectionState(BleConnectionState.CONNECTING);

      this.gattClient = ble.createGattClientDevice(deviceId);
      this.registerGattCallbacks();

      await this.gattClient.connect();
      hilog.info(DOMAIN, TAG, `GATT connected to ${deviceId}`);
      this.updateConnectionState(BleConnectionState.CONNECTED);

      this.updateConnectionState(BleConnectionState.DISCOVERING);
      await this.discoverServices();

      this.updateConnectionState(BleConnectionState.READY);
      this.reconnectAttempts = 0;
      hilog.info(DOMAIN, TAG, 'BLE connection ready');
    } catch (err) {
      const msg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Connection failed: ${msg}`);
      this.updateConnectionState(BleConnectionState.DISCONNECTED, msg);
      this.attemptReconnect();
      throw new Error(msg);
    }
  }

  /** 断开连接 */
  disconnect(): void {
    this.cancelReconnect();
    if (this.gattClient) {
      try {
        this.gattClient.disconnect();
      } catch (_err) {
        // ignore
      }
      this.gattClient = null;
    }
    this.updateConnectionState(BleConnectionState.DISCONNECTED);
  }

  /** 获取当前连接状态 */
  getConnectionState(): BleConnectionState {
    return this.connectionState;
  }

  // ==========================================================================
  // GATT 操作（私有）
  // ==========================================================================

  /** 注册 GATT 客户端事件监听 */
  private registerGattCallbacks(): void {
    if (!this.gattClient) {
      return;
    }

    this.gattClient.on('BLEConnectionStateChange', (data: ble.BLEConnectionChangeState) => {
      hilog.info(DOMAIN, TAG, `BLE connection state: ${data.state}`);
      if (data.state === PROFILE_STATE_DISCONNECTED) {
        this.updateConnectionState(BleConnectionState.DISCONNECTED, 'Device disconnected');
        this.attemptReconnect();
      }
    });

    this.gattClient.on('BLECharacteristicChange', (data: ble.BLECharacteristic) => {
      const value: ArrayBuffer = data.characteristicValue;
      if (!value || value.byteLength === 0) {
        return;
      }
      const text = bufToString(value);
      hilog.debug(DOMAIN, TAG, `Notify received (${value.byteLength}B): ${text.substring(0, 120)}`);
      this.parseAndDispatch(text);
    });
  }

  /** 发现 GATT 服务并启用通知 */
  private async discoverServices(): Promise<void> {
    if (!this.gattClient) {
      throw new Error('No GATT client');
    }

    const services = await this.gattClient.getServices();
    hilog.info(DOMAIN, TAG, `Discovered ${services.length} service(s)`);

    const targetService = services.find(
      (s: ble.GattService) => s.serviceUuid.toUpperCase() === BLE_SERVICE_UUID.toUpperCase()
    );
    if (!targetService) {
      for (let i = 0; i < services.length; i++) {
        const s = services[i];
        hilog.warn(DOMAIN, TAG, `  Service: ${s.serviceUuid}`);
        const chars = s.characteristics;
        for (let j = 0; j < chars.length; j++) {
          hilog.warn(DOMAIN, TAG, `    Char: ${chars[j].characteristicUuid}`);
        }
      }
      throw new Error(`Target service ${BLE_SERVICE_UUID} not found`);
    }

    const cmdChar = targetService.characteristics.find(
      (c: ble.BLECharacteristic) =>
        c.characteristicUuid.toUpperCase() === CHAR_CMD_DATA_UUID.toUpperCase()
    );
    if (!cmdChar) {
      throw new Error(`CMD/Data characteristic ${CHAR_CMD_DATA_UUID} not found`);
    }

    // 启用 Notify（传入完整特征对象，含必要字段）
    const charObj = makeCharacteristic(BLE_SERVICE_UUID, CHAR_CMD_DATA_UUID);
    await this.gattClient.setCharacteristicChangeNotification(charObj, true);
    hilog.info(DOMAIN, TAG, 'Notification enabled on CMD/Data characteristic');

    // 协商 MTU
    try {
      this.gattClient.setBLEMtuSize(256);
    } catch (_err) {
      hilog.warn(DOMAIN, TAG, 'MTU negotiation failed (default 23 will be used)');
    }
  }

  // ==========================================================================
  // JSON 指令发送
  // ==========================================================================

  /** 发送 JSON 指令到开发板 */
  async sendJsonCommand(cmd: string, params?: Record<string, Object>): Promise<void> {
    if (!this.gattClient || this.connectionState !== BleConnectionState.READY) {
      throw new Error('BLE not ready — must be in READY state');
    }

    const jsonStr = buildCommandJson(cmd, params);
    const bytes = new Uint8Array(jsonStr.length);
    for (let i = 0; i < jsonStr.length; i++) {
      bytes[i] = jsonStr.charCodeAt(i);
    }

    const writeObj = makeCharacteristic(BLE_SERVICE_UUID, CHAR_CMD_DATA_UUID, bytes.buffer as ArrayBuffer);

    try {
      await this.gattClient.writeCharacteristicValue(writeObj, ble.GattWriteType.WRITE_NO_RESPONSE);
      hilog.debug(DOMAIN, TAG, `Command sent: ${jsonStr}`);
    } catch (err) {
      const msg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Write failed: ${msg}`);
      throw new Error(msg);
    }
  }

  /** 请求传感器数据（发送 request_data 指令） */
  async requestSensorData(): Promise<void> {
    return this.sendJsonCommand(BleCommand.REQUEST_DATA);
  }

  /** 发送 set_motion_config 指令 */
  async setMotionConfig(config: Record<string, Object>): Promise<void> {
    return this.sendJsonCommand(BleCommand.SET_MOTION_CONFIG, config);
  }

  /** 发送 get_status 指令 */
  async getDeviceStatus(): Promise<void> {
    return this.sendJsonCommand(BleCommand.GET_STATUS);
  }

  /** 发送 reset_motion 指令 */
  async resetMotion(): Promise<void> {
    return this.sendJsonCommand(BleCommand.RESET_MOTION);
  }

  // ==========================================================================
  // 数据接收与解析
  // ==========================================================================

  /** 解析 JSON 响应并分发 */
  private parseAndDispatch(text: string): void {
    try {
      const parsed: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
      const sensorData: BleSensorData = { raw: text };

      if (typeof parsed['temp'] !== 'undefined') {
        sensorData.temp = Number(parsed['temp']);
      }
      if (typeof parsed['hum'] !== 'undefined') {
        sensorData.hum = Number(parsed['hum']);
      }

      if (typeof parsed['motion'] === 'object' && parsed['motion'] !== null) {
        const m = parsed['motion'] as Record<string, Object>;
        const motionData: BleMotionData = {
          isMoving: Number(m['is_moving'] ?? 0),
          calories: Number(m['calories'] ?? 0),
        };
        sensorData.motion = motionData;
      }

      if (typeof parsed['gps'] === 'string') {
        sensorData.gpsError = parsed['gps'] as string;
      } else if (typeof parsed['gps'] === 'object' && parsed['gps'] !== null) {
        const g = parsed['gps'] as Record<string, Object>;
        const gpsData: BleGpsData = {
          lat: Number(g['lat'] ?? 0),
          lon: Number(g['lon'] ?? 0),
          alt: Number(g['alt'] ?? 0),
          fix: Number(g['fix'] ?? 0),
          sats: Number(g['sats'] ?? 0),
        };
        sensorData.gps = gpsData;
      }

      this.notifySensorData(sensorData);
    } catch (_err) {
      hilog.error(DOMAIN, TAG, `JSON parse error, raw: ${text.substring(0, 200)}`);
    }
  }

  // ==========================================================================
  // 轮询
  // ==========================================================================

  /** 开始定时轮询传感器数据 */
  startPolling(intervalMs: number = DEFAULT_POLL_INTERVAL_MS): void {
    this.stopPolling();
    this.pollIntervalMs = intervalMs;
    hilog.info(DOMAIN, TAG, `Starting polling every ${intervalMs}ms`);

    this.requestSensorData().catch((err: Error) => {
      hilog.error(DOMAIN, TAG, `Initial poll failed: ${err.message}`);
    });

    this.pollIntervalId = setInterval(() => {
      this.requestSensorData().catch((err: Error) => {
        hilog.warn(DOMAIN, TAG, `Poll failed: ${err.message}`);
      });
    }, intervalMs);
  }

  /** 停止轮询 */
  stopPolling(): void {
    if (this.pollIntervalId) {
      clearInterval(this.pollIntervalId);
      this.pollIntervalId = 0;
      hilog.info(DOMAIN, TAG, 'Polling stopped');
    }
  }

  // ==========================================================================
  // 断连重连
  // ==========================================================================

  private attemptReconnect(): void {
    if (!this.reconnectDeviceId || this.reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      hilog.warn(DOMAIN, TAG, `Reconnect aborted (attempts: ${this.reconnectAttempts})`);
      return;
    }

    const delay = RECONNECT_BACKOFF_MS[this.reconnectAttempts];
    this.reconnectAttempts++;
    hilog.info(DOMAIN, TAG,
      `Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS})`);

    this.reconnectTimerId = setTimeout(() => {
      this.performConnect(this.reconnectDeviceId).catch((err: Error) => {
        hilog.error(DOMAIN, TAG, `Reconnect failed: ${err.message}`);
      });
    }, delay);
  }

  private cancelReconnect(): void {
    this.reconnectAttempts = MAX_RECONNECT_ATTEMPTS;
    this.reconnectDeviceId = '';
    if (this.reconnectTimerId) {
      clearTimeout(this.reconnectTimerId);
      this.reconnectTimerId = 0;
    }
  }

  // ==========================================================================
  // 回调管理
  // ==========================================================================

  onDeviceFound(cb: BleDeviceCallback): void { this.deviceFoundCallbacks.push(cb); }
  offDeviceFound(cb: BleDeviceCallback): void {
    const idx = this.deviceFoundCallbacks.indexOf(cb);
    if (idx >= 0) { this.deviceFoundCallbacks.splice(idx, 1); }
  }

  onConnectionChange(cb: BleConnectionCallback): void { this.connectionCallbacks.push(cb); }
  offConnectionChange(cb: BleConnectionCallback): void {
    const idx = this.connectionCallbacks.indexOf(cb);
    if (idx >= 0) { this.connectionCallbacks.splice(idx, 1); }
  }

  onSensorData(cb: BleSensorDataCallback): void { this.sensorDataCallbacks.push(cb); }
  offSensorData(cb: BleSensorDataCallback): void {
    const idx = this.sensorDataCallbacks.indexOf(cb);
    if (idx >= 0) { this.sensorDataCallbacks.splice(idx, 1); }
  }

  // ==========================================================================
  // 内部通知
  // ==========================================================================

  private notifyDeviceFound(device: BleScanDevice): void {
    for (let i = 0; i < this.deviceFoundCallbacks.length; i++) {
      try { this.deviceFoundCallbacks[i](device); } catch (_err) { /* skip */ }
    }
  }

  private updateConnectionState(state: BleConnectionState, error?: string): void {
    this.connectionState = state;
    for (let i = 0; i < this.connectionCallbacks.length; i++) {
      try { this.connectionCallbacks[i](state, error); } catch (_err) { /* skip */ }
    }
  }

  private notifySensorData(data: BleSensorData): void {
    for (let i = 0; i < this.sensorDataCallbacks.length; i++) {
      try { this.sensorDataCallbacks[i](data); } catch (err) {
        hilog.error(DOMAIN, TAG, `SensorData callback error: ${JSON.stringify(err)}`);
      }
    }
  }
}

// 单例导出
export const BleService = new BleServiceClass();
