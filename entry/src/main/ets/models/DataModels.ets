// 设备类型枚举
export enum DeviceType {
  COLLAR = 'collar',
  FEEDER = 'feeder',
  WATER = 'water',
  CAMERA = 'camera',
  LITTER_BOX = 'litter_box',
  THERMOMETER = 'thermometer',
  TOY = 'toy',
  OTHER = 'other'
}

// 喂食状态枚举
export enum FeedingStatus {
  COMPLETED = 'completed',
  PENDING = 'pending',
  ADAPTIVE = 'adaptive'
}

// 喂食记录类型枚举
export enum FeedingRecordType {
  SCHEDULED = 'scheduled',
  EXERCISE_REWARD = 'exercise_reward',
  MANUAL = 'manual'
}

// 疫苗状态枚举
export enum VaccineStatus {
  DONE = 'done',
  PENDING = 'pending'
}

// 宠物信息（UI 展示用）
export interface PetInfo {
  id: string;
  name: string;
  breed: string;
  age: number;
  weight: number;
  gender: string;
  isOnline: boolean;
  vaccineStatus: string;
}

// 设备信息
export interface DeviceInfo {
  id: string;
  name: string;
  model: string;
  type: DeviceType;
  isOnline: boolean;
  battery?: number;
  iconSymbol: string;
  iconColor: string;
  gradientColors: [string, string];
  features: string[];
  extraInfo?: string;
}

// 位置信息
export interface LocationInfo {
  address: string;
  distance: string;
  description: string;
  updateTime: string;
}

// 运动数据
export interface ActivityData {
  steps: number;
  distance: number;
  calories: number;
  goalPercent: number;
  goalSteps: number;
  comparedYesterday: string;
}

// 喂食计划
export interface FeedingPlan {
  time: string;
  label: string;
  amount: number;
  unit: string;
  status: FeedingStatus;
  note?: string;
}

// 喂食记录
export interface FeedingRecord {
  time: string;
  type: FeedingRecordType;
  label: string;
  amount: string;
  isHighlight: boolean;
}

// 喂食器状态
export interface FeederStatus {
  foodRemaining: number;
  foodCapacity: number;
  waterRemaining: number;
  waterCapacity: number;
  nextMealTime: string;
  isAdaptiveEnabled: boolean;
}

// 健康数据
export interface HealthData {
  weight: number;
  temperature: number;
}

// 疫苗记录
export interface VaccineRecord {
  id?: number;
  petId?: number;
  name: string;
  date: string;
  status: VaccineStatus;
}

// 就诊记录
export interface MedicalRecord {
  id?: number;
  petId?: number;
  title: string;
  date: string;
  description: string;
  hospital: string;
}

// 体重记录
export interface WeightRecord {
  id?: number;
  petId: number;
  weight: number;
  recordDate: string;
}

// 周运动趋势
export interface WeeklyActivity {
  day: string;
  percent: number;
  isToday: boolean;
}

// 用户信息（UI 展示用）
export interface UserInfo {
  name: string;
  userId: string;
  isVip: boolean;
  petCount: number;
  deviceCount: number;
  usageDays: number;
  linkageScenes: number;
}

// 菜单项
export interface MenuItem {
  icon: Resource;
  iconColor: string;
  label: string;
  badge?: number;
}

// ---- 数据库相关补充类型 ----

// 宠物选择器项（用于多宠物切换 UI）
export interface PetSelectorItem {
  id: number;
  name: string;
  breed: string;
  avatar: string;
}

// 运动日报摘要
export interface DailyMotionSummary {
  date: string;
  steps: number;
  distance: number;
  calories: number;
  goalPercent: number;
}

// 喂食日报摘要
export interface DailyFeedSummary {
  date: string;
  totalAmount: number;
  feedCount: number;
}

// ===== 硬件相关扩展接口 =====

// 位置点数据
export interface LocationPoint {
  latitude: number;
  longitude: number;
  timestamp: string;
  accuracy: number;
  altitude?: number;
  speed?: number;
}

// 运动轨迹
export interface Trajectory {
  date: string;
  points: LocationPoint[];
  totalDistance: number;
  duration: number; // 秒
}

// 硬件命令类型
export enum HardwareCommandType {
  FIND_PET = 'find_pet',           // 一键寻宠
  VOICE_CALL = 'voice_call',       // 语音对讲
  GET_STATUS = 'get_status',       // 获取状态
  FEED_NOW = 'feed_now',           // 立即投喂
  SET_SCHEDULE = 'set_schedule',   // 设置计划
  CALIBRATE = 'calibrate'          // 校准
}

// 硬件命令
export interface HardwareCommand {
  type: HardwareCommandType;
  deviceId: string;
  timestamp: string;
  payload?: Record<string, Object>;
}

// 硬件状态
export interface HardwareStatus {
  deviceId: string;
  deviceType: DeviceType;
  battery: number;
  signalStrength: number;
  lastSeen: string;
  hardwareVersion: string;
  temperature?: number;
  errors?: string[];
}

// 项圈硬件状态
export interface CollarHardwareStatus extends HardwareStatus {
  steps: number;
  distance: number;
  calories: number;
  isMoving: boolean;
  lastLocation?: LocationPoint;
}

// 喂食器硬件状态
export interface FeederHardwareStatus extends HardwareStatus {
  foodRemaining: number;
  foodCapacity: number;
  waterRemaining: number;
  waterCapacity: number;
  servoPosition: number;
  weightSensorValue: number;
  lastFeedTime: string;
  feedCountToday: number;
}

// 传感器数据
export interface SensorData {
  timestamp: string;
  accelerometer: AccelerometerData;
  steps: number;
  distance: number;
  calories: number;
}

// 加速度计数据
export interface AccelerometerData {
  timestamp: string | number;
  x: number;
  y: number;
  z: number;
}

// 喂食计划项
export interface FeedingScheduleItem {
  id?: number;
  petId: number;
  time: string;           // HH:mm格式
  label: string;
  amount: number;
  unit: string;
  isActive: boolean;
  isAdaptive: boolean;    // 是否启用自适应
  minAmount: number;      // 最小投喂量
  maxAmount: number;      // 最大投喂量
  daysOfWeek: number[];   // 0-6表示周日到周六
}

// 自适应投喂规则
export interface AdaptiveFeedingRule {
  stepsThreshold: number;      // 步数阈值
  amountAdjustment: number;    // 投喂量调整（百分比）
  isReward: boolean;           // 是否为奖励零食
}

// 位置围栏
export interface GeoFence {
  id?: number;
  petId: number;
  name: string;
  latitude: number;
  longitude: number;
  radius: number;        // 米
  isActive: boolean;
  notificationEnabled: boolean;
}

// 硬件遥测数据
export interface HardwareTelemetry {
  deviceId: string;
  deviceType: string;
  metricType: string;
  value: number;
  unit: string;
  timestamp: string;
}
