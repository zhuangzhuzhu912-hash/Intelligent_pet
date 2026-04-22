import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RdbHelper } from '../services/RdbHelper';
import { DeviceDiscoveryService } from '../services/DeviceDiscoveryService';

const TAG: string = 'PetHubAbility';
const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, 'onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
    DeviceDiscoveryService.release();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');

    // 设置沉浸式状态栏
    windowStage.getMainWindow().then((mainWindow: window.Window) => {
      mainWindow.setWindowLayoutFullScreen(true);
      const sysBarProps: window.SystemBarProperties = {
        statusBarColor: '#00000000',
        statusBarContentColor: '#1F2937',
        navigationBarColor: '#FFFFFF',
        navigationBarContentColor: '#1F2937'
      };
      mainWindow.setWindowSystemBarProperties(sysBarProps);
    });

    // 先初始化数据库，完成后再加载页面内容
    // 这样确保页面中的任何数据库操作都不会因为 DB 未就绪而失败
    RdbHelper.initDb(this.context).then(() => {
      hilog.info(DOMAIN, TAG, 'Database initialized successfully');

      // 初始化软总线设备发现（非关键，失败不影响主流程）
      try {
        DeviceDiscoveryService.init();
        hilog.info(DOMAIN, TAG, 'DeviceDiscoveryService initialized');
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'Failed to init DeviceDiscoveryService: %{public}s', JSON.stringify(err));
      }

      // 数据库就绪后加载页面
      windowStage.loadContent('pages/Index', (err) => {
        if (err && err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, TAG, 'Content loaded successfully');
      });
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'Failed to init database: %{public}s', JSON.stringify(err));
      // 即使数据库初始化失败，也加载页面（页面会显示错误提示）
      windowStage.loadContent('pages/Index', (loadErr) => {
        if (loadErr && loadErr.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(loadErr));
        }
      });
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }
}
