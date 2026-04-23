// // 项圈硬件服务
// // 控制智能项圈的硬件功能：一键寻宠、LED、蜂鸣器、状态监控
//
// import { HardwareControllerFactory } from '../hardware/HardwareAbstraction';
// import { RdbHelper } from './RdbHelper';
// import { hilog } from '@kit.PerformanceAnalysisKit';
// import { DeviceType } from '../models/DataModels';
// import type { HardwareCommand, CollarHardwareStatus } from '../models/DataModels';
// import type { CollarHardwareServiceStatus, CollarConfig } from '../models/HardwareServiceModels';
//
// const TAG: string = 'CollarHardwareService';
// const DOMAIN: number = 0x0000;
//
// // 项圈硬件配置
// const COLLAR_CONFIG: CollarConfig = {
//   gpioPins: {
//     buzzer: 7,
//     led: 8,
//     statusLed: 10,
//   },
//   pwmPins: {
//   },
//   adcPins: {
//     battery: 0,
//   },
//   findPetDuration: 3000,
//   blinkInterval: 500,
// };
//
// class CollarHardwareServiceClass {
//   private isInitialized: boolean = false;
//   private currentDeviceId: string = '';
//   // private hardwareController: any = null;
//   private findPetTimeout: number = 0;
//   private blinkInterval: number = 0;
//   private isFindingPet: boolean = false;
//   private isBlinking: boolean = false;
//
//   // 初始化项圈硬件服务
//   async initialize(deviceId: string = ''): Promise<void> {
//     if (this.isInitialized) {
//       hilog.warn(DOMAIN, TAG, 'Collar hardware service already initialized');
//       return;
//     }
//
//     this.currentDeviceId = deviceId;
//
//     try {
//       // 获取硬件控制器
//       this.hardwareController = await HardwareControllerFactory.getController();
//
//       // 初始化GPIO引脚
//       await this.initializeGpioPins();
//
//       // 设置初始状态
//       await this.setInitialState();
//
//       this.isInitialized = true;
//       hilog.info(DOMAIN, TAG, `Collar hardware service initialized for device: ${deviceId || 'simulated'}`);
//     } catch (err) {
//       const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
//       hilog.error(DOMAIN, TAG, `Failed to initialize collar hardware service: ${errorMessage}`);
//       throw new Error(`项圈硬件服务初始化失败: ${errorMessage}`);
//     }
//   }
//
//   // 初始化GPIO引脚
//   private async initializeGpioPins(): Promise<void> {
//     try {
//       // 确保所有GPIO引脚处于关闭状态
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.buzzer, false);
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.led, false);
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.statusLed, false);
//
//       hilog.debug(DOMAIN, TAG, 'GPIO pins initialized');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to initialize GPIO pins: ${JSON.stringify(err)}`);
//       throw new Error(`项圈硬件服务初始化失败: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 设置初始状态
//   private async setInitialState(): Promise<void> {
//     try {
//       // 状态LED慢闪表示就绪
//       await this.startStatusBlink();
//       hilog.debug(DOMAIN, TAG, 'Initial state set');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to set initial state: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 一键寻宠功能
//   async findPet(duration: number = COLLAR_CONFIG.findPetDuration): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     if (this.isFindingPet) {
//       hilog.warn(DOMAIN, TAG, 'Find pet already in progress');
//       return;
//     }
//
//     try {
//       this.isFindingPet = true;
//
//       // 打开蜂鸣器和LED
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.buzzer, true);
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.led, true);
//
//       // 停止状态闪烁
//       await this.stopStatusBlink();
//
//       hilog.info(DOMAIN, TAG, `Find pet activated for ${duration}ms`);
//
//       // 记录硬件命令
//       await this.logHardwareCommand({
//         type: 'find_pet',
//         deviceId: this.currentDeviceId,
//         timestamp: new Date().toISOString(),
//         payload: ({ duration })as number
//       });
//
//       // 设置定时关闭
//       this.findPetTimeout = setTimeout(async () => {
//         try {
//           await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.buzzer, false);
//           await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.led, false);
//
//           // 恢复状态闪烁
//           await this.startStatusBlink();
//
//           this.isFindingPet = false;
//           hilog.info(DOMAIN, TAG, 'Find pet deactivated');
//         } catch (err) {
//           hilog.error(DOMAIN, TAG, `Failed to deactivate find pet: ${JSON.stringify(err)}`);
//           this.isFindingPet = false;
//         }
//       }, duration)  as number;
//
//     } catch (err) {
//       this.isFindingPet = false;
//       const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
//       hilog.error(DOMAIN, TAG, `Failed to activate find pet: ${errorMessage}`);
//       throw new Error(`一键寻宠失败: ${errorMessage}`);
//     }
//   }
//
//   // 停止寻宠
//   async stopFindPet(): Promise<void> {
//     if (!this.isFindingPet) {
//       return;
//     }
//
//     try {
//       // 清除定时器
//       if (this.findPetTimeout) {
//         clearTimeout(this.findPetTimeout);
//         this.findPetTimeout = 0;
//       }
//
//       // 关闭蜂鸣器和LED
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.buzzer, false);
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.led, false);
//
//       // 恢复状态闪烁
//       await this.startStatusBlink();
//
//       this.isFindingPet = false;
//       hilog.info(DOMAIN, TAG, 'Find pet stopped manually');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to stop find pet: ${JSON.stringify(err)}`);
//       throw new Error(`停止寻宠失败: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 开始状态LED闪烁
//   async startStatusBlink(): Promise<void> {
//     if (this.isBlinking) {
//       return;
//     }
//
//     this.isBlinking = true;
//     let ledState = false;
//
//     this.blinkInterval = setInterval(async () => {
//       try {
//         ledState = !ledState;
//         await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.statusLed, ledState);
//       } catch (err) {
//         hilog.error(DOMAIN, TAG, `Failed to toggle status LED: ${JSON.stringify(err)}`);
//       }
//     }, COLLAR_CONFIG.blinkInterval)  as number;
//
//     hilog.debug(DOMAIN, TAG, 'Status blink started');
//   }
//
//   // 停止状态LED闪烁
//   async stopStatusBlink(): Promise<void> {
//     if (!this.isBlinking) {
//       return;
//     }
//
//     if (this.blinkInterval) {
//       clearInterval(this.blinkInterval);
//       this.blinkInterval = 0;
//     }
//
//     try {
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.statusLed, false);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to turn off status LED: ${JSON.stringify(err)}`);
//     }
//
//     this.isBlinking = false;
//     hilog.debug(DOMAIN, TAG, 'Status blink stopped');
//   }
//
//   // 设置LED状态
//   async setLedState(on: boolean): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.led, on);
//       hilog.debug(DOMAIN, TAG, `LED set to ${on ? 'ON' : 'OFF'}`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to set LED state: ${JSON.stringify(err)}`);
//       throw new Error(`设置LED状态失败: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 设置蜂鸣器状态
//   async setBuzzerState(on: boolean): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.buzzer, on);
//       hilog.debug(DOMAIN, TAG, `Buzzer set to ${on ? 'ON' : 'OFF'}`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to set buzzer state: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 读取电池电压
//   async readBatteryVoltage(): Promise<number> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       const adcValue = await this.hardwareController.readAdc(COLLAR_CONFIG.adcPins.battery);
//
//       // 假设ADC参考电压3.3V，12位分辨率
//       const voltage = (adcValue / 4095) * 3.3;
//
//       hilog.debug(DOMAIN, TAG, `Battery voltage: ${voltage.toFixed(2)}V (ADC: ${adcValue})`);
//       return voltage;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to read battery voltage: ${JSON.stringify(err)}`);
//       throw new Error(`读取电池电压失败: ${JSON.stringify(err)}`);
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
//   // 获取项圈状态
//   async getCollarStatus(): Promise<CollarHardwareStatus> {
//     if (!this.isInitialized) {
//       throw new Error('Service not initialized');
//     }
//
//     try {
//       const batteryVoltage = await this.readBatteryVoltage();
//       const batteryPercentage = this.calculateBatteryPercentage(batteryVoltage);
//
//       const hardwareStatus = await this.hardwareController.getStatus();
//
//       const status: CollarHardwareStatus = {
//         deviceId: this.currentDeviceId,
//         deviceType: DeviceType.COLLAR,
//         battery: batteryPercentage,
//         signalStrength: 100, // 简化实现
//         lastSeen: new Date().toISOString(),
//         hardwareVersion: '1.0',
//         steps: 0, // 需要从传感器服务获取
//         distance: 0,
//         calories: 0,
//         isMoving: false,
//         temperature: 25, // 简化实现
//       };
//
//       // 记录状态到数据库
//       await this.logHardwareStatus(status);
//
//       return status;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to get collar status: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
//
//   // 计算电池百分比
//   private calculateBatteryPercentage(voltage: number): number {
//     // 假设锂电池：4.2V满电，3.3V空电
//     const fullVoltage = 4.2;
//     const emptyVoltage = 3.3;
//
//     if (voltage >= fullVoltage) return 100;
//     if (voltage <= emptyVoltage) return 0;
//
//     const percentage = ((voltage - emptyVoltage) / (fullVoltage - emptyVoltage)) * 100;
//     return Math.round(Math.max(0, Math.min(100, percentage)));
//   }
//
//   // 记录硬件命令到数据库
//   private async logHardwareCommand(command: any): Promise<void> {
//     try {
//       const userId = await this.getCurrentUserId();
//       if (userId === -1) {
//         return;
//       }
//
//       const values = {
//         device_id: command.deviceId || this.currentDeviceId,
//         device_type: DeviceType.COLLAR,
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
//   // 记录硬件状态到数据库
//   private async logHardwareStatus(status: CollarHardwareStatus): Promise<void> {
//     try {
//       const userId = await this.getCurrentUserId();
//       if (userId === -1) {
//         return;
//       }
//
//       const timestamp = new Date().toISOString();
//
//       // 记录电池状态
//       const batteryValues = {
//         device_id: status.deviceId,
//         device_type: DeviceType.COLLAR,
//         metric_type: 'battery',
//         value: status.battery,
//         unit: '%',
//         timestamp: timestamp,
//         created_at: timestamp,
//       };
//
//       await RdbHelper.insert('hardware_telemetry', batteryValues);
//
//       // 记录信号强度
//       const signalValues = {
//         device_id: status.deviceId,
//         device_type: DeviceType.COLLAR,
//         metric_type: 'signal_strength',
//         value: status.signalStrength,
//         unit: '%',
//         timestamp: timestamp,
//         created_at: timestamp,
//       };
//
//       await RdbHelper.insert('hardware_telemetry', signalValues);
//
//       hilog.debug(DOMAIN, TAG, 'Hardware status logged to database');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to log hardware status: ${JSON.stringify(err)}`);
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
//   getServiceStatus(): CollarHardwareServiceStatus {
//     return {
//       isInitialized: this.isInitialized,
//       currentDeviceId: this.currentDeviceId,
//       isFindingPet: this.isFindingPet,
//       isBlinking: this.isBlinking,
//       controllerType: HardwareControllerFactory.getControllerType(),
//     };
//   }
//
//   // 语音对讲功能（待实现）
//   async startAudioTalk(deviceId: string): Promise<void> {
//     hilog.info(DOMAIN, TAG, `Audio talk requested for device ${deviceId} (not implemented)`);
//     // TODO: 实现语音对讲功能
//     throw new Error('语音对讲功能暂未实现');
//   }
//
//   // 释放资源
//   async release(): Promise<void> {
//     try {
//       // 停止所有活动
//       await this.stopFindPet();
//       await this.stopStatusBlink();
//
//       // 关闭所有GPIO
//       if (this.hardwareController) {
//         await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.buzzer, false);
//         await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.led, false);
//         await this.hardwareController.setGpio(COLLAR_CONFIG.gpioPins.statusLed, false);
//       }
//
//       this.isInitialized = false;
//       this.currentDeviceId = '';
//       this.hardwareController = null;
//
//       hilog.info(DOMAIN, TAG, 'Collar hardware service released');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Error releasing collar hardware service: ${JSON.stringify(err)}`);
//       throw err;
//     }
//   }
// }
//
// // 单例导出
// export const CollarHardwareService = new CollarHardwareServiceClass();