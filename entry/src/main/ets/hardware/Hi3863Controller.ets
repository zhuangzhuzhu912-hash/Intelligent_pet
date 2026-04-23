// // Hi3863硬件控制器
// // 专为Hi3863开发板设计的硬件驱动，控制GPIO、PWM、ADC等外设
//
// import { hilog } from '@kit.PerformanceAnalysisKit';
// import type { HardwareCommand } from '../models/DataModels';
// import { HardwareCommandType } from '../models/DataModels';
//
// const TAG: string = 'Hi3863Controller';
// const DOMAIN: number = 0x0000;
//
// // DriverKit相关接口定义（用于类型检查）
// export interface GpioPin {
//   setDirection(direction: 'in' | 'out'): Promise<void>;
//   setPull(pull: 'none' | 'pullup' | 'pulldown'): Promise<void>;
//   write(value: number): Promise<void>;
//   read(): Promise<number>;
//   close(): Promise<void>;
// }
//
// // 模拟GPIO引脚实现类
// class SimulatedGpioPin implements GpioPin {
//   private pin: number;
//   private value: number = 0;
//
//   constructor(pin: number) {
//     this.pin = pin;
//   }
//
//   async setDirection(direction: 'in' | 'out'): Promise<void> {
//     hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${this.pin} direction set to ${direction}`);
//   }
//
//   async setPull(pull: 'none' | 'pullup' | 'pulldown'): Promise<void> {
//     hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${this.pin} pull set to ${pull}`);
//   }
//
//   async write(value: number): Promise<void> {
//     this.value = value;
//     hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${this.pin} written: ${this.value}`);
//     await new Promise<void>(resolve => setTimeout(resolve, 10));
//   }
//
//   async read(): Promise<number> {
//     hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${this.pin} read: ${this.value}`);
//     await new Promise<void>(resolve => setTimeout(resolve, 5));
//     return this.value;
//   }
//
//   async close(): Promise<void> {
//     hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${this.pin} closed`);
//   }
// }
//
// export interface PwmPin {
//   setFrequency(frequency: number): Promise<void>;
//   setDutyCycle(dutyCycle: number): Promise<void>;
//   close(): Promise<void>;
// }
//
// // 模拟PWM引脚实现类
// class SimulatedPwmPin implements PwmPin {
//   private pin: number;
//   private dutyCycle: number = 0;
//
//   constructor(pin: number) {
//     this.pin = pin;
//   }
//
//   async setFrequency(frequency: number): Promise<void> {
//     hilog.debug(DOMAIN, TAG, `Simulated PWM pin ${this.pin} frequency set to ${frequency}Hz`);
//   }
//
//   async setDutyCycle(dc: number): Promise<void> {
//     this.dutyCycle = Math.max(0, Math.min(100, dc));
//     hilog.debug(DOMAIN, TAG, `Simulated PWM pin ${this.pin} duty cycle set to ${this.dutyCycle}%`);
//     await new Promise<void>(resolve => setTimeout(resolve, 10));
//   }
//
//   async close(): Promise<void> {
//     hilog.debug(DOMAIN, TAG, `Simulated PWM pin ${this.pin} closed`);
//   }
// }
//
// export interface AdcPin {
//   read(): Promise<number>;
//   close(): Promise<void>;
// }
//
// // 模拟ADC引脚实现类
// class SimulatedAdcPin implements AdcPin {
//   private pin: number;
//
//   constructor(pin: number) {
//     this.pin = pin;
//   }
//
//   async read(): Promise<number> {
//     // 模拟ADC读数（0-4095）
//     const value = Math.floor(Math.random() * 4096);
//     hilog.debug(DOMAIN, TAG, `Simulated ADC pin ${this.pin} read: ${value}`);
//     await new Promise<void>(resolve => setTimeout(resolve, 15));
//     return value;
//   }
//
//   async close(): Promise<void> {
//     hilog.debug(DOMAIN, TAG, `Simulated ADC pin ${this.pin} closed`);
//   }
// }
//
// // DriverKit接口
// export interface DriverKitType {
//   createGpioPin(pin: number): Promise<GpioPin>;
//   createPwmPin(pin: number): Promise<PwmPin>;
//   createAdcPin(pin: number): Promise<AdcPin>;
// }
//
// // 模拟DriverKit实现类
// class SimulatedDriverKit implements DriverKitType {
//   async createGpioPin(pin: number): Promise<GpioPin> {
//     return new SimulatedGpioPin(pin);
//   }
//
//   async createPwmPin(pin: number): Promise<PwmPin> {
//     return new SimulatedPwmPin(pin);
//   }
//
//   async createAdcPin(pin: number): Promise<AdcPin> {
//     return new SimulatedAdcPin(pin);
//   }
// }
//
// // 智能项圈引脚配置
// export interface CollarPinConfig {
//   buzzer: number;      // 蜂鸣器控制
//   led: number;         // LED指示灯
//   statusLed: number;   // 状态LED
//   batteryAdc: number;  // 电池电压检测
// }
//
// // 智能喂食器引脚配置
// export interface FeederPinConfig {
//   servoPwm: number;    // 舵机PWM控制
//   weightAdc: number;   // 称重传感器ADC
//   feederLed: number;   // 喂食器状态LED
// }
//
// // Hi3863引脚配置
// export interface Hi3863PinConfig {
//   collar: CollarPinConfig;
//   feeder: FeederPinConfig;
// }
//
// // 硬件状态信息接口
// export interface HardwareStatus {
//   timestamp: string;
//   isInitialized: boolean;
//   gpio: Record<string, boolean | string>;
//   pwm: Record<string, number | string>;
//   adc: Record<string, number | string>;
// }
//
// // 默认引脚配置（根据硬件设计）
// export const DEFAULT_PIN_CONFIG: Hi3863PinConfig = {
//   collar: {
//     buzzer: 7,      // GPIO7 - 蜂鸣器
//     led: 8,         // GPIO8 - LED指示灯
//     statusLed: 10,  // GPIO10 - 状态LED
//     batteryAdc: 0,  // ADC0 - 电池电压
//   },
//   feeder: {
//     servoPwm: 9,    // PWM9 - 舵机控制
//     weightAdc: 1,   // ADC1 - 称重传感器
//     feederLed: 11,  // GPIO11 - 喂食器LED
//   },
// };
//
// // Hi3863硬件控制器类
// export class Hi3863Controller {
//   private gpioPins: Map<number, GpioPin> = new Map();
//   private pwmPins: Map<number, PwmPin> = new Map();
//   private adcPins: Map<number, AdcPin> = new Map();
//   private isInitialized: boolean = false;
//   private pinConfig: Hi3863PinConfig;
//   private DriverKit: DriverKitType | null = null;
//
//   constructor(pinConfig: Hi3863PinConfig = DEFAULT_PIN_CONFIG) {
//     this.pinConfig = pinConfig;
//   }
//
//   // 初始化Hi3863硬件
//   async initialize(): Promise<void> {
//     if (this.isInitialized) {
//       hilog.warn(DOMAIN, TAG, 'Hi3863 controller already initialized');
//       return;
//     }
//
//     try {
//       hilog.info(DOMAIN, TAG, 'Initializing Hi3863 hardware controller');
//
//       // 使用模拟DriverKit（DriverKit在应用层不可用，需要在驱动层使用）
//       hilog.info(DOMAIN, TAG, 'Using simulated DriverKit for application layer');
//       this.DriverKit = this.createSimulatedDriverKit();
//
//       // 初始化项圈GPIO引脚
//       await this.initializeGpioPin(this.pinConfig.collar.buzzer, 'out', 'none');
//       await this.initializeGpioPin(this.pinConfig.collar.led, 'out', 'none');
//       await this.initializeGpioPin(this.pinConfig.collar.statusLed, 'out', 'none');
//
//       // 初始化喂食器GPIO引脚
//       await this.initializeGpioPin(this.pinConfig.feeder.feederLed, 'out', 'none');
//
//       // 初始化PWM引脚（舵机）
//       await this.initializePwmPin(this.pinConfig.feeder.servoPwm, 50); // 50Hz for servo
//
//       // 初始化ADC引脚
//       await this.initializeAdcPin(this.pinConfig.collar.batteryAdc);
//       await this.initializeAdcPin(this.pinConfig.feeder.weightAdc);
//
//       // 设置初始状态
//       await this.setInitialState();
//
//       this.isInitialized = true;
//       hilog.info(DOMAIN, TAG, 'Hi3863 hardware controller initialized successfully');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to initialize Hi3863 controller: ${JSON.stringify(err)}`);
//       throw new Error(`Hi3863控制器初始化失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 初始化GPIO引脚
//   private async initializeGpioPin(pin: number, direction: 'in' | 'out', pull: 'none' | 'pullup' | 'pulldown'): Promise<void> {
//     if (!this.DriverKit) {
//       throw new Error('DriverKit not available');
//     }
//
//     try {
//       const gpioPin = await this.DriverKit.createGpioPin(pin);
//       await gpioPin.setDirection(direction);
//       await gpioPin.setPull(pull);
//       this.gpioPins.set(pin, gpioPin);
//       hilog.debug(DOMAIN, TAG, `GPIO pin ${pin} initialized (${direction}, ${pull})`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to initialize GPIO pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`初始化GPIO引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 初始化PWM引脚
//   private async initializePwmPin(pin: number, frequency: number): Promise<void> {
//     if (!this.DriverKit) {
//       throw new Error('DriverKit not available');
//     }
//
//     try {
//       const pwmPin = await this.DriverKit.createPwmPin(pin);
//       await pwmPin.setFrequency(frequency);
//       await pwmPin.setDutyCycle(0);
//       this.pwmPins.set(pin, pwmPin);
//       hilog.debug(DOMAIN, TAG, `PWM pin ${pin} initialized (${frequency}Hz)`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to initialize PWM pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`初始化PWM引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 初始化ADC引脚
//   private async initializeAdcPin(pin: number): Promise<void> {
//     if (!this.DriverKit) {
//       throw new Error('DriverKit not available');
//     }
//
//     try {
//       const adcPin = await this.DriverKit.createAdcPin(pin);
//       this.adcPins.set(pin, adcPin);
//       hilog.debug(DOMAIN, TAG, `ADC pin ${pin} initialized`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to initialize ADC pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`初始化ADC引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 设置初始状态
//   private async setInitialState(): Promise<void> {
//     try {
//       // 关闭所有输出
//       for (const entry of this.gpioPins) {
//         await entry[1].write(0);
//       }
//
//       // 设置PWM为0
//       for (const entry of this.pwmPins) {
//         await entry[1].setDutyCycle(0);
//       }
//
//       hilog.debug(DOMAIN, TAG, 'All pins set to initial state');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to set initial state: ${JSON.stringify(err)}`);
//       throw new Error(`设置初始状态失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 设置GPIO引脚状态
//   async setGpio(pin: number, value: boolean): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Controller not initialized');
//     }
//
//     const gpioPin = this.gpioPins.get(pin);
//     if (!gpioPin) {
//       throw new Error(`GPIO pin ${pin} not configured`);
//     }
//
//     try {
//       await gpioPin.write(value ? 1 : 0);
//       hilog.info(DOMAIN, TAG, `GPIO pin ${pin} set to ${value}`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to set GPIO pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`设置GPIO引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 读取GPIO引脚状态
//   async getGpio(pin: number): Promise<boolean> {
//     if (!this.isInitialized) {
//       throw new Error('Controller not initialized');
//     }
//
//     const gpioPin = this.gpioPins.get(pin);
//     if (!gpioPin) {
//       throw new Error(`GPIO pin ${pin} not configured`);
//     }
//
//     try {
//       const value = await gpioPin.read();
//       return value > 0;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to read GPIO pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`读取GPIO引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 设置PWM占空比
//   async setPwm(pin: number, dutyCycle: number): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Controller not initialized');
//     }
//
//     const pwmPin = this.pwmPins.get(pin);
//     if (!pwmPin) {
//       throw new Error(`PWM pin ${pin} not configured`);
//     }
//
//     try {
//       // 限制占空比在0-100之间
//       const clampedDutyCycle = Math.max(0, Math.min(100, dutyCycle));
//       await pwmPin.setDutyCycle(clampedDutyCycle);
//       hilog.info(DOMAIN, TAG, `PWM pin ${pin} set to ${clampedDutyCycle}%`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to set PWM pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`设置PWM引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 读取ADC值
//   async readAdc(pin: number): Promise<number> {
//     if (!this.isInitialized) {
//       throw new Error('Controller not initialized');
//     }
//
//     const adcPin = this.adcPins.get(pin);
//     if (!adcPin) {
//       throw new Error(`ADC pin ${pin} not configured`);
//     }
//
//     try {
//       const value = await adcPin.read();
//       hilog.debug(DOMAIN, TAG, `ADC pin ${pin} read: ${value}`);
//       return value;
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to read ADC pin ${pin}: ${JSON.stringify(err)}`);
//       throw new Error(`读取ADC引脚${pin}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 执行硬件命令
//   async executeCommand(command: HardwareCommand): Promise<void> {
//     if (!this.isInitialized) {
//       throw new Error('Controller not initialized');
//     }
//
//     hilog.info(DOMAIN, TAG, `Executing command: ${command.type}`);
//
//     try {
//       switch (command.type) {
//         case HardwareCommandType.FIND_PET:
//           await this.executeFindPet();
//           break;
//         case HardwareCommandType.FEED_NOW:
//           await this.executeFeedNow(command.payload?.amount || 30);
//           break;
//         case HardwareCommandType.GET_STATUS:
//           await this.executeGetStatus();
//           break;
//         case HardwareCommandType.SET_SCHEDULE:
//           await this.executeSetLed(command.payload?.pin, command.payload?.value);
//           break;
//         case HardwareCommandType.CALIBRATE:
//           await this.executeReadBattery();
//           break;
//         default:
//           hilog.warn(DOMAIN, TAG, `Unsupported command type: ${command.type}`);
//           throw new Error(`不支持的命令类型: ${command.type}`);
//       }
//
//       hilog.info(DOMAIN, TAG, `Command ${command.type} executed successfully`);
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Failed to execute command ${command.type}: ${JSON.stringify(err)}`);
//       throw new Error(`执行命令${command.type}失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 执行一键寻宠命令
//   private async executeFindPet(): Promise<void> {
//     const buzzer = this.pinConfig.collar.buzzer;
//     const led = this.pinConfig.collar.led;
//
//     // 打开蜂鸣器和LED
//     await this.setGpio(buzzer, true);
//     await this.setGpio(led, true);
//
//     hilog.info(DOMAIN, TAG, 'Find pet activated - buzzer and LED ON');
//
//     // 3秒后自动关闭
//     setTimeout(async () => {
//       try {
//         await this.setGpio(buzzer, false);
//         await this.setGpio(led, false);
//         hilog.info(DOMAIN, TAG, 'Find pet deactivated - buzzer and LED OFF');
//       } catch (err) {
//         hilog.error(DOMAIN, TAG, `Failed to deactivate find pet: ${JSON.stringify(err)}`);
//       }
//     }, 3000);
//   }
//
//   // 执行立即投喂命令
//   private async executeFeedNow(amount: number): Promise<void> {
//     const servoPwm = this.pinConfig.feeder.servoPwm;
//     const feederLed = this.pinConfig.feeder.feederLed;
//
//     // 打开喂食器LED表示工作中
//     await this.setGpio(feederLed, true);
//
//     // 计算舵机占空比（2.5% - 12.5%对应0-180度）
//     // 假设每克对应0.1%占空比变化
//     const baseDuty = 2.5;
//     const dutyIncrement = (amount / 100) * 10;
//     const targetDuty = baseDuty + dutyIncrement;
//
//     // 限制在有效范围
//     const clampedDuty = Math.max(2.5, Math.min(12.5, targetDuty));
//
//     // 控制舵机转动
//     await this.setPwm(servoPwm, clampedDuty);
//     hilog.info(DOMAIN, TAG, `Feeding ${amount}g - servo duty cycle: ${clampedDuty}%`);
//
//     // 保持位置1秒后复位
//     setTimeout(async () => {
//       try {
//         await this.setPwm(servoPwm, 2.5); // 复位到0度
//         await this.setGpio(feederLed, false); // 关闭工作LED
//         hilog.info(DOMAIN, TAG, 'Feeding completed - servo reset');
//       } catch (err) {
//         hilog.error(DOMAIN, TAG, `Failed to reset after feeding: ${JSON.stringify(err)}`);
//       }
//     }, 1000);
//   }
//
//   // 执行获取状态命令
//   private async executeGetStatus(): Promise<HardwareStatus> {
//     const status: HardwareStatus = {
//       timestamp: new Date().toISOString(),
//       isInitialized: this.isInitialized,
//       gpio: {},
//       pwm: {},
//       adc: {},
//     };
//
//     // 读取所有GPIO状态
//     for (const entry of this.gpioPins) {
//       const pin = entry[0];
//       const gpioPin = entry[1];
//       try {
//         const value = await gpioPin.read();
//         status.gpio[`pin_${pin}`] = value > 0;
//       } catch (err) {
//         status.gpio[`pin_${pin}`] = 'error';
//       }
//     }
//
//     // 读取所有ADC值
//     for (const entry of this.adcPins) {
//       const pin = entry[0];
//       const adcPin = entry[1];
//       try {
//         const value = await adcPin.read();
//         status.adc[`pin_${pin}`] = value;
//       } catch (err) {
//         status.adc[`pin_${pin}`] = 'error';
//       }
//     }
//
//     hilog.info(DOMAIN, TAG, 'Hardware status retrieved');
//     return status;
//   }
//
//   // 执行设置LED命令
//   private async executeSetLed(pin?: number, value?: boolean): Promise<void> {
//     if (pin === undefined || value === undefined) {
//       throw new Error('LED pin and value must be specified');
//     }
//
//     await this.setGpio(pin, value);
//   }
//
//   // 执行读取电池电压命令
//   private async executeReadBattery(): Promise<number> {
//     const batteryAdc = this.pinConfig.collar.batteryAdc;
//     const adcValue = await this.readAdc(batteryAdc);
//
//     // 假设ADC参考电压3.3V，12位分辨率
//     const voltage = (adcValue / 4095) * 3.3;
//     hilog.info(DOMAIN, TAG, `Battery voltage: ${voltage.toFixed(2)}V`);
//
//     return voltage;
//   }
//
//   // 获取硬件状态
//   async getStatus(): Promise<HardwareStatus> {
//     return await this.executeGetStatus();
//   }
//
//   // 释放资源
//   async release(): Promise<void> {
//     try {
//       // 关闭所有GPIO
//       for (const entry of this.gpioPins) {
//         const pin = entry[0];
//         const gpioPin = entry[1];
//         try {
//           await gpioPin.write(0);
//           await gpioPin.close();
//         } catch (err) {
//           hilog.warn(DOMAIN, TAG, `Failed to close GPIO pin ${pin}: ${JSON.stringify(err)}`);
//         }
//       }
//
//       // 关闭所有PWM
//       for (const entry of this.pwmPins) {
//         const pin = entry[0];
//         const pwmPin = entry[1];
//         try {
//           await pwmPin.setDutyCycle(0);
//           await pwmPin.close();
//         } catch (err) {
//           hilog.warn(DOMAIN, TAG, `Failed to close PWM pin ${pin}: ${JSON.stringify(err)}`);
//         }
//       }
//
//       // 关闭所有ADC
//       for (const entry of this.adcPins) {
//         const pin = entry[0];
//         const adcPin = entry[1];
//         try {
//           await adcPin.close();
//         } catch (err) {
//           hilog.warn(DOMAIN, TAG, `Failed to close ADC pin ${pin}: ${JSON.stringify(err)}`);
//         }
//       }
//
//       this.gpioPins.clear();
//       this.pwmPins.clear();
//       this.adcPins.clear();
//       this.isInitialized = false;
//
//       hilog.info(DOMAIN, TAG, 'Hi3863 hardware controller released');
//     } catch (err) {
//       hilog.error(DOMAIN, TAG, `Error releasing hardware controller: ${JSON.stringify(err)}`);
//       throw new Error(`释放硬件控制器资源失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
//     }
//   }
//
//   // 检查是否已初始化
//   isControllerInitialized(): boolean {
//     return this.isInitialized;
//   }
//
//   // 获取引脚配置
//   getPinConfig(): Hi3863PinConfig {
//     return {
//       collar: {
//         buzzer: this.pinConfig.collar.buzzer,
//         led: this.pinConfig.collar.led,
//         statusLed: this.pinConfig.collar.statusLed,
//         batteryAdc: this.pinConfig.collar.batteryAdc
//       },
//       feeder: {
//         servoPwm: this.pinConfig.feeder.servoPwm,
//         weightAdc: this.pinConfig.feeder.weightAdc,
//         feederLed: this.pinConfig.feeder.feederLed
//       }
//     };
//   }
//
//   // 创建模拟DriverKit（用于开发测试）
//   private createSimulatedDriverKit(): DriverKitType {
//     return new SimulatedDriverKit();
//   }
//
//   // 创建模拟GPIO引脚
//   private async createSimulatedGpioPin(pin: number): Promise<GpioPin> {
//     return new SimulatedGpioPin(pin);
//   }
//
//   // 创建模拟PWM引脚
//   private async createSimulatedPwmPin(pin: number): Promise<PwmPin> {
//     return new SimulatedPwmPin(pin);
//   }
//
//   // 创建模拟ADC引脚
//   private async createSimulatedAdcPin(pin: number): Promise<AdcPin> {
//     return new SimulatedAdcPin(pin);
//   }
// }
//
// // 单例实例
// let hi3863ControllerInstance: Hi3863Controller | null = null;
//
// // 获取Hi3863控制器实例（单例模式）
// export async function getHi3863Controller(pinConfig?: Hi3863PinConfig): Promise<Hi3863Controller> {
//   if (!hi3863ControllerInstance) {
//     hi3863ControllerInstance = new Hi3863Controller(pinConfig);
//     await hi3863ControllerInstance.initialize();
//   }
//   return hi3863ControllerInstance;
// }
//
// // 释放控制器实例
// export async function releaseHi3863Controller(): Promise<void> {
//   if (hi3863ControllerInstance) {
//     await hi3863ControllerInstance.release();
//     hi3863ControllerInstance = null;
//   }
// }
