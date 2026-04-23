// // 喂食器硬件服务
// // 控制智能喂食器的硬件功能：舵机控制、称重传感器、状态监控
//
// import { HardwareControllerFactory } from '../hardware/HardwareAbstraction';
// import { RdbHelper } from './RdbHelper';
// import { hilog } from '@kit.PerformanceAnalysisKit';
// import { DeviceType } from '../models/DataModels';
// import type { HardwareCommand, FeederHardwareStatus } from '../models/DataModels';
// import type { FeederHardwareServiceStatus, FeederConfig } from '../models/HardwareServiceModels';
//
// const TAG: string = 'FeederHardwareService';
// const DOMAIN: number = 0x0000;
//
// // 喂食器硬件配置
// const FEEDER_CONFIG: FeederConfig = {
//   gpioPins: {
//     statusLed: 10,
//     errorLed: 11,
//   },
//   pwmPins: {
//     servo: 9,
//   },
//   adcPins: {
//     weightSensor: 0,
//     temperature: 1,
//   },
//   servoConfig: {
//     minDutyCycle: 2.5,
//     maxDutyCycle: 12.5,
//     feedDuration: 1000,
//     resetDelay: 500,
//   },
//   weightSensorConfig: {
//     calibrationFactor: 0.1,
//     emptyValue: 100,
//     fullValue: 3000,
//     stableReadings: 3,
//   },
// };
//
// class FeederHardwareServiceClass {
//   private isInitialized: boolean = false;
//   private currentDeviceId: string = '';
//   private hardwareController: any = null;
//   private isFeeding: boolean = false;
//   private feedTimeout: number = 0;
//   private lastFeedTime: string = '';
//   private feedCountToday: number = 0;
//   private weightReadings: number[] = [];
//   private currentFoodRemaining: number = 0;
//   private currentWaterRemaining: number = 0;
//
//   // 初始化喂食器硬件服务
//   async initialize(deviceId: string = ''): Promise<void> {
//     if (this.isInitialized) {
//       hilog.warn(DOMAIN, TAG, 'Feeder hardware service already initialized');
//       return;
//     }
//
//     this.currentDeviceId = deviceId;
//
//     try {
//       // 获取硬件控制器
//       this.hardwareController = await HardwareControllerFactory.getController();
//
//       // 初始化硬件
//       await this.initializeHardware();
//
//       // 校准称重传感器
//       await this.calibrateWeightSensor();
//
//       // 读取初始状态
//       await this.updateStatus();
//
//       this.isInitialized = true;
//       hilog.info(DOMAIN, TAG, `Feeder hardware service initialized for device: ${deviceId || 'simulated'}`);
//     } catch (err) {
//       const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
//       hilog.error(DOMAIN, TAG, `Failed to initialize feeder hardware service: ${errorMessage}`);
//       throw new Error(`喂食器硬件服务初始化失败: ${errorMessage}`);
//     }
//   }
//
//   // 初始化硬件
//   private async initializeHardware(): Promise<void> {
//     try {
//       // 初始化GPIO引脚
//       await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.statusLed, false);
//       await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.errorLed, false);
//
//       // 初始化舵机到初始位置
//       await this.hardwareController.setPwm(FEEDER_CONFIG.pwmPins.servo, FEEDER_CONFIG.servoConfig.minDutyCycle);
//
//       hilog.debug(DOMAIN, TAG, 'Hardware initialized');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to initialize hardware: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 校准称重传感器
//   private async calibrateWeightSensor(): Promise<void> {
//     try {
//       hilog.info(DOMAIN, TAG, 'Calibrating weight sensor...');
//
//       // 读取多次取平均值
//       const readings: number[] = [];
//       for (let i = 0; i < 10; i++) {
//         const reading = await this.hardwareController.readAdc(FEEDER_CONFIG.adcPins.weightSensor);
//         readings.push(reading);
//         await new Promise(resolve => setTimeout(resolve, 100));
//       }
//
//       const average = readings.reduce((sum, val) => sum + val, 0) / readings.length;
//       this.weightReadings = [average];
//
//       hilog.info(DOMAIN, TAG, `Weight sensor calibrated. Average reading: ${average.toFixed(1)}`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to calibrate weight sensor: ${JSON.stringify(err)}`);
//       // 使用默认值继续
//       this.weightReadings = [FEEDER_CONFIG.weightSensorConfig.emptyValue];
//     }
//   }
//
//   // 执行投喂动作
//   async feed(amount: number = 30): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     if (this.isFeeding) {
//       hilog.warn(DOMAIN, TAG, 'Feeding already in progress');
//       return;
//     }
//
//     try {
//       this.isFeeding = true;
//
//       // 打开状态LED
//       await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.statusLed, true);
//
//       // 计算舵机占空比（基于投喂量）
//       const dutyCycle = this.calculateServoDutyCycle(amount);
//
//       // 执行投喂动作
//       await this.hardwareController.setPwm(FEEDER_CONFIG.pwmPins.servo, dutyCycle);
//
//       hilog.info(DOMAIN, TAG, `Feeding ${amount}g, servo duty cycle: ${dutyCycle.toFixed(2)}%`);
//
//       // 记录投喂命令
//       await this.logFeedingCommand(amount);
//
//       // 设置定时复位
//       this.feedTimeout = setTimeout(async () => {
//         try {
//           // 复位舵机
//           await this.hardwareController.setPwm(FEEDER_CONFIG.pwmPins.servo, FEEDER_CONFIG.servoConfig.minDutyCycle);
//
//           // 关闭状态LED
//           await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.statusLed, false);
//
//           // 更新状态
//           this.lastFeedTime = new Date().toISOString();
//           this.feedCountToday++;
//           await this.updateFoodRemaining(amount);
//
//           this.isFeeding = false;
//           hilog.info(DOMAIN, TAG, 'Feeding completed');
//         } catch (err) {
//           hilog.error(DOMAIN, TAG, `Failed to complete feeding: ${JSON.stringify(err)}`);
//           this.isFeeding = false;
//         }
//       }, FEEDER_CONFIG.servoConfig.feedDuration) as unknown as number;
//
//     } catch (err) {
//       this.isFeeding = false;
//       const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
//       hilog.error(DOMAIN, TAG, `Failed to execute feeding: ${errorMessage}`);
//       throw new Error(`投喂失败: ${errorMessage}`);
//     }
//   }
//
//   // 计算舵机占空比
//   private calculateServoDutyCycle(amount: number): number {
//     // 简化计算：投喂量与舵机角度成正比
//     const maxAmount = 100; // 最大投喂量
//     const clampedAmount = Math.min(amount, maxAmount);
//
//     const range = FEEDER_CONFIG.servoConfig.maxDutyCycle - FEEDER_CONFIG.servoConfig.minDutyCycle;
//     const dutyCycle = FEEDER_CONFIG.servoConfig.minDutyCycle + (clampedAmount / maxAmount) * range;
//
//     return Math.max(FEEDER_CONFIG.servoConfig.minDutyCycle,
//                    Math.min(FEEDER_CONFIG.servoConfig.maxDutyCycle, dutyCycle));
//   }
//
//   // 停止投喂
//   async stopFeeding(): Promise<void> {
//     if (!this.isFeeding) {
//       return;
//     }
//
//     try {
//       // 清除定时器
//       if (this.feedTimeout) {
//         clearTimeout(this.feedTimeout);
//         this.feedTimeout = 0;
//       }
//
//       // 复位舵机
//       await this.hardwareController.setPwm(FEEDER_CONFIG.pwmPins.servo, FEEDER_CONFIG.servoConfig.minDutyCycle);
//
//       // 关闭状态LED
//       await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.statusLed, false);
//
//       this.isFeeding = false;
//       hilog.info(DOMAIN, TAG, 'Feeding stopped manually');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to stop feeding: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 读取称重传感器
//   async readWeightSensor(): Promise<number> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       const rawValue = await this.hardwareController.readAdc(FEEDER_CONFIG.adcPins.weightSensor);
//
//       // 添加到读数缓冲区
//       this.weightReadings.push(rawValue);
//       if (this.weightReadings.length > FEEDER_CONFIG.weightSensorConfig.stableReadings) {
//         this.weightReadings.shift();
//       }
//
//       // 计算平均值
//       const average = this.weightReadings.reduce((sum, val) => sum + val, 0) / this.weightReadings.length;
//
//       // 转换为克数
//       const weight = this.convertAdcToGrams(average);
//
//       hilog.debug(DOMAIN, TAG, `Weight sensor: raw=${rawValue.toFixed(1)}, avg=${average.toFixed(1)}, weight=${weight.toFixed(1)}g`);
//       return weight;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to read weight sensor: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // ADC值转换为克数
//   private convertAdcToGrams(adcValue: number): number {
//     const { emptyValue, fullValue, calibrationFactor } = FEEDER_CONFIG.weightSensorConfig;
//
//     if (adcValue <= emptyValue) {
//       return 0;
//     }
//
//     const weight = (adcValue - emptyValue) * calibrationFactor;
//     return Math.max(0, weight);
//   }
//
//   // 读取温度传感器
//   async readTemperature(): Promise<number> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       const adcValue = await this.hardwareController.readAdc(FEEDER_CONFIG.adcPins.temperature);
//
//       // 简化转换：假设10mV/°C，参考电压3.3V
//       const voltage = (adcValue / 4095) * 3.3;
//       const temperature = voltage * 100; // 10mV/°C
//
//       hilog.debug(DOMAIN, TAG, `Temperature: ${temperature.toFixed(1)}°C (ADC: ${adcValue})`);
//       return temperature;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to read temperature: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 更新食物剩余量
//   private async updateFoodRemaining(fedAmount: number): Promise<void> {
//     try {
//       const currentWeight = await this.readWeightSensor();
//       this.currentFoodRemaining = Math.max(0, currentWeight - fedAmount);
//
//       hilog.debug(DOMAIN, TAG, `Food remaining updated: ${this.currentFoodRemaining.toFixed(1)}g`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to update food remaining: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 更新状态
//   async updateStatus(): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       // 读取当前重量
//       const currentWeight = await this.readWeightSensor();
//       this.currentFoodRemaining = currentWeight;
//
//       // 读取温度
//       const temperature = await this.readTemperature();
//
//       // 记录状态到数据库
//       await this.logFeederStatus(currentWeight, temperature);
//
//       hilog.debug(DOMAIN, TAG, 'Feeder status updated');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to update feeder status: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 获取喂食器状态
//   async getFeederStatus(): Promise<FeederHardwareStatus> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       const currentWeight = await this.readWeightSensor();
//       const temperature = await this.readTemperature();
//       const hardwareStatus = await this.hardwareController.getStatus();
//
//       const status: FeederHardwareStatus = {
//         deviceId: this.currentDeviceId,
//         deviceType: DeviceType.FEEDER,
//         battery: 100, // 简化实现
//         signalStrength: 100,
//         lastSeen: new Date().toISOString(),
//         hardwareVersion: '1.0',
//         foodRemaining: currentWeight,
//         foodCapacity: 200, // 假设容量200g
//         waterRemaining: this.currentWaterRemaining,
//         waterCapacity: 500, // 假设容量500ml
//         servoPosition: await this.getServoPosition(),
//         weightSensorValue: currentWeight,
//         lastFeedTime: this.lastFeedTime,
//         feedCountToday: this.feedCountToday,
//         temperature: temperature,
//       };
//
//       return status;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to get feeder status: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 获取舵机位置
//   private async getServoPosition(): Promise<number> {
//     try {
//       // 简化实现，返回估计位置
//       return this.isFeeding ? 90 : 0; // 90度表示正在投喂
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to get servo position: ${JSON.stringify(err)}`);
//       return 0;
//     }
//   }
//
//   // 发送硬件命令
//   async sendCommand(command: HardwareCommand): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       await this.hardwareController.sendCommand(command);
//       await this.logHardwareCommand(command);
//       hilog.info(DOMAIN, TAG, `Hardware command sent: ${command.type}`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to send hardware command: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 记录投喂命令
//   private async logFeedingCommand(amount: number): Promise<void> {
//     try {
//       const userId = await this.getCurrentUserId();
//       if (userId === -1) {
//         return;
//       }
//
//       const timestamp = new Date().toISOString();
//
//       const values = {
//         device_id: this.currentDeviceId,
//         device_type: DeviceType.FEEDER,
//         metric_type: 'feeding',
//         value: amount,
//         unit: 'g',
//         timestamp: timestamp,
//         created_at: timestamp,
//       };
//
//       await RdbHelper.insert('hardware_telemetry', values);
//       hilog.debug(DOMAIN, TAG, `Feeding command logged: ${amount}g`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to log feeding command: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 记录喂食器状态
//   private async logFeederStatus(weight: number, temperature: number): Promise<void> {
//     try {
//       const userId = await this.getCurrentUserId();
//       if (userId === -1) {
//         return;
//       }
//
//       const timestamp = new Date().toISOString();
//
//       // 记录重量
//       const weightValues = {
//         device_id: this.currentDeviceId,
//         device_type: DeviceType.FEEDER,
//         metric_type: 'food_weight',
//         value: weight,
//         unit: 'g',
//         timestamp: timestamp,
//         created_at: timestamp,
//       };
//
//       await RdbHelper.insert('hardware_telemetry', weightValues);
//
//       // 记录温度
//       const tempValues = {
//         device_id: this.currentDeviceId,
//         device_type: DeviceType.FEEDER,
//         metric_type: 'temperature',
//         value: temperature,
//         unit: '°C',
//         timestamp: timestamp,
//         created_at: timestamp,
//       };
//
//       await RdbHelper.insert('hardware_telemetry', tempValues);
//
//       hilog.debug(DOMAIN, TAG, 'Feeder status logged to database');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to log feeder status: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 记录硬件命令
//   private async logHardwareCommand(command: any): Promise<void> {
//     try {
//       const userId = await this.getCurrentUserId();
//       if (userId === -1) {
//         return;
//       }
//
//       const values = {
//         device_id: command.deviceId || this.currentDeviceId,
//         device_type: DeviceType.FEEDER,
//         metric_type: `command_${command.type}`,
//         value: 1,
//         unit: 'count',
//         timestamp: command.timestamp || new Date().toISOString(),
//         created_at: new Date().toISOString(),
//       };
//
//       await RdbHelper.insert('hardware_telemetry', values);
//       hilog.debug(DOMAIN, TAG, `Hardware command logged: ${command.type}`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to log hardware command: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 获取当前用户ID（简化实现）
//   private async getCurrentUserId(): Promise<number> {
//     // 这里应该从用户服务获取当前用户ID
//     // 简化实现，返回1
//     return 1;
//   }
//
//   // 获取服务状态
//   getServiceStatus(): FeederHardwareServiceStatus {
//     return {
//       isInitialized: this.isInitialized,
//       currentDeviceId: this.currentDeviceId,
//       isFeeding: this.isFeeding,
//       feedCountToday: this.feedCountToday,
//       lastFeedTime: this.lastFeedTime,
//       currentFoodRemaining: this.currentFoodRemaining,
//       controllerType: HardwareControllerFactory.getControllerType(),
//     };
//   }
//
//   // 重置今日计数
//   resetDailyCount(): void {
//     this.feedCountToday = 0;
//     hilog.info(DOMAIN, TAG, 'Daily feed count reset');
//   }
//
//   // 释放资源
//   async release(): Promise<void> {
//     try {
//       // 停止所有活动
//       await this.stopFeeding();
//
//       // 关闭所有GPIO
//       if (this.hardwareController) {
//         await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.statusLed, false);
//         await this.hardwareController.setGpio(FEEDER_CONFIG.gpioPins.errorLed, false);
//         await this.hardwareController.setPwm(FEEDER_CONFIG.pwmPins.servo, FEEDER_CONFIG.servoConfig.minDutyCycle);
//       }
//
//       this.isInitialized = false;
//       this.currentDeviceId = '';
//       this.hardwareController = null;
//       this.weightReadings = [];
//
//       hilog.info(DOMAIN, TAG, 'Feeder hardware service released');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Error releasing feeder hardware service: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
// }
//
// // 单例导出
// export const FeederHardwareService = new FeederHardwareServiceClass();