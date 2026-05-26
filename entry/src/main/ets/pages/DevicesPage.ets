
// 设备管理页面 — 数据库驱动 + 设备增删功能

import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard, StatusBadge } from '../components/CommonComponents';
import { DeviceDiscoveryService } from '../services/DeviceDiscoveryService';
import { DeviceService } from '../services/DeviceService';
import type { DeviceEntity } from '../services/DeviceService';
import type { DiscoveredDevice } from '../services/DeviceDiscoveryService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DevicesPage';
const DEVICE_TYPE_OPTIONS: Array<[string, string, string]> = [
  ['collar', '🐕', '智能项圈'],
  ['feeder', '🍽️', '智能喂食器'],
  ['water', '💧', '饮水机'],
  ['camera', '📹', '摄像头'],
  ['litter_box', '🚽', '猫砂盆'],
  ['thermometer', '🌡️', '温湿度计'],
  ['toy', '🎮', '玩具'],
  ['other', '📱', '其他']
];

function getTypeIcon(type: string): string {
  const opt = DEVICE_TYPE_OPTIONS.find((o: [string, string, string]) => o[0] === type);
  return opt ? opt[1] : '📱';
}

function getTypeLabel(type: string): string {
  const opt = DEVICE_TYPE_OPTIONS.find((o: [string, string, string]) => o[0] === type);
  return opt ? opt[2] : '其他';
}

function getGradientColors(type: string): [string, string] {
  switch (type) {
    case 'collar': return ['#FF9F43', '#F97316'];
    case 'feeder': return ['#00B4D8', '#3B82F6'];
    case 'water': return ['#60A5FA', '#06B6D4'];
    case 'camera': return ['#8B5CF6', '#7C3AED'];
    case 'litter_box': return ['#10B981', '#059669'];
    case 'thermometer': return ['#F59E0B', '#D97706'];
    case 'toy': return ['#EC4899', '#DB2777'];
    default: return ['#6B7280', '#4B5563'];
  }
}

@Component
export struct DevicesPage {
  @State private devices: DeviceEntity[] = [];
  @State private discoveredDevices: DiscoveredDevice[] = [];
  @State private showAddForm: boolean = false;
  @State private addName: string = '';
  @State private addModel: string = '';
  @State private addTypeIndex: number = 0;

  private moreDevices: Array<[string, string, string]> = [
    ['📹', '#FAF5FF', '摄像头'],
    ['🚽', '#F0FDF4', '猫砂盆'],
    ['🌡️', '#FFF7ED', '温湿度'],
    ['🎮', '#FDF2F8', '玩具']
  ];

  aboutToAppear(): void {
    this.loadDevices();
    this.loadDiscoveredDevices();
    DeviceDiscoveryService.onDeviceChange((devices: DiscoveredDevice[]) => {
      this.discoveredDevices = devices;
    });
  }

  aboutToDisappear(): void {
    // 清理回调引用
  }

  private async loadDevices(): Promise<void> {
    try {
      this.devices = await DeviceService.getDevicesByCurrentUser();
    } catch (e) {
      hilog.error(0x0000, TAG, `Failed to load devices: ${JSON.stringify(e)}`);
    }
  }

  private loadDiscoveredDevices(): void {
    this.discoveredDevices = DeviceDiscoveryService.getAvailableDevices();
  }

  private async handleAddDevice(): Promise<void> {
    const typeVal = DEVICE_TYPE_OPTIONS[this.addTypeIndex][0];
    if (this.addName.trim() === '') {
      return;
    }
    const icon = getTypeIcon(typeVal);
    const gradients = getGradientColors(typeVal);
    try {
      await DeviceService.addDevice({
        name: this.addName.trim(),
        model: this.addModel.trim() || '未知型号',
        type: typeVal,
        iconSymbol: icon,
        iconColor: gradients[0],
        gradientStart: gradients[0],
        gradientEnd: gradients[1]
      });
      this.showAddForm = false;
      this.addName = '';
      this.addModel = '';
      this.addTypeIndex = 0;
      await this.loadDevices();
    } catch (e) {
      hilog.error(0x0000, TAG, `Add device failed: ${JSON.stringify(e)}`);
    }
  }

  private async handleDeleteDevice(deviceId: number): Promise<void> {
    try {
      await DeviceService.deleteDevice(deviceId);
      await this.loadDevices();
    } catch (e) {
      hilog.error(0x0000, TAG, `Delete device failed: ${JSON.stringify(e)}`);
    }
  }

  private getFeaturesArray(featuresStr: string): string[] {
    if (!featuresStr || featuresStr === '[]') {
      return [];
    }
    const cleaned: string = featuresStr.replace(/[\[\]"'\s]/g, '');
    if (cleaned === '') {
      return [];
    }
    return cleaned.split(',');
  }

  @Builder
  private buildAddForm() {
    GlassCard() {
      Column({ space: 12 }) {
        Text('新增设备')
          .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY).width('100%')

        Row({ space: 8 }) {
          Text('名称')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY).width(40)
          TextInput({ text: this.addName, placeholder: '请输入设备名称' })
            .fontSize(AppFonts.BODY).layoutWeight(1).height(36)
            .backgroundColor('#F9FAFB').borderRadius(8)
            .onChange((value: string) => {
              this.addName = value;
            })
        }

        Row({ space: 8 }) {
          Text('型号')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY).width(40)
          TextInput({ text: this.addModel, placeholder: '请输入设备型号' })
            .fontSize(AppFonts.BODY).layoutWeight(1).height(36)
            .backgroundColor('#F9FAFB').borderRadius(8)
            .onChange((value: string) => {
              this.addModel = value;
            })
        }

        Text('类型').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
        Grid() {
          ForEach(DEVICE_TYPE_OPTIONS, (opt: [string, string, string], index: number) => {
            GridItem() {
              Column({ space: 2 }) {
                Text(opt[1]).fontSize(20)
                Text(opt[2]).fontSize(10).fontColor(AppColors.TEXT_SECONDARY)
              }
              .width('100%').padding({ top: 6, bottom: 6 })
              .backgroundColor(this.addTypeIndex === index ? AppColors.PRIMARY_10 : '#F9FAFB')
              .borderRadius(8)
              .border({
                width: this.addTypeIndex === index ? 1.5 : 0,
                color: AppColors.PRIMARY
              })
              .onClick(() => {
                this.addTypeIndex = index;
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr').columnsGap(6).rowsGap(6).width('100%')

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
            .backgroundColor('#F3F4F6').borderRadius(20).height(36).layoutWeight(1)
            .onClick(() => {
              this.showAddForm = false;
              this.addName = '';
              this.addModel = '';
              this.addTypeIndex = 0;
            })
          Button('确认添加')
            .fontSize(AppFonts.BODY).fontColor(Color.White)
            .backgroundColor(AppColors.PRIMARY).borderRadius(20).height(36).layoutWeight(1)
            .onClick(() => {
              this.handleAddDevice();
            })
        }
        .width('100%')
      }
    }
  }

  @Builder
  private buildDeviceCard(device: DeviceEntity) {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Row({ space: 12 }) {
            Text(device.iconSymbol)
              .fontSize(24).width(48).height(48)
              .textAlign(TextAlign.Center).borderRadius(12)
              .linearGradient({
                angle: 135,
                colors: [[device.gradientStart || '#FF9F43', 0], [device.gradientEnd || '#F97316', 1]]
              })
            Column({ space: 2 }) {
              Text(device.name).fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
              Text('型号: ' + (device.model || '未知'))
                .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
          }
          Blank()
          Column({ space: 4 }) {
            StatusBadge({ label: device.isOnline ? '在线' : '离线', isOnline: device.isOnline })
            if (device.extraInfo) {
              Text(device.extraInfo).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
            }
          }
          .alignItems(HorizontalAlign.End)

          if (!device.isBuiltin) {
            Text('🗑️')
              .fontSize(18).width(32).height(32)
              .textAlign(TextAlign.Center)
              .margin({ left: 8 })
              .onClick(() => {
                this.handleDeleteDevice(device.id);
              })
          }
        }
        .width('100%')

        Text('类型: ' + getTypeLabel(device.type))
          .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
          .width('100%')

        if (this.getFeaturesArray(device.features).length > 0) {
          Grid() {
            ForEach(this.getFeaturesArray(device.features), (feat: string) => {
              GridItem() {
                Column({ space: 2 }) {
                  Text(feat).fontSize(13).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
                  Text(this.getFeatureSubtitle(feat)).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
                }
                .width('100%').padding({ top: 8, bottom: 8 })
                .backgroundColor('#F9FAFB').borderRadius(8)
                .alignItems(HorizontalAlign.Center)
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr').columnsGap(8).width('100%')
        }
      }
    }
  }

  @Builder
  private buildDistributedDevicesCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Text('📡 分布式组网设备')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text(`${this.discoveredDevices.length}台`)
            .fontSize(AppFonts.SMALL).fontColor(AppColors.SECONDARY)
        }
        .width('100%')

        if (this.discoveredDevices.length === 0) {
          Text('未发现组网设备，请确保设备已登录同一华为账号')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT).width('100%')
        } else {
          ForEach(this.discoveredDevices, (device: DiscoveredDevice) => {
            Row({ space: 12 }) {
              Text('📱')
                .fontSize(20).width(40).height(40)
                .textAlign(TextAlign.Center)
                .backgroundColor(AppColors.SECONDARY_10).borderRadius(20)
              Column({ space: 2 }) {
                Text(device.deviceName)
                  .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.TEXT_PRIMARY)
                Text(`ID: ${device.deviceId.substring(0, 8)}...`)
                  .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('已组网')
                .fontSize(AppFonts.SMALL).fontColor(AppColors.SUCCESS)
                .backgroundColor(AppColors.SUCCESS_10)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(10)
            }
            .width('100%').padding(8).borderRadius(10)
            .backgroundColor('#F9FAFB')
          })
        }
      }
    }
  }

  @Builder
  private buildMoreDevicesCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Text('更多设备')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
        Grid() {
          ForEach(this.moreDevices, (item: [string, string, string]) => {
            GridItem() {
              Column({ space: 6 }) {
                Text(item[0])
                  .fontSize(22).width(48).height(48)
                  .textAlign(TextAlign.Center).backgroundColor(item[1]).borderRadius(24)
                Text(item[2])
                  .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.Center)
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr').rowsGap(12).width('100%')
      }
    }
  }

  private getFeatureSubtitle(feat: string): string {
    const map: Record<string, string> = {
      'GPS': '定位', '运动': '监测', '语音': '对讲',
      '定时': '投喂', '智能': '联动', '远程': '控制'
    };
    return map[feat] ?? '';
  }

  build() {
    Scroll() {
      Column({ space: AppSizes.CARD_GAP }) {
        Row() {
          Text('我的设备')
            .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text(`${this.devices.length}台`)
            .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
            .margin({ right: 12 })
          Button('添加设备')
            .fontSize(AppFonts.CAPTION).fontColor(Color.White)
            .backgroundColor(AppColors.PRIMARY).borderRadius(20)
            .height(32).padding({ left: 14, right: 14 })
            .onClick(() => {
              this.showAddForm = !this.showAddForm;
            })
        }
        .width('100%').padding({ left: 4, right: 4, bottom: 4 })

        if (this.showAddForm) {
          this.buildAddForm()
        }

        if (this.devices.length === 0) {
          GlassCard() {
            Text('暂无设备，点击上方"添加设备"按钮添加您的第一台设备')
              .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT)
              .width('100%').textAlign(TextAlign.Center)
          }
        }

        ForEach(this.devices, (device: DeviceEntity) => {
          this.buildDeviceCard(device)
        })

        this.buildDistributedDevicesCard()
        this.buildMoreDevicesCard()
      }
      .width('100%')
      .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 16 })
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BG_PAGE)
  }
}
