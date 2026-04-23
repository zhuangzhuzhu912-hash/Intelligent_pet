// 传感器服务
// 处理加速度传感器数据，实现步数检测和运动监测

import { hilog } from '@kit.PerformanceAnalysisKit';
import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from './RdbHelper';
import type { AccelerometerData, ActivityData, SensorData } from '../models/DataModels';
import { AccelerationData, MotionRecord, SensorServiceStatus, StepDetectionParams } from '../models/SensorModels';

// 模拟sensor常量（SensorKit在应用层不可直接使用）
const SENSOR_MODE_REALTIME: number = 0;

const TAG: string = 'SensorService';
const DOMAIN: number = 0x0000;




class SensorServiceClass {
  private isMonitoring: boolean = false;
  // private accelerometerSensor: any | null = null;
  // private stepCounterSensor: any | null = null;
  private currentPetId: number = -1;
  private currentDeviceId: string = '';

  // 运动数据
  private stepCount: number = 0;
  private distance: number = 0; // 米
  private calories: number = 0; // 千卡
  private lastStepTime: number = 0;
  private accelerationBuffer: Array<AccelerationData> = [];

  // 模拟数据（当真实传感器不可用时）
  private useSimulation: boolean = false;
  private simulationInterval: number = 0;
  private lastSimulationTime: number = 0;
  private STEP_DETECTION_PARAMS: StepDetectionParams = {
    accelerationThreshold: 1.2,
    stepTimeWindow: 500,
    minStepInterval: 200,
    filterAlpha: 0.8,
  };

  // 开始运动监测
  async startMonitoring(petId: number, deviceId: string = '', useSimulation: boolean = false): Promise<void> {
    if (this.isMonitoring) {
      hilog.warn(DOMAIN, TAG, 'Sensor monitoring already started');
      return;
    }

    this.currentPetId = petId;
    this.currentDeviceId = deviceId;
    this.useSimulation = useSimulation;

    try {
      if (useSimulation) {
        await this.startSimulation();
      } else {
        await this.startRealSensors();
      }

      this.isMonitoring = true;
      this.resetCounters();
      hilog.info(DOMAIN, TAG, `Sensor monitoring started for pet ${petId}, simulation: ${useSimulation}`);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to start sensor monitoring: ${errorMessage}`);

      // 如果真实传感器失败，回退到模拟模式
      if (!useSimulation) {
        hilog.warn(DOMAIN, TAG, 'Falling back to simulation mode');
        this.useSimulation = true;
        await this.startSimulation();
        this.isMonitoring = true;
        this.resetCounters();
      } else {
        throw new Error(`启动运动监测失败: ${errorMessage}`);
      }
    }
  }

  // 停止运动监测
  async stopMonitoring(): Promise<void> {
    if (!this.isMonitoring) {
      return;
    }

    try {
      if (this.useSimulation) {
        await this.stopSimulation();
      } else {
        await this.stopRealSensors();
      }

      // 保存最终数据
      await this.saveSensorData();

      this.isMonitoring = false;
      this.currentPetId = -1;
      this.currentDeviceId = '';
      hilog.info(DOMAIN, TAG, 'Sensor monitoring stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to stop sensor monitoring: ${JSON.stringify(err)}`);
      throw new Error(`停止运动监测失败: ${JSON.stringify(err)}`);
    }
  }

  // 启动真实传感器
  private async startRealSensors(): Promise<void> {
    // SensorKit在应用层不可直接使用，需要通过系统服务
    // 直接抛出错误以回退到模拟模式
    throw new Error('SensorKit not available in application layer');
  }

  // 停止真实传感器
  private async stopRealSensors(): Promise<void> {
    // if (this.accelerometerSensor) {
    //   this.accelerometerSensor = null;
    // }
    // if (this.stepCounterSensor) {
    //   this.stepCounterSensor = null;
    // }
    hilog.info(DOMAIN, TAG, 'Real sensors stopped');
  }

  // 启动模拟传感器
  private async startSimulation(): Promise<void> {
    try {
      this.lastSimulationTime = Date.now();

      // 模拟传感器数据生成
      this.simulationInterval = setInterval(() => {
        this.generateSimulatedData();
      }, 100)  as number; // 每100ms生成一次数据

      hilog.info(DOMAIN, TAG, 'Simulation mode started');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to start simulation: ${JSON.stringify(err)}`);
      throw new Error(`启动模拟传感器失败: ${JSON.stringify(err)}`);
    }
  }

  // 停止模拟传感器
  private async stopSimulation(): Promise<void> {
    try {
      if (this.simulationInterval) {
        clearInterval(this.simulationInterval);
        this.simulationInterval = 0;
      }

      hilog.info(DOMAIN, TAG, 'Simulation mode stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error stopping simulation: ${JSON.stringify(err)}`);
      throw new Error(`停止模拟传感器失败: ${JSON.stringify(err)}`);
    }
  }

  // 处理加速度传感器数据
  private async handleAccelerometerData(data: AccelerationData): Promise<void> {
    try {
      const timestamp = Date.now();
      const acceleration: AccelerationData = {
        x: data.x,
        y: data.y,
        z: data.z,
        timestamp: timestamp,
      };

      // 添加到缓冲区
      this.accelerationBuffer.push(acceleration);


      // 保持缓冲区大小
      if (this.accelerationBuffer.length > 100) {
        this.accelerationBuffer.shift();
      }

      // 检测步数
      this.detectSteps(acceleration);

      // 定期保存数据
      if (timestamp % 10000 < 100) { // 每10秒左右保存一次
        await this.saveSensorData();
      }

      hilog.debug(DOMAIN, TAG, `Accelerometer: x=${data.x.toFixed(2)}, y=${data.y.toFixed(2)}, z=${data.z.toFixed(2)}`);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error handling accelerometer data: ${JSON.stringify(err)}`);
    }
  }

  // 处理步数计数器数据
  private async handleStepCounterData(data: ActivityData): Promise<void> {
    try {
      const steps = data.steps;
      if (steps > this.stepCount) {
        const newSteps = steps - this.stepCount;
        this.stepCount = steps;
        this.updateDistanceAndCalories(newSteps);

        hilog.info(DOMAIN, TAG, `Step counter: ${steps} steps (${newSteps} new)`);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error handling step counter data: ${JSON.stringify(err)}`);
    }
  }

  // 生成模拟数据
  private generateSimulatedData(): void {
    const now = Date.now();
    const timeDiff = now - this.lastSimulationTime;

    // 模拟步行模式
    const isWalking = Math.random() > 0.3; // 70%时间在走路
    const stepProbability = isWalking ? 0.7 : 0.1;

    if (Math.random() < stepProbability && timeDiff > this.STEP_DETECTION_PARAMS.minStepInterval) {
      this.stepCount++;
      this.lastStepTime = now;
      this.updateDistanceAndCalories(1);

      // 生成模拟加速度数据
      const acceleration: AccelerationData = {
        x: 0.5 + Math.random() * 2.0,
        y: 0.5 + Math.random() * 1.5,
        z: 9.8 + Math.random() * 0.5, // 重力加速度
        timestamp: now,
      };

      this.accelerationBuffer.push(acceleration);
      if (this.accelerationBuffer.length > 100) {
        this.accelerationBuffer.shift();
      }

      hilog.debug(DOMAIN, TAG, `Simulated step detected, total steps: ${this.stepCount}`);
    }

    this.lastSimulationTime = now;
  }

  // 步数检测算法
  private detectSteps(acceleration: AccelerationData): void {
    // 计算合加速度
    const totalAcceleration = Math.sqrt(
      acceleration.x * acceleration.x +
      acceleration.y * acceleration.y +
      acceleration.z * acceleration.z
    );

    // 去除重力影响（简单高通滤波）
    const gravity = 9.8;
    const dynamicAcceleration = Math.abs(totalAcceleration - gravity);

    // 检查是否超过阈值
    if (dynamicAcceleration > this.STEP_DETECTION_PARAMS.accelerationThreshold) {
      const now = acceleration.timestamp;

      // 检查时间间隔
      if (now - this.lastStepTime > this.STEP_DETECTION_PARAMS.minStepInterval) {
        this.stepCount++;
        this.lastStepTime = now;
        this.updateDistanceAndCalories(1);

        hilog.debug(DOMAIN, TAG, `Step detected! Total: ${this.stepCount}, Acceleration: ${dynamicAcceleration.toFixed(2)}`);
      }
    }
  }

  // 更新距离和卡路里
  private updateDistanceAndCalories(newSteps: number): void {
    // 假设平均步长0.5米（宠物）
    const stepLength = 0.5; // 米
    this.distance += newSteps * stepLength;

    // 简单卡路里计算：每步0.05千卡（宠物）
    const caloriesPerStep = 0.05;
    this.calories += newSteps * caloriesPerStep;

    hilog.debug(DOMAIN, TAG, `Updated: distance=${this.distance.toFixed(1)}m, calories=${this.calories.toFixed(1)}kcal`);
  }

  // 保存传感器数据到数据库
  private async saveSensorData(): Promise<void> {
    if (this.currentPetId <= 0) {
      return;
    }

    try {
      const userId = await this.getCurrentUserId();
      if (userId === -1) {
        return;
      }

      const timestamp = new Date().toISOString();

      // 保存步数数据到motion_record表
      const motionValues : relationalStore.ValuesBucket = {
        pet_id: this.currentPetId,
        user_id: userId,
        record_date: new Date().toISOString().split('T')[0],
        steps: this.stepCount,
        distance: this.distance / 1000, // 转换为公里
        calories: this.calories,
        goal_steps: 8000, // 默认目标
        duration_minutes: Math.floor(Date.now() / 60000) % 60, // 简化计算
        created_at: timestamp,
      };

      // 检查是否已有今日记录
      const existingRecord = await this.getTodayMotionRecord();
      if (existingRecord) {
        // 更新现有记录
        const predicates = new relationalStore.RdbPredicates('motion_record');
        predicates.equalTo('id', existingRecord.id);
        await RdbHelper.update(motionValues, predicates);
      } else {
        // 插入新记录
        await RdbHelper.insert('motion_record', motionValues);
      }

      // 保存传感器原始数据到硬件遥测表
      if (this.currentDeviceId && this.accelerationBuffer.length > 0) {
        const latestAcceleration = this.accelerationBuffer[this.accelerationBuffer.length - 1];
        const telemetryValues : relationalStore.ValuesBucket= {
          device_id: this.currentDeviceId,
          device_type: 'collar',
          metric_type: 'accelerometer',
          value: latestAcceleration.x, // 保存x轴加速度
          unit: 'm/s²',
          timestamp: timestamp,
          created_at: timestamp,
        };

        await RdbHelper.insert('hardware_telemetry', telemetryValues);
      }

      hilog.debug(DOMAIN, TAG, 'Sensor data saved to database');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to save sensor data: ${JSON.stringify(err)}`);
    }
  }

  // 获取今日运动记录
  private async getTodayMotionRecord(): Promise<MotionRecord |null> {
    try {
      const store = await RdbHelper.getStoreAsync();
      const predicates = new relationalStore.RdbPredicates('motion_record');
      const today = new Date().toISOString().split('T')[0];
      predicates.equalTo('pet_id', this.currentPetId);
      predicates.equalTo('record_date', today);

      const resultSet = await store.query(predicates);
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const record :MotionRecord= {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          steps: resultSet.getLong(resultSet.getColumnIndex('steps')),
          distance: resultSet.getDouble(resultSet.getColumnIndex('distance')),
          calories: resultSet.getDouble(resultSet.getColumnIndex('calories')),
        };
        resultSet.close();
        return record;
      }

      resultSet.close();
      return null;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to get today's motion record: ${JSON.stringify(err)}`);
      return null;
    }
  }

  // 获取当前运动数据
  getCurrentData(): SensorData {
    const latestAcceleration = this.accelerationBuffer.length > 0
      ? this.accelerationBuffer[this.accelerationBuffer.length - 1]
      : ({
        x: 0,
        y: 0,
        z: 0,
        timestamp: Date.now()
      })as AccelerationData;

    return {
      timestamp: new Date(latestAcceleration.timestamp).toISOString(),
      accelerometer: ({
        x: latestAcceleration.x,
        y: latestAcceleration.y,
        z: latestAcceleration.z,
      })as AccelerometerData,
      steps: this.stepCount,
      distance: this.distance,
      calories: this.calories,
    };
  }

  // 获取步数统计
  getStepStats(): MotionRecord {
    return {
      id:this.currentPetId,
      steps: this.stepCount,
      distance: this.distance,
      calories: this.calories,
    };
  }

  // 重置计数器
  resetCounters(): void {
    this.stepCount = 0;
    this.distance = 0;
    this.calories = 0;
    this.lastStepTime = 0;
    this.accelerationBuffer = [];
    hilog.info(DOMAIN, TAG, 'Counters reset');
  }

  // 获取当前用户ID（简化实现）
  private async getCurrentUserId(): Promise<number> {
    // 这里应该从用户服务获取当前用户ID
    // 简化实现，返回1
    return 1;
  }

  // 获取服务状态
  getStatus(): SensorServiceStatus {
    return {
      isMonitoring: this.isMonitoring,
      useSimulation: this.useSimulation,
      currentPetId: this.currentPetId,
      currentDeviceId: this.currentDeviceId,
      stepCount: this.stepCount,
      distance: this.distance,
      calories: this.calories,
      bufferSize: this.accelerationBuffer.length,
      lastStepTime: this.lastStepTime ? new Date(this.lastStepTime).toISOString() : null,
    };
  }
}

// 单例导出
export const SensorService = new SensorServiceClass();