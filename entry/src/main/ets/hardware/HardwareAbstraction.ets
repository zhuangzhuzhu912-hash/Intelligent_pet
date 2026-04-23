// 硬件抽象层
// 提供统一的硬件控制接口，支持模拟和真实硬件（Hi3863开发板）

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HardwareCommandType } from '../models/DataModels';
import type { HardwareCommand } from '../models/DataModels';

const TAG: string = 'HardwareAbstraction';
const DOMAIN: number = 0x0000;

// GPIO引脚配置
export interface GpioConfig {
  pin: number;
  direction: 'in' | 'out';
  pull: 'none' | 'pullup' | 'pulldown';
}

// PWM配置
export interface PwmConfig {
  pin: number;
  frequency: number;
  dutyCycle: number;
}

// ADC配置
export interface AdcConfig {
  pin: number;
  referenceVoltage: number;
}

// 硬件状态信息接口
export interface HardwareControllerStatus {
  isInitialized: boolean;
  timestamp: string;
  gpio?: Record<string, boolean | string>;
  pwm?: Record<string, number | string>;
  adc?: Record<string, number | string>;
  controllerType?: string;
}

// 硬件控制器接口
export interface HardwareController {
  // 初始化
  initialize(): Promise<void>;

  // GPIO控制
  setGpio(pin: number, value: boolean): Promise<void>;
  getGpio(pin: number): Promise<boolean>;

  // PWM控制
  setPwm(pin: number, dutyCycle: number): Promise<void>;

  // ADC读取
  readAdc(pin: number): Promise<number>;

  // 发送命令
  sendCommand(command: HardwareCommand): Promise<void>;

  // 获取状态
  getStatus(): Promise<HardwareControllerStatus>;

  // 释放资源
  release(): Promise<void>;
}

// 模拟硬件控制器（用于开发和测试）
export class SimulatedHardwareController implements HardwareController {
  private gpioStates: Map<number, boolean> = new Map();
  private pwmStates: Map<number, number> = new Map();
  private isInitialized: boolean = false;
  private timeouts: number[] = []; // 用于跟踪所有setTimeout，便于清理

  async initialize(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Simulated hardware controller initialized');
    this.isInitialized = true;

    // 初始化默认引脚状态
    this.gpioStates.set(7, false);  // 蜂鸣器
    this.gpioStates.set(8, false);  // LED指示灯
    this.gpioStates.set(10, false); // 状态LED

    this.pwmStates.set(9, 0);       // 舵机初始位置
  }

  async setGpio(pin: number, value: boolean): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    this.gpioStates.set(pin, value);
    hilog.info(DOMAIN, TAG, `GPIO pin ${pin} set to ${value}`);

    // 模拟硬件响应延迟
    await new Promise<void>(resolve => setTimeout(resolve, 50));
  }

  async getGpio(pin: number): Promise<boolean> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    return this.gpioStates.get(pin) || false;
  }

  async setPwm(pin: number, dutyCycle: number): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    // 限制占空比在0-100之间
    const clampedDutyCycle = Math.max(0, Math.min(100, dutyCycle));
    this.pwmStates.set(pin, clampedDutyCycle);
    hilog.info(DOMAIN, TAG, `PWM pin ${pin} set to ${clampedDutyCycle}%`);

    await new Promise<void>(resolve => setTimeout(resolve, 100));
  }

  async readAdc(pin: number): Promise<number> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    // 模拟ADC读数（0-4095）
    const value = Math.floor(Math.random() * 4096);
    hilog.debug(DOMAIN, TAG, `ADC pin ${pin} read: ${value}`);

    await new Promise<void>(resolve => setTimeout(resolve, 20));
    return value;
  }

  async sendCommand(command: HardwareCommand): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    hilog.info(DOMAIN, TAG, `Sending command: ${command.type} to device ${command.deviceId}`);

    // 模拟命令处理
    switch (command.type) {
      case HardwareCommandType.FIND_PET:
        // 一键寻宠：打开蜂鸣器和LED
        await this.setGpio(7, true);  // 蜂鸣器
        await this.setGpio(8, true);  // LED

        // 使用箭头函数保持this上下文
        const findPetTimeout = setTimeout(async () => {
          try {
            await this.setGpio(7, false);
            await this.setGpio(8, false);
          } catch (err) {
            hilog.error(DOMAIN, TAG, `Failed to turn off find pet indicators: ${JSON.stringify(err)}`);
          }
        }, 3000); // 3秒后关闭

        this.timeouts.push(findPetTimeout as unknown as number);
        break;

      case HardwareCommandType.FEED_NOW:
        // 立即投喂：控制舵机
        const amount = command.payload?.amount || 30;
        const dutyCycle = (amount / 100) * 100; // 简化计算
        await this.setPwm(9, dutyCycle);
        break;

      case HardwareCommandType.GET_STATUS:
        // 获取状态：返回模拟状态
        hilog.info(DOMAIN, TAG, 'Status query received');
        break;

      default:
        hilog.warn(DOMAIN, TAG, `Unknown command type: ${command.type}`);
    }

    await new Promise<void>(resolve => setTimeout(resolve, 200));
  }

  async getStatus(): Promise<any> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    return {
      isInitialized: this.isInitialized,
      gpioStates: Object.fromEntries(this.gpioStates),
      pwmStates: Object.fromEntries(this.pwmStates),
      timestamp: new Date().toISOString()
    };
  }

  async release(): Promise<void> {
    // 清除所有定时器
    this.timeouts.forEach(timeoutId => {
      clearTimeout(timeoutId);
    });
    this.timeouts = [];

    // 重置所有引脚
    for (const [pin] of this.gpioStates) {
      this.gpioStates.set(pin, false);
    }

    for (const [pin] of this.pwmStates) {
      this.pwmStates.set(pin, 0);
    }

    this.isInitialized = false;
    hilog.info(DOMAIN, TAG, 'Simulated hardware controller released');
  }
}

// Hi3863硬件控制器
export class Hi3863HardwareController implements HardwareController {
  private gpioPins: Map<number, any> = new Map();
  private pwmPins: Map<number, any> = new Map();
  private adcPins: Map<number, any> = new Map();
  private isInitialized: boolean = false;
  private timeouts: number[] = []; // 用于跟踪所有setTimeout，便于清理

  // 保存this引用，用于回调函数
  private self = this;

  async initialize(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Initializing Hi3863 hardware controller');

      // DriverKit在应用层不可直接使用，使用模拟模式
      const DriverKit = this.createSimulatedDriverKit();
      hilog.info(DOMAIN, TAG, 'Using simulated DriverKit for application layer');

      // 初始化GPIO引脚
      const gpioConfigs: Array<{pin: number, direction: 'in' | 'out', pull: 'none' | 'pullup' | 'pulldown'}> = [
        { pin: 7, direction: 'out', pull: 'none' },  // 蜂鸣器
        { pin: 8, direction: 'out', pull: 'none' },  // LED指示灯
        { pin: 10, direction: 'out', pull: 'none' }, // 状态LED
      ];

      for (const config of gpioConfigs) {
        try {
          const gpioPin = await DriverKit.createGpioPin(config.pin);
          await gpioPin.setDirection(config.direction);
          await gpioPin.setPull(config.pull);
          this.gpioPins.set(config.pin, gpioPin);
          hilog.debug(DOMAIN, TAG, `GPIO pin ${config.pin} initialized`);
        } catch (err) {
          hilog.error(DOMAIN, TAG, `Failed to initialize GPIO pin ${config.pin}: ${JSON.stringify(err)}`);
          // 创建模拟GPIO引脚
          this.gpioPins.set(config.pin, this.createSimulatedGpioPin(config.pin));
        }
      }

      // 初始化PWM引脚（舵机控制）
      try {
        const pwmPin = await DriverKit.createPwmPin(9);
        await pwmPin.setFrequency(50); // 50Hz for servo
        await pwmPin.setDutyCycle(0);
        this.pwmPins.set(9, pwmPin);
        hilog.debug(DOMAIN, TAG, 'PWM pin 9 initialized');
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to initialize PWM pin 9: ${JSON.stringify(err)}`);
        // 创建模拟PWM引脚
        this.pwmPins.set(9, this.createSimulatedPwmPin(9));
      }

      // 初始化ADC引脚（称重传感器）
      try {
        const adcPin = await DriverKit.createAdcPin(0);
        this.adcPins.set(0, adcPin);
        hilog.debug(DOMAIN, TAG, 'ADC pin 0 initialized');
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to initialize ADC pin 0: ${JSON.stringify(err)}`);
        // 创建模拟ADC引脚
        this.adcPins.set(0, this.createSimulatedAdcPin(0));
      }

      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'Hi3863 hardware controller initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to initialize Hi3863 controller: ${JSON.stringify(err)}`);
      throw new Error(`Hi3863初始化失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`);
    }
  }

  async setGpio(pin: number, value: boolean): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    const gpioPin = this.gpioPins.get(pin);
    if (!gpioPin) {
      throw new Error(`GPIO pin ${pin} not configured`);
    }

    try {
      // 检查是否是模拟引脚
      if (gpioPin.isSimulated) {
        await gpioPin.write(value);
      } else {
        await gpioPin.write(value ? 1 : 0);
      }
      hilog.info(DOMAIN, TAG, `GPIO pin ${pin} set to ${value}`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to set GPIO pin ${pin}: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  async getGpio(pin: number): Promise<boolean> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    const gpioPin = this.gpioPins.get(pin);
    if (!gpioPin) {
      throw new Error(`GPIO pin ${pin} not configured`);
    }

    try {
      let value: number;
      if (gpioPin.isSimulated) {
        value = await gpioPin.read();
      } else {
        value = await gpioPin.read();
      }
      return value > 0;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to read GPIO pin ${pin}: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  async setPwm(pin: number, dutyCycle: number): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    const pwmPin = this.pwmPins.get(pin);
    if (!pwmPin) {
      throw new Error(`PWM pin ${pin} not configured`);
    }

    try {
      // 限制占空比在0-100之间
      const clampedDutyCycle = Math.max(0, Math.min(100, dutyCycle));

      if (pwmPin.isSimulated) {
        await pwmPin.setDutyCycle(clampedDutyCycle);
      } else {
        await pwmPin.setDutyCycle(clampedDutyCycle);
      }

      hilog.info(DOMAIN, TAG, `PWM pin ${pin} set to ${clampedDutyCycle}%`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to set PWM pin ${pin}: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  async readAdc(pin: number): Promise<number> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    const adcPin = this.adcPins.get(pin);
    if (!adcPin) {
      throw new Error(`ADC pin ${pin} not configured`);
    }

    try {
      let value: number;
      if (adcPin.isSimulated) {
        value = await adcPin.read();
      } else {
        value = await adcPin.read();
      }

      hilog.debug(DOMAIN, TAG, `ADC pin ${pin} read: ${value}`);
      return value;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to read ADC pin ${pin}: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  async sendCommand(command: HardwareCommand): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    hilog.info(DOMAIN, TAG, `Sending command to Hi3863: ${command.type}`);

    try {
      switch (command.type) {
        case HardwareCommandType.FIND_PET:
          // 一键寻宠：蜂鸣器响3秒，LED闪烁
          await this.setGpio(7, true);  // 蜂鸣器开
          await this.setGpio(8, true);  // LED开

          // 使用箭头函数保持this上下文
          const findPetTimeout = setTimeout(async () => {
            try {
              await this.self.setGpio(7, false);
              await this.self.setGpio(8, false);
            } catch (err) {
              hilog.error(DOMAIN, TAG, `Failed to turn off find pet indicators: ${JSON.stringify(err)}`);
            }
          }, 3000);

          this.timeouts.push(findPetTimeout as unknown as number);
          break;

        case HardwareCommandType.FEED_NOW:
          // 立即投喂：控制舵机转动
          const amount = command.payload?.amount || 30;
          // 将克数转换为舵机角度（简化计算）
          const dutyCycle = 2.5 + (amount / 100) * 10; // 2.5% - 12.5%对应0-180度
          await this.setPwm(9, dutyCycle);

          // 使用箭头函数保持this上下文
          const feedTimeout = setTimeout(async () => {
            try {
              await this.self.setPwm(9, 2.5); // 复位到0度
            } catch (err) {
              hilog.error(DOMAIN, TAG, `Failed to reset servo: ${JSON.stringify(err)}`);
            }
          }, 1000);

          this.timeouts.push(feedTimeout as unknown as number);
          break;

        case HardwareCommandType.GET_STATUS:
          // 状态查询：读取所有传感器
          hilog.info(DOMAIN, TAG, 'Status query received');
          break;

        default:
          hilog.warn(DOMAIN, TAG, `Unsupported command type for Hi3863: ${command.type}`);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to execute command ${command.type}: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  async getStatus(): Promise<any> {
    if (!this.isInitialized) {
      throw new Error('Controller not initialized');
    }

    try {
      const status: any = {
        isInitialized: this.isInitialized,
        timestamp: new Date().toISOString(),
        gpio: {},
        pwm: {},
        adc: {},
        controllerType: 'Hi3863'
      };

      // 读取GPIO状态
      for (const [pin, gpioPin] of this.gpioPins) {
        try {
          let value: number;
          if (gpioPin.isSimulated) {
            value = await gpioPin.read();
          } else {
            value = await gpioPin.read();
          }
          status.gpio[`pin_${pin}`] = value > 0;
        } catch (err) {
          status.gpio[`pin_${pin}`] = 'error';
        }
      }

      // 读取ADC值
      for (const [pin, adcPin] of this.adcPins) {
        try {
          let value: number;
          if (adcPin.isSimulated) {
            value = await adcPin.read();
          } else {
            value = await adcPin.read();
          }
          status.adc[`pin_${pin}`] = value;
        } catch (err) {
          status.adc[`pin_${pin}`] = 'error';
        }
      }

      return status;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to get hardware status: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  async release(): Promise<void> {
    try {
      // 清除所有定时器
      this.timeouts.forEach(timeoutId => {
        clearTimeout(timeoutId);
      });
      this.timeouts = [];

      // 关闭所有GPIO
      for (const [pin, gpioPin] of this.gpioPins) {
        try {
          if (gpioPin.isSimulated) {
            await gpioPin.write(0);
            await gpioPin.close();
          } else {
            await gpioPin.write(0);
            await gpioPin.close();
          }
        } catch (err) {
          hilog.warn(DOMAIN, TAG, `Failed to close GPIO pin ${pin}: ${JSON.stringify(err)}`);
        }
      }

      // 关闭所有PWM
      for (const [pin, pwmPin] of this.pwmPins) {
        try {
          if (pwmPin.isSimulated) {
            await pwmPin.setDutyCycle(0);
            await pwmPin.close();
          } else {
            await pwmPin.setDutyCycle(0);
            await pwmPin.close();
          }
        } catch (err) {
          hilog.warn(DOMAIN, TAG, `Failed to close PWM pin ${pin}: ${JSON.stringify(err)}`);
        }
      }

      // 关闭所有ADC
      for (const [pin, adcPin] of this.adcPins) {
        try {
          if (adcPin.isSimulated) {
            await adcPin.close();
          } else {
            await adcPin.close();
          }
        } catch (err) {
          hilog.warn(DOMAIN, TAG, `Failed to close ADC pin ${pin}: ${JSON.stringify(err)}`);
        }
      }

      this.gpioPins.clear();
      this.pwmPins.clear();
      this.adcPins.clear();
      this.isInitialized = false;

      hilog.info(DOMAIN, TAG, 'Hi3863 hardware controller released');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error releasing hardware controller: ${JSON.stringify(err)}`);
      throw err;
    }
  }

  // 创建模拟DriverKit
  private createSimulatedDriverKit(): any {
    return {
      createGpioPin: (pin: number) => this.createSimulatedGpioPin(pin),
      createPwmPin: (pin: number) => this.createSimulatedPwmPin(pin),
      createAdcPin: (pin: number) => this.createSimulatedAdcPin(pin)
    };
  }

  // 创建模拟GPIO引脚
  private createSimulatedGpioPin(pin: number): any {
    let state = false;
    return {
      isSimulated: true,
      setDirection: async (direction: string) => {
        hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${pin} direction set to ${direction}`);
      },
      setPull: async (pull: string) => {
        hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${pin} pull set to ${pull}`);
      },
      write: async (value: number) => {
        state = value > 0;
        hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${pin} written to ${value}`);
        await new Promise<void>(resolve => setTimeout(resolve, 10));
      },
      read: async (): Promise<number> => {
        await new Promise<void>(resolve => setTimeout(resolve, 5));
        return state ? 1 : 0;
      },
      close: async () => {
        hilog.debug(DOMAIN, TAG, `Simulated GPIO pin ${pin} closed`);
      }
    };
  }

  // 创建模拟PWM引脚
  private createSimulatedPwmPin(pin: number): any {
    let dutyCycle = 0;
    return {
      isSimulated: true,
      setFrequency: async (frequency: number) => {
        hilog.debug(DOMAIN, TAG, `Simulated PWM pin ${pin} frequency set to ${frequency}Hz`);
      },
      setDutyCycle: async (dc: number) => {
        dutyCycle = Math.max(0, Math.min(100, dc));
        hilog.debug(DOMAIN, TAG, `Simulated PWM pin ${pin} duty cycle set to ${dutyCycle}%`);
        await new Promise<void>(resolve => setTimeout(resolve, 20));
      },
      close: async () => {
        hilog.debug(DOMAIN, TAG, `Simulated PWM pin ${pin} closed`);
      }
    };
  }

  // 创建模拟ADC引脚
  private createSimulatedAdcPin(pin: number): any {
    return {
      isSimulated: true,
      read: async (): Promise<number> => {
        // 模拟ADC读数（0-4095）
        const value = Math.floor(Math.random() * 4096);
        await new Promise<void>(resolve => setTimeout(resolve, 15));
        return value;
      },
      close: async () => {
        hilog.debug(DOMAIN, TAG, `Simulated ADC pin ${pin} closed`);
      }
    };
  }
}

// 硬件控制器工厂
export class HardwareControllerFactory {
  private static instance: HardwareController | null = null;
  private static controllerType: 'simulated' | 'hi3863' = 'simulated';

  // 设置控制器类型
  static setControllerType(type: 'simulated' | 'hi3863'): void {
    this.controllerType = type;
    hilog.info(DOMAIN, TAG, `Hardware controller type set to: ${type}`);
  }

  // 获取硬件控制器实例（单例）
  static async getController(): Promise<HardwareController> {
    if (!this.instance) {
      switch (this.controllerType) {
        case 'hi3863':
          this.instance = new Hi3863HardwareController();
          hilog.info(DOMAIN, TAG, 'Creating Hi3863 hardware controller');
          break;
        case 'simulated':
        default:
          this.instance = new SimulatedHardwareController();
          hilog.info(DOMAIN, TAG, 'Creating simulated hardware controller');
          break;
      }

      try {
        await this.instance.initialize();
      } catch (err) {
        this.instance = null;
        hilog.error(DOMAIN, TAG, `Failed to initialize hardware controller: ${JSON.stringify(err)}`);
        throw err;
      }
    }

    return this.instance;
  }

  // 释放控制器
  static async releaseController(): Promise<void> {
    if (this.instance) {
      try {
        await this.instance.release();
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Error releasing hardware controller: ${JSON.stringify(err)}`);
      } finally {
        this.instance = null;
      }
    }
  }

  // 获取当前控制器类型
  static getControllerType(): string {
    return this.controllerType;
  }
}