// 设备管理页面 — 集成软总线设备发现
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard, StatusBadge } from '../components/CommonComponents';
import { DeviceType } from '../models/DataModels';
import type { DeviceInfo } from '../models/DataModels';
import { DeviceDiscoveryService } from '../services/DeviceDiscoveryService';
import type { DiscoveredDevice } from '../services/DeviceDiscoveryService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DevicesPage';

@Component
export struct DevicesPage {
  @State private devices: DeviceInfo[] = [
    {
      id: '1', name: '智能项圈', model: 'PetCollar Pro', type: DeviceType.COLLAR,
      isOnline: true, battery: 87, iconSymbol: '🐕', iconColor: AppColors.PRIMARY,
      gradientColors: [AppColors.PRIMARY, '#F97316'],
      features: ['GPS', '运动', '语音'], extraInfo: '电量 87%'
    },
    {
      id: '2', name: '智能喂食器', model: 'AutoFeeder X1', type: DeviceType.FEEDER,
      isOnline: true, iconSymbol: '🍽️', iconColor: AppColors.SECONDARY,
      gradientColors: [AppColors.SECONDARY, '#3B82F6'],
      features: ['定时', '智能', '远程'], extraInfo: '余粮 68%'
    },
    {
      id: '3', name: '智能饮水机', model: 'WaterFlow Plus', type: DeviceType.WATER,
      isOnline: true, iconSymbol: '💧', iconColor: '#3B82F6',
      gradientColors: ['#60A5FA', '#06B6D4'],
      features: [], extraInfo: '水量 64%'
    }
  ];

  @State private discoveredDevices: DiscoveredDevice[] = [];

  private moreDevices: Array<[string, string, string]> = [
    ['📹', '#FAF5FF', '摄像头'],
    ['🚽', '#F0FDF4', '猫砂盆'],
    ['🌡️', '#FFF7ED', '温湿度'],
    ['🎮', '#FDF2F8', '玩具']
  ];

  aboutToAppear(): void {
    this.loadDiscoveredDevices();
    // 监听设备变更
    DeviceDiscoveryService.onDeviceChange((devices: DiscoveredDevice[]) => {
      this.discoveredDevices = devices;
    });
  }

  aboutToDisappear(): void {
    // 注意：简化处理，实际应保存回调引用以便移除
  }

  private loadDiscoveredDevices(): void {
    this.discoveredDevices = DeviceDiscoveryService.getAvailableDevices();
  }

  @Builder
  private buildDeviceCard(device: DeviceInfo) {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Row({ space: 12 }) {
            Text(device.iconSymbol)
              .fontSize(24).width(48).height(48)
              .textAlign(TextAlign.Center).borderRadius(12)
              .linearGradient({
                angle: 135,
                colors: [[device.gradientColors[0], 0], [device.gradientColors[1], 1]]
              })
            Column({ space: 2 }) {
              Text(device.name).fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
              Text('型号: ' + device.model).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
            }.alignItems(HorizontalAlign.Start)
          }
          Blank()
          Column({ space: 4 }) {
            StatusBadge({ label: device.isOnline ? '在线' : '离线', isOnline: device.isOnline })
            if (device.extraInfo) {
              Text(device.extraInfo).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
            }
          }.alignItems(HorizontalAlign.End)
        }.width('100%')

        if (device.features.length > 0) {
          Grid() {
            ForEach(device.features, (feat: string) => {
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
        }.width('100%')

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
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
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
              }.alignItems(HorizontalAlign.Center)
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
          Button('添加设备')
            .fontSize(AppFonts.CAPTION).fontColor(Color.White)
            .backgroundColor(AppColors.PRIMARY).borderRadius(20)
            .height(32).padding({ left: 14, right: 14 })
        }
        .width('100%').padding({ left: 4, right: 4, bottom: 4 })

        ForEach(this.devices, (device: DeviceInfo) => {
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
