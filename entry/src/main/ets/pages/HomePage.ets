import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard, StatusBadge } from '../components/CommonComponents';
import { FeedingStatus, FeedingRecordType } from '../models/DataModels';
import type { ActivityData, FeederStatus, FeedingPlan, FeedingRecord, LocationInfo } from '../models/DataModels';
import { PetService } from '../services/PetService';
import type { PetEntity } from '../services/PetService';
import { MotionService } from '../services/MotionService';
import { FeedService } from '../services/FeedService';
import type { FeedEntity } from '../services/FeedService';
import { DeviceDiscoveryService, DiscoveredDevice } from '../services/DeviceDiscoveryService';
// import { CollarHardwareService } from '../services/CollarHardwareService';
// import { FeederHardwareService } from '../services/FeederHardwareService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'HomePage';

@Component
export struct HomePage {
  @StorageProp('currentPetId') currentPetId: number = -1;
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;

  @State private petName: string = '--';
  @State private petBreed: string = '--';
  @State private petWeight: string = '--';
  @State private isCollarOnline: boolean = false;
  @State private deviceCount: number = 0;

  @State private location: LocationInfo = {
    address: '等待定位中...',
    distance: '--',
    description: '未连接项圈',
    updateTime: '--'
  };

  @State private activity: ActivityData = {
    steps: 0, distance: 0, calories: 0,
    goalPercent: 0, goalSteps: 8000, comparedYesterday: '--'
  };

  @State private feeder: FeederStatus = {
    foodRemaining: 0, foodCapacity: 200,
    waterRemaining: 0, waterCapacity: 500,
    nextMealTime: '--:--', isAdaptiveEnabled: false
  };

  // 硬件控制状态
  @State private isFindingPet: boolean = false;
  @State private isAudioTalking: boolean = false;
  @State private collarDevices: DiscoveredDevice[] = [];
  @State private feederDevices: DiscoveredDevice[] = [];

  @State private feedingPlans: FeedingPlan[] = [
    { time: '08:00', label: '早餐', amount: 30, unit: 'g', status: FeedingStatus.PENDING },
    { time: '12:30', label: '午餐', amount: 25, unit: 'g', status: FeedingStatus.PENDING },
    { time: '18:30', label: '晚餐', amount: 35, unit: 'g', status: FeedingStatus.PENDING }
  ];

  @State private feedingRecords: FeedingRecord[] = [];

  aboutToAppear(): void {
    this.loadPetData();
    this.loadHardwareDevices();
  }

  private async loadPetData(): Promise<void> {
    if (!this.isLoggedIn || this.currentPetId <= 0) {
      return;
    }
    try {
      // 加载宠物信息
      const pet: PetEntity | null = await PetService.getPetById(this.currentPetId);
      if (pet) {
        this.petName = pet.name;
        this.petBreed = `${pet.breed || '未知'}·${pet.age > 0 ? pet.age + '岁' : ''}`;
        this.petWeight = `${pet.weight > 0 ? pet.weight + 'kg' : '--'} · ${pet.gender} · ${pet.vaccineStatus === 'done' ? '疫苗齐全' : '疫苗待补'}`;
      }
      // 加载运动数据
      const motion = await MotionService.getTodayRecord(this.currentPetId);
      if (motion) {
        this.activity = {
          steps: motion.steps,
          distance: motion.distance,
          calories: motion.calories,
          goalPercent: motion.goalSteps > 0 ? Math.round(motion.steps / motion.goalSteps * 100) : 0,
          goalSteps: motion.goalSteps,
          comparedYesterday: '--'
        };
      }
      // 加载喂食记录
      const feeds: FeedEntity[] = await FeedService.getTodayRecords(this.currentPetId);
      this.feedingRecords = feeds.map((f: FeedEntity): FeedingRecord => ({
        time: f.feedTime.split('T').length > 1 ? f.feedTime.split('T')[1].substring(0, 5) : f.feedTime,
        type: f.feedType as FeedingRecordType,
        label: f.label || f.feedType,
        amount: `${f.amount}${f.unit}`,
        isHighlight: f.isHighlight
      }));
      // 设备数量
      this.deviceCount = DeviceDiscoveryService.getDeviceCount();
    } catch (err) {
      hilog.error(0x0000, TAG, `Load pet data failed: ${JSON.stringify(err)}`);
    }
  }

  private loadHardwareDevices(): void {
    try {
      // 获取智能项圈设备
      this.collarDevices = DeviceDiscoveryService.getCollarDevices();
      // 获取智能喂食器设备
      this.feederDevices = DeviceDiscoveryService.getFeederDevices();

      // 更新项圈在线状态
      this.isCollarOnline = this.collarDevices.length > 0;

      hilog.info(0x0000, TAG, `Found ${this.collarDevices.length} collar devices and ${this.feederDevices.length} feeder devices`);
    } catch (err) {
      hilog.error(0x0000, TAG, `Load hardware devices failed: ${JSON.stringify(err)}`);
    }
  }

  // 一键寻宠功能
  private async handleFindPet(): Promise<void> {
    if (this.collarDevices.length === 0) {
      hilog.warn(0x0000, TAG, 'No collar devices available for find pet');
      return;
    }

    this.isFindingPet = true;
    try {
      // 发送寻宠命令
      // await CollarHardwareService.findPet();
      hilog.info(0x0000, TAG, 'Find pet command sent');
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(0x0000, TAG, `Find pet failed: ${errorMsg}`);
    } finally {
      this.isFindingPet = false;
    }
  }

  // 语音对讲功能
  private async handleAudioTalk(): Promise<void> {
    if (this.collarDevices.length === 0) {
      hilog.warn(0x0000, TAG, 'No collar devices available for audio talk');
      return;
    }

    this.isAudioTalking = true;
    try {
      // 开始语音对讲
      const deviceId = this.collarDevices[0].deviceId;
      // await CollarHardwareService.startAudioTalk(deviceId);
      hilog.info(0x0000, TAG, `Audio talk started with device ${deviceId}`);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(0x0000, TAG, `Audio talk failed: ${errorMsg}`);
    } finally {
      this.isAudioTalking = false;
    }
  }

  // 手动投喂功能
  private async handleManualFeedWithHardware(): Promise<void> {
    if (this.feederDevices.length === 0) {
      hilog.warn(0x0000, TAG, 'No feeder devices available for manual feed');
      return;
    }

    try {
      // 发送投喂命令到第一个喂食器设备
      const deviceId = this.feederDevices[0].deviceId;
      // await FeederHardwareService.feed(30); // 默认30克
      hilog.info(0x0000, TAG, `Manual feed command sent to device ${deviceId}`);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(0x0000, TAG, `Manual feed failed: ${errorMsg}`);
    }
  }

  @Builder
  private buildNavBar() {
    Row() {
      Row({ space: 8 }) {
        Text('\u26A1').fontSize(24)
        Text('宠联中枢')
          .fontSize(AppFonts.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      Blank()
      Row({ space: 8 }) {
        Row({ space: 4 }) {
          Text('\uD83D\uDCE1').fontSize(12)
          Text(`${this.deviceCount}台设备`)
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#F3F4F6')
        .borderRadius(20)
        Image($r('app.media.ohos_ic_public_ring'))
          .width(22).height(22)
          .fillColor(AppColors.TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding({ left: 4, right: 4, bottom: 8 })
  }

  @Builder
  private buildPetInfoCard() {
    GlassCard() {
      Row({ space: 12 }) {
        Stack() {
          Image($r('app.media.pet_avatar'))
            .width(56).height(56).borderRadius(28)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: Color.White })
          Circle().width(12).height(12)
            .fill(this.isCollarOnline ? AppColors.SUCCESS : AppColors.TEXT_HINT)
            .stroke(Color.White).strokeWidth(2)
            .position({ x: 42, y: 42 })
        }.width(56).height(56)
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.petName)
              .fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
            Text(this.petBreed)
              .fontSize(11).fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.PRIMARY_10)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
          }
          Text(this.petWeight)
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
        }.alignItems(HorizontalAlign.Start)
      }
    }
  }

  @Builder
  private buildCollarCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Row({ space: 6 }) {
            Text('\uD83D\uDC15').fontSize(18)
            Text('智能项圈').fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            StatusBadge({ label: this.isCollarOnline ? '在线' : '离线', isOnline: this.isCollarOnline })
          }
          Blank()
          Text('更新于' + this.location.updateTime)
            .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
        }.width('100%')

        // 地图占位
        Column() {
          Text('🗺️ 地图区域')
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%').height(144)
        .borderRadius(16)
        .backgroundColor('#F3F4F6')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text('📍 ' + this.location.address)
            .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.location.distance + ' · ' + this.location.description)
            .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%').alignItems(HorizontalAlign.Start)

        Grid() {
          GridItem() {
            Column({ space: 4 }) {
              Image($r('sys.media.ohos_ic_public_search_filled')).width(20).height(20).fillColor(AppColors.PRIMARY)
              Text('一键寻宠').fontSize(11).fontColor(AppColors.TEXT_PRIMARY)
            }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(AppColors.PRIMARY_10).borderRadius(12)
            .onClick(() => {
              this.handleFindPet();
            })
          }
          GridItem() {
            Column({ space: 4 }) {
              Image($r('sys.media.ohos_ic_public_voice')).width(20).height(20).fillColor(AppColors.SECONDARY)
              Text('语音对讲').fontSize(11).fontColor(AppColors.TEXT_PRIMARY)
            }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(AppColors.SECONDARY_10).borderRadius(12)
            .onClick(() => {
              this.handleAudioTalk();
            })
          }
          GridItem() { this.buildActionBtn($r('app.media.ohos_ic_public_gps'), '历史轨迹', '#F3F4F6', AppColors.TEXT_SECONDARY) }
          GridItem() { this.buildActionBtn($r('app.media.ohos_ic_public_shield'), '电子围栏', '#F3F4F6', AppColors.TEXT_SECONDARY) }
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(8).width('100%').height(64)

        Divider().color(AppColors.DIVIDER)

        Column({ space: 8 }) {
          Row() {
            Text('🏃 今日运动').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            Text('目标 ' + this.activity.goalSteps + '步').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
          }.width('100%')
          Row({ space: 16 }) {
            Stack() {
              Progress({ value: this.activity.goalPercent, total: 100, type: ProgressType.Ring })
                .width(76).height(76).color(AppColors.PRIMARY).backgroundColor('#E8E8E8').style({ strokeWidth: 6 })
              Column() {
                Text(this.activity.goalPercent.toString()).fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
                Text('%').fontSize(10).fontColor(AppColors.TEXT_HINT)
              }
            }.width(76).height(76)
            Row({ space: 4 }) {
              this.buildStatCell(this.formatSteps(this.activity.steps), '步数')
              this.buildStatCell(this.activity.distance.toString(), '公里')
              this.buildStatCell(this.activity.calories.toString(), '千卡')
            }.layoutWeight(1)
          }.width('100%')
          Text('📈 较昨日 ' + this.activity.comparedYesterday)
            .fontSize(AppFonts.SMALL).fontColor(AppColors.SUCCESS)
        }
      }
    }
  }

  @Builder
  private buildFeederCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Row({ space: 6 }) {
            Text('🍽️').fontSize(18)
            Text('智能喂食器').fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            StatusBadge({ label: '在线', isOnline: true })
          }
          Blank()
          Text('下一餐 ' + this.feeder.nextMealTime).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
        }.width('100%')

        Row() {
          Column({ space: 4 }) {
            Stack() {
              Progress({ value: this.feeder.foodRemaining, total: this.feeder.foodCapacity, type: ProgressType.Ring })
                .width(76).height(76).color(AppColors.PRIMARY).backgroundColor('#E8E8E8').style({ strokeWidth: 6 })
              Column() {
                Row() {
                  Text(this.feeder.foodRemaining.toString()).fontSize(18).fontWeight(FontWeight.Bold)
                  Text('g').fontSize(10).fontColor(AppColors.TEXT_HINT)
                }
                Text('余粮').fontSize(10).fontColor(AppColors.TEXT_HINT)
              }
            }
            Text('容量' + this.feeder.foodCapacity + 'g').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
          }.layoutWeight(1)
          Column({ space: 4 }) {
            Stack() {
              Progress({ value: this.feeder.waterRemaining, total: this.feeder.waterCapacity, type: ProgressType.Ring })
                .width(76).height(76).color(AppColors.SECONDARY).backgroundColor('#E8E8E8').style({ strokeWidth: 6 })
              Column() {
                Row() {
                  Text(this.feeder.waterRemaining.toString()).fontSize(18).fontWeight(FontWeight.Bold)
                  Text('ml').fontSize(10).fontColor(AppColors.TEXT_HINT)
                }
                Text('水量').fontSize(10).fontColor(AppColors.TEXT_HINT)
              }
            }
            Text('容量' + this.feeder.waterCapacity + 'ml').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
          }.layoutWeight(1)
        }.width('100%')

        Column({ space: 8 }) {
          Row() {
            Text('📅 今日喂食计划').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
            Blank()
            if (this.feeder.isAdaptiveEnabled) {
              Text('运动自适应开启').fontSize(AppFonts.SMALL).fontColor(AppColors.PRIMARY)
                .backgroundColor('rgba(255,255,255,0.8)')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(10)
            }
          }.width('100%')
          ForEach(this.feedingPlans, (plan: FeedingPlan) => {
            Row() {
              Text(plan.time + ' ' + plan.label).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
              Blank()
              Row({ space: 4 }) {
                Text(plan.amount + plan.unit + (plan.note ? ' (预估)' : '')).fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                Text(this.getFeedingStatusText(plan.status)).fontSize(AppFonts.SMALL).fontColor(this.getFeedingStatusColor(plan.status))
              }
            }.width('100%')
          })
        }
        .width('100%').padding(12).borderRadius(12)
        .linearGradient({ angle: 90, colors: [['rgba(255,159,67,0.05)', 0], ['rgba(0,180,216,0.05)', 1]] })

        Row({ space: 12 }) {
          Button('立即加餐').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
            .fontColor(Color.White).backgroundColor(AppColors.PRIMARY)
            .borderRadius(AppSizes.BTN_RADIUS).height(44).layoutWeight(1)
            .shadow({ radius: 8, color: 'rgba(255,159,67,0.25)', offsetY: 2 })
            .onClick(() => { this.handleManualFeedWithHardware(); })
          Button('自定义投喂').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY).backgroundColor(Color.White)
            .borderRadius(AppSizes.BTN_RADIUS).borderWidth(1).borderColor(AppColors.BORDER)
            .height(44).layoutWeight(1)
        }.width('100%')

        Column({ space: 8 }) {
          Row() {
            Text('📋 今日记录').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            Text('全部 >').fontSize(AppFonts.SMALL).fontColor(AppColors.PRIMARY)
          }.width('100%')
          if (this.feedingRecords.length === 0) {
            Text('暂无喂食记录').fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_HINT).width('100%')
          } else {
            ForEach(this.feedingRecords, (record: FeedingRecord) => {
              Row() {
                Text(this.getRecordIcon(record.type)).fontSize(14)
                Text(record.time + ' ' + record.label).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
                Blank()
                Text(record.amount).fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                  .fontColor(record.isHighlight ? AppColors.SECONDARY : AppColors.TEXT_PRIMARY)
              }.width('100%').padding(8).backgroundColor('rgba(255,255,255,0.5)').borderRadius(8)
            })
          }
        }
      }
    }
  }

  private async handleManualFeed(): Promise<void> {
    if (this.currentPetId <= 0) { return; }
    try {
      await FeedService.addRecord(this.currentPetId, {
        feedType: 'manual',
        amount: 30,
        unit: 'g',
        label: '手动加餐'
      });
      await this.loadPetData();
    } catch (err) {
      hilog.error(0x0000, TAG, `Manual feed failed: ${JSON.stringify(err)}`);
    }
  }

  @Builder
  private buildOtherDevices() {
    GlassCard() {
      Column({ space: 8 }) {
        Row() {
          Text('其他设备').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text(`${this.deviceCount}台在线`).fontSize(AppFonts.SMALL).fontColor(AppColors.PRIMARY)
        }.width('100%')
        Scroll() {
          Row({ space: 16 }) {
            this.buildDeviceIcon('💧', '#EFF6FF', '饮水机')
            this.buildDeviceIcon('🚽', '#F0FDF4', '猫砂盆')
            this.buildDeviceIcon('📹', '#FAF5FF', '摄像头')
            this.buildDeviceIcon('🌡️', '#FFF7ED', '温湿度计')
            this.buildDeviceIcon('➕', '#F3F4F6', '添加')
          }
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      }
    }
  }

  @Builder
  private buildLinkageBar() {
    Row({ space: 8 }) {
      Text('🔗').fontSize(14)
      Text('分布式联动已激活 · 今日运动奖励已触发1次')
        .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
      Text('✅').fontSize(14)
    }
    .width('100%').padding(12)
    .backgroundColor(AppColors.CARD_BG).borderRadius(16)
    .border({ width: 0.5, color: 'rgba(255,159,67,0.2)' })
    .linearGradient({ angle: 90, colors: [['rgba(255,159,67,0.1)', 0], ['rgba(0,180,216,0.1)', 1]] })
  }

  @Builder
  private buildActionBtn(icon: Resource, label: string, bgColor: string, iconColor: string) {
    Column({ space: 4 }) {
      Image(icon).width(20).height(20).fillColor(iconColor)
      Text(label).fontSize(11).fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(bgColor).borderRadius(12)
  }

  @Builder
  private buildStatCell(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text(label).fontSize(10).fontColor(AppColors.TEXT_HINT)
    }
    .layoutWeight(1).padding(6)
    .backgroundColor('rgba(255,255,255,0.6)').borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildDeviceIcon(emoji: string, bgColor: string, label: string) {
    Column({ space: 4 }) {
      Text(emoji).fontSize(24).width(48).height(48)
        .textAlign(TextAlign.Center).backgroundColor(bgColor).borderRadius(24)
      Text(label).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_PRIMARY)
    }.alignItems(HorizontalAlign.Center)
  }

  private formatSteps(steps: number): string {
    return steps >= 1000 ? (steps / 1000).toFixed(1) + 'k' : steps.toString();
  }

  private getFeedingStatusText(status: FeedingStatus): string {
    switch (status) {
      case FeedingStatus.COMPLETED: return '已完成';
      case FeedingStatus.PENDING: return '待执行';
      case FeedingStatus.ADAPTIVE: return '将根据运动调整';
      default: return '';
    }
  }

  private getFeedingStatusColor(status: FeedingStatus): string {
    switch (status) {
      case FeedingStatus.COMPLETED: return AppColors.SUCCESS;
      case FeedingStatus.PENDING: return AppColors.WARNING;
      default: return AppColors.TEXT_HINT;
    }
  }

  private getRecordIcon(type: FeedingRecordType): string {
    switch (type) {
      case FeedingRecordType.SCHEDULED: return '⏰';
      case FeedingRecordType.EXERCISE_REWARD: return '⚡';
      case FeedingRecordType.MANUAL: return '👆';
      default: return '📌';
    }
  }

  build() {
    Scroll() {
      Column({ space: AppSizes.CARD_GAP }) {
        this.buildNavBar()
        this.buildPetInfoCard()
        this.buildCollarCard()
        this.buildFeederCard()
        this.buildOtherDevices()
        this.buildLinkageBar()
      }
      .width('100%')
      .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 16 })
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BG_PAGE)
  }
}
