// 健康档案页面 — 从数据库读取宠物健康/运动数据
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { VaccineStatus } from '../models/DataModels';
import type { HealthData, VaccineRecord, MedicalRecord, WeeklyActivity } from '../models/DataModels';
import { PetService } from '../services/PetService';
import type { PetEntity } from '../services/PetService';
import { MotionService } from '../services/MotionService';
import type { MotionEntity } from '../services/MotionService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'HealthPage';

@Component
export struct HealthPage {
  @StorageProp('currentPetId') @Watch('onPetChanged') currentPetId: number = -1;
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;

  @State private petName: string = '--';
  @State private petBreedInfo: string = '--';
  @State private health: HealthData = { weight: 0, temperature: 0, heartRate: 0 };
  @State private isNeutered: boolean = false;

  @State private weeklyData: WeeklyActivity[] = [
    { day: '周一', percent: 0, isToday: false },
    { day: '周二', percent: 0, isToday: false },
    { day: '周三', percent: 0, isToday: false },
    { day: '周四', percent: 0, isToday: false },
    { day: '周五', percent: 0, isToday: false },
    { day: '周六', percent: 0, isToday: false },
    { day: '今天', percent: 0, isToday: true }
  ];

  @State private vaccines: VaccineRecord[] = [
    { name: '狂犬疫苗', date: '待记录', status: VaccineStatus.PENDING },
    { name: '六联疫苗', date: '待记录', status: VaccineStatus.PENDING },
    { name: '驱虫药', date: '待记录', status: VaccineStatus.PENDING }
  ];

  @State private medicals: MedicalRecord[] = [];

  aboutToAppear(): void {
    this.loadData();
  }

  // 当 currentPetId 变化时重新加载健康数据
  onPetChanged(): void {
    if (this.currentPetId > 0) {
      this.loadData();
    }
  }

  private async loadData(): Promise<void> {
    if (!this.isLoggedIn || this.currentPetId <= 0) {
      return;
    }
    try {
      // 加载宠物信息
      const pet: PetEntity | null = await PetService.getPetById(this.currentPetId);
      if (pet) {
        this.petName = pet.name;
        this.petBreedInfo = `${pet.breed || '未知'} · ${pet.age > 0 ? pet.age + '岁' : '年龄未知'} · ${pet.gender}`;
        this.health = {
          weight: pet.weight,
          temperature: pet.temperature,
          heartRate: pet.heartRate
        };
        this.isNeutered = pet.isNeutered;
      }
      // 加载最近7天运动数据
      const records: MotionEntity[] = await MotionService.getRecentRecords(this.currentPetId, 7);
      const dayLabels: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '今天'];
      const updatedWeekly: WeeklyActivity[] = dayLabels.map((day: string, index: number): WeeklyActivity => {
        const record = records.length > index ? records[records.length - 1 - index] : null;
        const goalSteps = record ? record.goalSteps : 8000;
        const percent = record && goalSteps > 0 ? Math.min(100, Math.round(record.steps / goalSteps * 100)) : 0;
        return { day: day, percent: percent, isToday: index === 6 };
      });
      this.weeklyData = updatedWeekly;
    } catch (err) {
      hilog.error(0x0000, TAG, `Load health data failed: ${JSON.stringify(err)}`);
    }
  }

  @Builder
  private buildPetHealthCard() {
    GlassCard() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Image($r('app.media.pet_avatar'))
            .width(64).height(64).borderRadius(32)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: Color.White })
          Column({ space: 4 }) {
            Text(this.petName)
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Text(this.petBreedInfo)
              .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
            Row({ space: 6 }) {
              Text('健康')
                .fontSize(AppFonts.SMALL).fontColor(AppColors.SUCCESS)
                .backgroundColor(AppColors.SUCCESS_10)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(10)
              if (this.isNeutered) {
                Text('已绝育')
                  .fontSize(AppFonts.SMALL).fontColor(AppColors.PRIMARY)
                  .backgroundColor(AppColors.PRIMARY_10)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(10)
              }
            }
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        Grid() {
          GridItem() { this.buildHealthMetric(this.health.weight > 0 ? this.health.weight.toString() : '--', '体重(kg)', AppColors.PRIMARY_10) }
          GridItem() { this.buildHealthMetric(this.health.temperature > 0 ? this.health.temperature.toString() : '--', '体温(°C)', AppColors.SECONDARY_10) }
          GridItem() { this.buildHealthMetric(this.health.heartRate > 0 ? this.health.heartRate.toString() : '--', '心率(bpm)', AppColors.SUCCESS_10) }
        }
        .columnsTemplate('1fr 1fr 1fr').columnsGap(10).width('100%')
      }
    }
  }

  @Builder
  private buildHealthMetric(value: string, label: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text(label).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%').padding(12).backgroundColor(bgColor).borderRadius(12)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildWeeklyChart() {
    GlassCard() {
      Column({ space: 12 }) {
        Text('📈 本周运动趋势')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
        Row({ space: 6 }) {
          ForEach(this.weeklyData, (item: WeeklyActivity) => {
            Column() {
              Blank()
              Column()
                .width('100%')
                .height(item.percent > 0 ? item.percent.toString() + '%' : '2%')
                .borderRadius({ topLeft: 6, topRight: 6 })
                .linearGradient({
                  angle: 180,
                  colors: item.isToday
                    ? [[AppColors.SECONDARY, 0], ['#93C5FD', 1]]
                    : [[AppColors.PRIMARY, 0], ['#FDBA74', 1]]
                })
              Text(item.day)
                .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY).margin({ top: 4 })
            }.layoutWeight(1).height(140).alignItems(HorizontalAlign.Center)
          })
        }.width('100%')
      }
    }
  }

  @Builder
  private buildVaccineCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Text('💉 疫苗接种记录')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
        ForEach(this.vaccines, (v: VaccineRecord) => {
          Row() {
            Column({ space: 2 }) {
              Text(v.name).fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
              Text(v.date).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Text(v.status === VaccineStatus.DONE ? '已接种' : '待接种')
              .fontSize(AppFonts.SMALL)
              .fontColor(v.status === VaccineStatus.DONE ? AppColors.SUCCESS : AppColors.WARNING)
              .backgroundColor(v.status === VaccineStatus.DONE ? AppColors.SUCCESS_10 : AppColors.WARNING_10)
              .padding({ left: 12, right: 12, top: 4, bottom: 4 }).borderRadius(12)
          }
          .width('100%').padding(12)
          .backgroundColor(v.status === VaccineStatus.DONE ? 'rgba(82,196,26,0.05)' : 'rgba(250,173,20,0.05)')
          .borderRadius(10)
        })
      }
    }
  }

  @Builder
  private buildMedicalCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Text('🏥 就诊记录')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
        if (this.medicals.length === 0) {
          Text('暂无就诊记录')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT).width('100%')
        } else {
          ForEach(this.medicals, (m: MedicalRecord) => {
            Column({ space: 6 }) {
              Row() {
                Text(m.title).fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                Blank()
                Text(m.date).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
              }.width('100%')
              Text(m.description).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
              Text(m.hospital).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
            }
            .width('100%').padding(12).backgroundColor('#F9FAFB').borderRadius(10)
          })
        }
      }
    }
  }

  build() {
    Scroll() {
      Column({ space: AppSizes.CARD_GAP }) {
        Row() {
          Text('健康档案')
            .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text('📅 查看历史')
            .fontSize(AppFonts.BODY).fontColor(AppColors.PRIMARY)
        }
        .width('100%').padding({ left: 4, right: 4, bottom: 4 })

        this.buildPetHealthCard()
        this.buildWeeklyChart()
        this.buildVaccineCard()
        this.buildMedicalCard()
      }
      .width('100%')
      .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 16 })
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BG_PAGE)
  }
}
