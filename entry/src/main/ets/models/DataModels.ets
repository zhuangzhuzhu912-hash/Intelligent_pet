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
  heartRate: number;
}

// 疫苗记录
export interface VaccineRecord {
  name: string;
  date: string;
  status: VaccineStatus;
}

// 就诊记录
export interface MedicalRecord {
  title: string;
  date: string;
  description: string;
  hospital: string;
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
