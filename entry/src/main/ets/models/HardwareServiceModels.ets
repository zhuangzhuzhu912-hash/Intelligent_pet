// 硬件服务相关接口
// 用于 CollarHardwareService 和 FeederHardwareService 的类型定义

import { DeviceType } from './DataModels';

// 项圈GPIO引脚配置
export interface CollarGpioPins {
  buzzer: number;
  led: number;
  statusLed: number;
}

// 项圈PWM引脚配置
export interface CollarPwmPins {
  // 项圈可能不需要PWM
}

// 项圈ADC引脚配置
export interface CollarAdcPins {
  battery: number;
}

// 项圈硬件配置
export interface CollarConfig {
  gpioPins: CollarGpioPins;
  pwmPins: CollarPwmPins;
  adcPins: CollarAdcPins;
  findPetDuration: number;
  blinkInterval: number;
}

// 项圈硬件服务状态
export interface CollarHardwareServiceStatus {
  isInitialized: boolean;
  currentDeviceId: string;
  isFindingPet: boolean;
  isBlinking: boolean;
  controllerType: string;
}

// 喂食器GPIO引脚配置
export interface FeederGpioPins {
  statusLed: number;
  errorLed: number;
}

// 喂食器PWM引脚配置
export interface FeederPwmPins {
  servo: number;
}

// 喂食器ADC引脚配置
export interface FeederAdcPins {
  weightSensor: number;
  temperature: number;
}

// 喂食器舵机配置
export interface FeederServoConfig {
  minDutyCycle: number;
  maxDutyCycle: number;
  feedDuration: number;
  resetDelay: number;
}

// 喂食器称重传感器配置
export interface FeederWeightSensorConfig {
  calibrationFactor: number;
  emptyValue: number;
  fullValue: number;
  stableReadings: number;
}

// 喂食器硬件配置
export interface FeederConfig {
  gpioPins: FeederGpioPins;
  pwmPins: FeederPwmPins;
  adcPins: FeederAdcPins;
  servoConfig: FeederServoConfig;
  weightSensorConfig: FeederWeightSensorConfig;
}

// 喂食器硬件服务状态
export interface FeederHardwareServiceStatus {
  isInitialized: boolean;
  currentDeviceId: string;
  isFeeding: boolean;
  feedCountToday: number;
  lastFeedTime: string;
  currentFoodRemaining: number;
  controllerType: string;
}
