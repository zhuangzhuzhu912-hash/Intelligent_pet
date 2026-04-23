// 加速度数据接口
export interface AccelerationData {
  x: number;
  y: number;
  z: number;
  timestamp: number;
}
// 步数检测参数接口
export interface StepDetectionParams {
  accelerationThreshold: number;
  stepTimeWindow: number;
  minStepInterval: number;
  filterAlpha: number;
}
// 运动记录接口
export interface MotionRecord {
  id: number;
  steps: number;
  distance: number;
  calories: number;
}

// 运动记录数据（用于数据库存储）
export interface MotionRecordData {
  pet_id: number;
  user_id: number;
  record_date: string;
  steps: number;
  distance: number;
  calories: number;
  goal_steps: number;
  duration_minutes: number;
  created_at: string;
}

export interface HardwareTelemetryData {
  device_id: string;
  device_type: string;
  metric_type: string;
  value: number;
  unit: string;
  timestamp: string;
  created_at: string;
}

// 传感器服务状态
export interface SensorServiceStatus {
  isMonitoring: boolean;
  useSimulation: boolean;
  currentPetId: number;
  currentDeviceId: string;
  stepCount: number;
  distance: number;
  calories: number;
  bufferSize: number;
  lastStepTime: string | null;
}