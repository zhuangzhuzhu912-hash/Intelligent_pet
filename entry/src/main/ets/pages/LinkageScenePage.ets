
// 联动场景页面 — 基于已绑定设备的场景管理
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard, StatusBadge } from '../components/CommonComponents';
import { DeviceDiscoveryService } from '../services/DeviceDiscoveryService';
import { DeviceService } from '../services/DeviceService';
import type { DeviceEntity } from '../services/DeviceService';
import { router } from '@kit.ArkUI';

interface SceneItem {
  id: number;
  icon: string;
  name: string;
  description: string;
  devices: string;
  active: boolean;
  isBuiltin: boolean;
}

@Component
@Entry
@Component
export struct LinkageScenePage {
  @State private scenes: SceneItem[] = [
    { id: 2, icon: '🏃', name: '运动达标奖励', description: '宠物当日运动量达标后，自动额外投放零食奖励', devices: '智能项圈 + 智能喂食器', active: true, isBuiltin: true },
    { id: 3, icon: '💤', name: '睡眠监测通知', description: '当宠物夜间活动异常时，推送通知提醒主人查看', devices: '智能项圈', active: false, isBuiltin: true },
    { id: 4, icon: '🌡️', name: '温湿度自动调节', description: '环境温湿度超出舒适范围时，自动开启空调或加湿器', devices: '温湿度传感器 + 智能家居', active: false, isBuiltin: true },
    { id: 5, icon: '💧', name: '饮水提醒', description: '当饮水机水量不足或宠物饮水量异常时提醒加水', devices: '智能饮水机', active: true, isBuiltin: true }
  ];

  @State private bondDevices: DeviceEntity[] = [];
  @State private discoveredCount: number = 0;
  @State private showAddForm: boolean = false;
  @State private newSceneName: string = '';
  @State private newSceneDesc: string = '';
  @State private newSceneIcon: string = '🔗';
  @State private selectedDeviceIds: number[] = [];
  private nextId: number = 10;

  private iconOptions: string[] = ['🔗', '🏠', '🏃', '💤', '🌡️', '💧', '🍽️', '🎯', '⚡', '🛡️'];

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.bondDevices = await DeviceService.getDevicesByCurrentUser();
    this.discoveredCount = DeviceDiscoveryService.getAvailableDevices().length;
  }

  private getBondDeviceNames(): string {
    if (this.bondDevices.length === 0) {
      return '暂无已绑定设备';
    }
    return this.bondDevices.map((d: DeviceEntity) => d.name).join('、');
  }

  private getTotalAvailableCount(): number {
    return this.bondDevices.length + this.discoveredCount;
  }

  private toggleDeviceSelection(deviceId: number): void {
    const idx = this.selectedDeviceIds.indexOf(deviceId);
    if (idx >= 0) {
      this.selectedDeviceIds.splice(idx, 1);
    } else {
      this.selectedDeviceIds.push(deviceId);
    }
  }

  private getSelectedDeviceNames(): string {
    if (this.selectedDeviceIds.length === 0) {
      return '请选择联动设备';
    }
    const names: string[] = [];
    for (const id of this.selectedDeviceIds) {
      const d = this.bondDevices.find((dev: DeviceEntity) => dev.id === id);
      if (d) {
        names.push(d.name);
      }
    }
    return names.join(' + ');
  }

  private async handleAddScene(): Promise<void> {
    if (this.newSceneName.trim() === '') {
      return;
    }
    const newScene: SceneItem = {
      id: this.nextId++,
      icon: this.newSceneIcon || '🔗',
      name: this.newSceneName.trim(),
      description: this.newSceneDesc.trim() || '自定义联动场景',
      devices: this.getSelectedDeviceNames(),
      active: true,
      isBuiltin: false
    };
    this.scenes = [...this.scenes, newScene];
    this.showAddForm = false;
    this.newSceneName = '';
    this.newSceneDesc = '';
    this.newSceneIcon = '🔗';
    this.selectedDeviceIds = [];
  }

  private handleDeleteScene(sceneId: number): void {
    this.scenes = this.scenes.filter((s: SceneItem) => s.id !== sceneId);
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('联动场景')
          .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
        Blank()
        Text('+ 新建')
          .fontSize(AppFonts.BODY).fontColor(AppColors.PRIMARY)
          .onClick(() => {
            this.showAddForm = !this.showAddForm;
          })
      }
      .width('100%').padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 8 })

      Scroll() {
        Column({ space: AppSizes.CARD_GAP }) {
          GlassCard() {
            Row({ space: 12 }) {
              Text('📡').fontSize(24).width(44).height(44)
                .textAlign(TextAlign.Center)
                .backgroundColor(AppColors.SECONDARY_10).borderRadius(22)
              Column({ space: 2 }) {
                Text('可联动设备')
                  .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.TEXT_PRIMARY)
                Text(`${this.getTotalAvailableCount()}台设备可用`)
                  .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text(`${this.scenes.filter((s: SceneItem) => s.active).length}个活跃`)
                .fontSize(AppFonts.CAPTION).fontColor(AppColors.SUCCESS)
                .backgroundColor(AppColors.SUCCESS_10)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(10)
            }
            .width('100%')
          }

          if (this.bondDevices.length > 0) {
            GlassCard() {
              Column({ space: 8 }) {
                Text('已绑定设备')
                  .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
                  .width('100%')
                Text(this.getBondDeviceNames())
                  .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY)
                  .width('100%')
              }
            }
          }

          if (this.showAddForm) {
            GlassCard() {
              Column({ space: 12 }) {
                Text('新建联动场景')
                  .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.TEXT_PRIMARY).width('100%')

                Row({ space: 8 }) {
                  Text('名称')
                    .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY).width(40)
                  TextInput({ text: this.newSceneName, placeholder: '请输入场景名称' })
                    .fontSize(AppFonts.BODY).layoutWeight(1).height(36)
                    .backgroundColor('#F9FAFB').borderRadius(8)
                    .onChange((value: string) => {
                      this.newSceneName = value;
                    })
                }

                Row({ space: 8 }) {
                  Text('描述')
                    .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY).width(40)
                  TextInput({ text: this.newSceneDesc, placeholder: '请输入场景描述' })
                    .fontSize(AppFonts.BODY).layoutWeight(1).height(36)
                    .backgroundColor('#F9FAFB').borderRadius(8)
                    .onChange((value: string) => {
                      this.newSceneDesc = value;
                    })
                }

                Text('场景图标')
                  .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
                Row({ space: 8 }) {
                  ForEach(this.iconOptions, (icon: string) => {
                    Text(icon)
                      .fontSize(22).width(36).height(36)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(this.newSceneIcon === icon ? AppColors.PRIMARY_10 : '#F9FAFB')
                      .borderRadius(8)
                      .border({
                        width: this.newSceneIcon === icon ? 1.5 : 0,
                        color: AppColors.PRIMARY
                      })
                      .onClick(() => {
                        this.newSceneIcon = icon;
                      })
                  })
                }
                .width('100%')

                Text('关联设备（可多选）')
                  .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
                if (this.bondDevices.length === 0) {
                  Text('暂无已绑定设备，请先在设备管理中添加设备')
                    .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_HINT)
                } else {
                  Column({ space: 6 }) {
                    ForEach(this.bondDevices, (device: DeviceEntity) => {
                      Row({ space: 8 }) {
                        Text(device.iconSymbol).fontSize(18).width(32).height(32)
                          .textAlign(TextAlign.Center)
                          .backgroundColor(AppColors.PRIMARY_10).borderRadius(16)
                        Text(device.name)
                          .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY)
                          .layoutWeight(1)
                        Text(this.selectedDeviceIds.indexOf(device.id) >= 0 ? '✓' : '')
                          .fontSize(16).fontColor(AppColors.PRIMARY)
                          .width(24).height(24)
                          .textAlign(TextAlign.Center)
                      }
                      .width('100%').padding(8)
                      .backgroundColor(
                        this.selectedDeviceIds.indexOf(device.id) >= 0 ? AppColors.PRIMARY_10 : '#F9FAFB'
                      )
                      .borderRadius(8)
                      .onClick(() => {
                        this.toggleDeviceSelection(device.id);
                      })
                    })
                  }
                }

                Row({ space: 12 }) {
                  Button('取消')
                    .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
                    .backgroundColor('#F3F4F6').borderRadius(20).height(36).layoutWeight(1)
                    .onClick(() => {
                      this.showAddForm = false;
                      this.newSceneName = '';
                      this.newSceneDesc = '';
                      this.newSceneIcon = '🔗';
                      this.selectedDeviceIds = [];
                    })
                  Button('确认创建')
                    .fontSize(AppFonts.BODY).fontColor(Color.White)
                    .backgroundColor(AppColors.PRIMARY).borderRadius(20).height(36).layoutWeight(1)
                    .onClick(() => {
                      this.handleAddScene();
                    })
                }
                .width('100%')
              }
            }
          }

          ForEach(this.scenes, (item: SceneItem) => {
            Column() {
              GlassCard() {
                Column({ space: 8 }) {
                  Row({ space: 12 }) {
                    Text(item.icon).fontSize(28).width(48).height(48)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(item.active ? AppColors.SUCCESS_10 : AppColors.DIVIDER)
                      .borderRadius(12)
                    Column({ space: 4 }) {
                      Row() {
                        Text(item.name)
                          .fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold)
                          .fontColor(AppColors.TEXT_PRIMARY)
                        Blank()
                        StatusBadge({ label: item.active ? '已激活' : '未激活', isOnline: item.active })
                      }
                      .width('100%')
                      Text(item.description)
                        .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text('联动设备：' + item.devices)
                        .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
                    }
                    .alignItems(HorizontalAlign.Start).layoutWeight(1)
                  }
                  .width('100%')

                  Row() {
                    if (!item.isBuiltin) {
                      Text('🗑️ 删除')
                        .fontSize(AppFonts.CAPTION).fontColor(AppColors.DANGER)
                        .onClick(() => {
                          this.handleDeleteScene(item.id);
                        })
                    } else {
                      Blank()
                    }
                    Text(item.active ? '点击停用' : '点击激活')
                      .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_HINT)
                  }
                  .width('100%')
                }
              }
            }
            .onClick(() => {
              item.active = !item.active;
            })
          })
        }
        .width('100%')
        .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 12, bottom: 16 })
      }
      .scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BG_PAGE)
  }
}
