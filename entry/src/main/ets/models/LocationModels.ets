// 定位服务相关接口
// 用于 LocationService 的类型定义

import type { LocationPoint } from './DataModels';

// 定位服务状态
export interface LocationServiceStatus {
  isTracking: boolean;
  currentPetId: number;
  currentDeviceId: string;
  lastLocation: LocationPoint | null;
  callbackCount: number;
  errorCallbackCount: number;
}
