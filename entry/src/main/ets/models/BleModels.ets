// BLE 蓝牙通信 — 类型定义与常量
// 与 Hi3863 开发板 cmd_handler.c 的 JSON 协议对齐

// ==========================================================================
// GATT UUID 常量（与开发板固件对齐）
// ==========================================================================

/** 主服务 UUID */
export const BLE_SERVICE_UUID = '0000ABCE-0000-1000-8000-00805F9B34FB';

/** 指令/数据特征 UUID（Write 下发指令 + Notify 接收数据，共用同一特征） */
export const CHAR_CMD_DATA_UUID = '0000CDE0-0000-1000-8000-00805F9B34FB';

// ==========================================================================
// BLE 连接状态枚举
// ==========================================================================

export enum BleConnectionState {
  IDLE = 'idle',
  SCANNING = 'scanning',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  DISCOVERING = 'discovering',
  READY = 'ready',
  DISCONNECTED = 'disconnected',
}

// ==========================================================================
// 扫描到的 BLE 设备
// ==========================================================================

export interface BleScanDevice {
  deviceId: string;
  deviceName: string;
  rssi: number;
}

// ==========================================================================
// 开发板返回的传感器数据（对应 cmd_handler.c request_data 响应的 JSON）
// ==========================================================================

export interface BleGpsData {
  lat: number;        // 纬度（度）
  lon: number;        // 经度（度）
  alt: number;        // 海拔（米）
  fix: number;        // 定位质量：0=无定位, 1=GPS定位, 2=差分GPS
  sats: number;       // 可见卫星数
}

export interface BleMotionData {
  isMoving: number;   // 运动状态：0=静止, 1=运动中
  calories: number;   // 累计卡路里
}

export interface BleSensorData {
  temp?: number;          // 温度（℃）
  hum?: number;           // 湿度（%RH）
  motion?: BleMotionData; // 运动数据
  gps?: BleGpsData;       // GPS 定位数据
  gpsError?: string;      // GPS 错误信息（如 "no_fix"）
  raw?: string;           // 原始 JSON 文本（调试用）
}

// ==========================================================================
// 支持的命令（与 cmd_handler.c g_cmd_table 对齐）
// ==========================================================================

export enum BleCommand {
  SET_MOTION_CONFIG = 'set_motion_config',
  GET_MOTION_CONFIG = 'get_motion_config',
  RESET_MOTION = 'reset_motion',
  GET_STATUS = 'get_status',
  REQUEST_DATA = 'request_data',
}

// ==========================================================================
// 回调类型
// ==========================================================================

export type BleDeviceCallback = (device: BleScanDevice) => void;
export type BleConnectionCallback = (state: BleConnectionState, error?: string) => void;
export type BleSensorDataCallback = (data: BleSensorData) => void;
