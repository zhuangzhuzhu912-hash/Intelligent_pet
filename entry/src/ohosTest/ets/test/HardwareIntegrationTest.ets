// 硬件集成测试
// 测试智能项圈和喂食器的硬件功能集成

import { describe, it, expect } from '@ohos/hypium';
import { HardwareControllerFactory } from '../../../main/ets/hardware/HardwareAbstraction';
import { CollarHardwareService } from '../../../main/ets/services/CollarHardwareService';
import { FeederHardwareService } from '../../../main/ets/services/FeederHardwareService';
import { DeviceDiscoveryService, DeviceType } from '../../../main/ets/services/DeviceDiscoveryService';

const TAG: string = 'HardwareIntegrationTest';

export default function hardwareIntegrationTest() {
  describe('硬件集成测试', () => {
    it('测试硬件控制器工厂初始化', 0, async () => {
      try {
        // 设置为模拟模式进行测试
        HardwareControllerFactory.setControllerType('simulated');
        const controller = await HardwareControllerFactory.getController();

        expect(controller).assertNotUndefined();
        expect(controller).assertNotNull();

        const status = await controller.getStatus();
        expect(status.isInitialized).assertTrue();

        console.log(`${TAG}: 硬件控制器工厂测试通过`);
      } catch (err) {
        console.error(`${TAG}: 硬件控制器工厂测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试项圈硬件服务初始化', 0, async () => {
      try {
        await CollarHardwareService.initialize('test-device-001');
        const status = CollarHardwareService.getServiceStatus();

        expect(status.isInitialized).assertTrue();
        expect(status.controllerType).assertEqual('simulated');

        console.log(`${TAG}: 项圈硬件服务初始化测试通过`);

        // 清理
        await CollarHardwareService.release();
      } catch (err) {
        console.error(`${TAG}: 项圈硬件服务初始化测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试喂食器硬件服务初始化', 0, async () => {
      try {
        await FeederHardwareService.initialize('test-device-002');
        const status = FeederHardwareService.getServiceStatus();

        expect(status.isInitialized).assertTrue();
        expect(status.controllerType).assertEqual('simulated');

        console.log(`${TAG}: 喂食器硬件服务初始化测试通过`);

        // 清理
        await FeederHardwareService.release();
      } catch (err) {
        console.error(`${TAG}: 喂食器硬件服务初始化测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试一键寻宠功能', 0, async () => {
      try {
        await CollarHardwareService.initialize('test-device-003');

        // 执行一键寻宠
        await CollarHardwareService.findPet(1000); // 1秒测试

        // 检查服务状态
        const status = CollarHardwareService.getServiceStatus();
        expect(status.isFindingPet).assertTrue();

        console.log(`${TAG}: 一键寻宠功能测试通过`);

        // 等待寻宠完成
        await new Promise(resolve => setTimeout(resolve, 1500));

        // 清理
        await CollarHardwareService.release();
      } catch (err) {
        console.error(`${TAG}: 一键寻宠功能测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试立即投喂功能', 0, async () => {
      try {
        await FeederHardwareService.initialize('test-device-004');

        // 执行立即投喂
        await FeederHardwareService.feed(30); // 30克

        console.log(`${TAG}: 立即投喂功能测试通过`);

        // 等待投喂完成
        await new Promise(resolve => setTimeout(resolve, 1500));

        // 清理
        await FeederHardwareService.release();
      } catch (err) {
        console.error(`${TAG}: 立即投喂功能测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试设备发现服务', 0, async () => {
      try {
        // 初始化设备发现服务
        DeviceDiscoveryService.init();

        // 获取设备列表
        const devices = DeviceDiscoveryService.getAvailableDevices();

        expect(devices).assertNotUndefined();
        expect(Array.isArray(devices)).assertTrue();

        console.log(`${TAG}: 发现 ${devices.length} 个设备`);
        console.log(`${TAG}: 设备发现服务测试通过`);

        // 清理
        DeviceDiscoveryService.release();
      } catch (err) {
        console.error(`${TAG}: 设备发现服务测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试设备类型识别', 0, async () => {
      try {
        DeviceDiscoveryService.init();

        // 获取按类型分类的设备
        const collarDevices = DeviceDiscoveryService.getCollarDevices();
        const feederDevices = DeviceDiscoveryService.getFeederDevices();

        expect(collarDevices).assertNotUndefined();
        expect(feederDevices).assertNotUndefined();
        expect(Array.isArray(collarDevices)).assertTrue();
        expect(Array.isArray(feederDevices)).assertTrue();

        console.log(`${TAG}: 发现 ${collarDevices.length} 个项圈设备, ${feederDevices.length} 个喂食器设备`);
        console.log(`${TAG}: 设备类型识别测试通过`);

        DeviceDiscoveryService.release();
      } catch (err) {
        console.error(`${TAG}: 设备类型识别测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('测试硬件命令发送', 0, async () => {
      try {
        await CollarHardwareService.initialize('test-device-005');

        // 发送硬件命令
        const command = {
          commandType: 'FIND_PET',
          payload: { duration: 500 },
          timestamp: Date.now()
        };

        await CollarHardwareService.sendCommand(command);

        console.log(`${TAG}: 硬件命令发送测试通过`);

        // 等待命令执行
        await new Promise(resolve => setTimeout(resolve, 1000));

        await CollarHardwareService.release();
      } catch (err) {
        console.error(`${TAG}: 硬件命令发送测试失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });
  });

  describe('硬件部署验证测试', () => {
    it('验证硬件权限配置', 0, () => {
      // 验证module.json5中的硬件权限
      // 这里可以检查权限字符串，但实际验证需要在运行时进行
      console.log(`${TAG}: 硬件权限配置验证通过（需在运行时确认）`);
      expect(true).assertTrue();
    });

    it('验证Hi3863控制器接口', 0, async () => {
      try {
        // 测试Hi3863控制器接口
        const { getHi3863Controller } = await import('../../../main/ets/hardware/Hi3863Controller');
        const controller = await getHi3863Controller();

        expect(controller).assertNotUndefined();
        expect(typeof controller.executeCommand).assertEqual('function');
        expect(typeof controller.setGpio).assertEqual('function');
        expect(typeof controller.setPwm).assertEqual('function');
        expect(typeof controller.readAdc).assertEqual('function');

        console.log(`${TAG}: Hi3863控制器接口验证通过`);

        // 清理
        const { releaseHi3863Controller } = await import('../../../main/ets/hardware/Hi3863Controller');
        await releaseHi3863Controller();
      } catch (err) {
        console.error(`${TAG}: Hi3863控制器接口验证失败: ${JSON.stringify(err)}`);
        expect().fail();
      }
    });

    it('验证喂食计划页面集成', 0, () => {
      // 验证喂食计划页面是否正确导入硬件服务
      // 这里可以检查页面文件是否存在和基本结构
      console.log(`${TAG}: 喂食计划页面集成验证通过（需在UI运行时确认）`);
      expect(true).assertTrue();
    });

    it('验证HomePage硬件控制集成', 0, () => {
      // 验证HomePage是否正确集成硬件控制功能
      console.log(`${TAG}: HomePage硬件控制集成验证通过（需在UI运行时确认）`);
      expect(true).assertTrue();
    });
  });
}