// 健康档案页面 — 宠物健康数据展示与记录添加
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { VaccineStatus } from '../models/DataModels';
import type { HealthData, VaccineRecord, MedicalRecord, WeeklyActivity } from '../models/DataModels';
import { PetService } from '../services/PetService';
import type { PetEntity } from '../services/PetService';
import { MotionService } from '../services/MotionService';
import type { MotionEntity } from '../services/MotionService';
import { HealthService } from '../services/HealthService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'HealthPage';

// ==========================================================================
// 对话框 — 添加体重
// ==========================================================================
@CustomDialog
struct WeightDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: WeightDialog() });
  petId: number = -1;
  onSaved?: () => void;

  @State private weightValue: string = '';

  build() {
    Column({ space: 16 }) {
      Text('记录体重')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      TextInput({ placeholder: '输入体重(kg)，如 18.5' })
        .type(InputType.Normal)
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => {
          // 仅允许数字和1个小数点，最多1位小数
          let cleaned = value.replace(/[^0-9.]/g, '');
          // 阻止多个小数点
          const dotIdx = cleaned.indexOf('.');
          if (dotIdx >= 0) {
            cleaned = cleaned.substring(0, dotIdx + 1) + cleaned.substring(dotIdx + 1).replace(/\./g, '');
          }
          // 小数点后最多1位
          const parts = cleaned.split('.');
          if (parts.length > 1 && parts[1].length > 1) {
            cleaned = parts[0] + '.' + parts[1].substring(0, 1);
          }
          this.weightValue = cleaned;
        })
        .width('100%')
      Row({ space: 12 }) {
        Button('取消').fontColor(AppColors.TEXT_SECONDARY).backgroundColor(AppColors.DIVIDER)
          .onClick(() => { this.controller.close(); })
        Button('保存').fontColor(Color.White).backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            const w = parseFloat(this.weightValue);
            if (w > 0 && this.petId > 0) {
              const rounded = Math.round(w * 10) / 10;
              HealthService.addWeightRecord(this.petId, rounded).then(() => {
                PetService.updatePet(this.petId, { weight: rounded } as Partial<PetEntity>).then(() => {
                  if (this.onSaved) { this.onSaved(); }
                  this.controller.close();
                }).catch((err: Error) => {
                  hilog.error(0x0000, TAG, `Update weight failed: ${err.message}`);
                  this.controller.close();
                });
              }).catch((err: Error) => {
                hilog.error(0x0000, TAG, `Add weight failed: ${err.message}`);
                this.controller.close();
              });
            }
          })
      }.width('100%')
    }.padding(24)
  }
}

// ==========================================================================
// 对话框 — 添加疫苗
// ==========================================================================
@CustomDialog
struct VaccineDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: VaccineDialog() });
  petId: number = -1;
  onSaved?: () => void;

  @State private vName: string = '';
  @State private vDate: string = '';

  build() {
    Column({ space: 16 }) {
      Text('添加疫苗记录')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      TextInput({ placeholder: '疫苗名称，如 狂犬疫苗' })
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => { this.vName = value; })
        .width('100%')
      TextInput({ placeholder: '接种日期，如 2026-06-01' })
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => { this.vDate = value; })
        .width('100%')
      Row({ space: 12 }) {
        Button('取消').fontColor(AppColors.TEXT_SECONDARY).backgroundColor(AppColors.DIVIDER)
          .onClick(() => { this.controller.close(); })
        Button('保存').fontColor(Color.White).backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            if (this.vName.length > 0 && this.petId > 0) {
              HealthService.addVaccineRecord(this.petId, this.vName, this.vDate).then(() => {
                if (this.onSaved) { this.onSaved(); }
              }).catch((err: Error) => { hilog.error(0x0000, TAG, `Add vaccine failed: ${err.message}`); });
              this.controller.close();
            }
          })
      }.width('100%')
    }.padding(24)
  }
}

// ==========================================================================
// 对话框 — 添加就诊记录
// ==========================================================================
@CustomDialog
struct MedicalDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: MedicalDialog() });
  petId: number = -1;
  onSaved?: () => void;

  @State private mTitle: string = '';
  @State private mDate: string = '';
  @State private mDesc: string = '';
  @State private mHospital: string = '';

  build() {
    Column({ space: 14 }) {
      Text('添加就诊记录')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      TextInput({ placeholder: '就诊标题，如 年度体检' })
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => { this.mTitle = value; })
        .width('100%')
      TextInput({ placeholder: '就诊日期，如 2026-05-15' })
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => { this.mDate = value; })
        .width('100%')
      TextInput({ placeholder: '病情描述（可选）' })
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => { this.mDesc = value; })
        .width('100%')
      TextInput({ placeholder: '就诊医院（可选）' })
        .placeholderColor(AppColors.TEXT_HINT)
        .onChange((value: string) => { this.mHospital = value; })
        .width('100%')
      Row({ space: 12 }) {
        Button('取消').fontColor(AppColors.TEXT_SECONDARY).backgroundColor(AppColors.DIVIDER)
          .onClick(() => { this.controller.close(); })
        Button('保存').fontColor(Color.White).backgroundColor(AppColors.PRIMARY)
          .onClick(() => {
            if (this.mTitle.length > 0 && this.petId > 0) {
              HealthService.addMedicalRecord(this.petId, this.mTitle, this.mDate, this.mDesc, this.mHospital)
                .then(() => { if (this.onSaved) { this.onSaved(); } })
                .catch((err: Error) => { hilog.error(0x0000, TAG, `Add medical failed: ${err.message}`); });
              this.controller.close();
            }
          })
      }.width('100%')
    }.padding(24)
  }
}

// ==========================================================================
// 主页面
// ==========================================================================
@Component
export struct HealthPage {
  @StorageProp('currentPetId') @Watch('onPetChanged') currentPetId: number = -1;
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('healthRefreshKey') @Watch('onHealthTabRefresh') healthRefreshKey: number = 0;

  @State private petName: string = '--';
  @State private petBreedInfo: string = '--';
  @State private health: HealthData = { weight: 0, temperature: 0 };
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

  @State private vaccines: VaccineRecord[] = [];
  @State private medicals: MedicalRecord[] = [];

  private weightDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: WeightDialog({ petId: this.currentPetId, onSaved: () => { this.loadData(); } }),
    autoCancel: true,
  });
  private vaccineDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: VaccineDialog({ petId: this.currentPetId, onSaved: () => { this.loadData(); } }),
    autoCancel: true,
  });
  private medicalDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: MedicalDialog({ petId: this.currentPetId, onSaved: () => { this.loadData(); } }),
    autoCancel: true,
  });

  aboutToAppear(): void {
    this.loadData();
  }

  onPetChanged(): void {
    if (this.currentPetId > 0) {
      this.loadData();
    }
  }

  onHealthTabRefresh(): void {
    if (this.currentPetId > 0) {
      this.loadData();
    }
  }

  private async loadData(): Promise<void> {
    if (!this.isLoggedIn || this.currentPetId <= 0) {
      return;
    }
    const pid = this.currentPetId;
    try {
      // 宠物基本信息
      const pet: PetEntity | null = await PetService.getPetById(pid);
      if (pet) {
        this.petName = pet.name;
        this.petBreedInfo = `${pet.breed || '未知'} · ${pet.age > 0 ? pet.age + '岁' : '年龄未知'} · ${pet.gender}`;
        // 从 weight_record 表取最新体重，确保与宠物管理页一致
        const latestWeights = await HealthService.getWeightRecords(pid, 1);
        const currentWeight = latestWeights.length > 0 ? latestWeights[0].weight : pet.weight;
        this.health = { weight: currentWeight, temperature: pet.temperature };
        this.isNeutered = pet.isNeutered;
      }
      // 运动数据
      const motionRecords: MotionEntity[] = await MotionService.getRecentRecords(pid, 7);
      const dayLabels: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '今天'];
      const updatedWeekly: WeeklyActivity[] = dayLabels.map((day: string, index: number): WeeklyActivity => {
        const record = motionRecords.length > index ? motionRecords[motionRecords.length - 1 - index] : null;
        const goalSteps = record ? record.goalSteps : 8000;
        const pct = record && goalSteps > 0 ? Math.min(100, Math.round(record.steps / goalSteps * 100)) : 0;
        return { day: day, percent: pct, isToday: index === 6 };
      });
      this.weeklyData = updatedWeekly;
      // 疫苗记录
      this.vaccines = await HealthService.getVaccineRecords(pid);
      // 就诊记录
      this.medicals = await HealthService.getMedicalRecords(pid);
    } catch (err) {
      hilog.error(0x0000, TAG, `Load health data failed: ${JSON.stringify(err)}`);
    }
  }

  // ==========================================================================
  // 宠物健康卡片（体重+体温，可点体重添加记录）
  // ==========================================================================
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
          GridItem() {
            // 体重 — 可点击弹出添加对话框
            Column({ space: 4 }) {
              Text(this.health.weight > 0 ? this.health.weight.toFixed(1) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
              Row({ space: 2 }) {
                Text('体重(kg)')
                Text('✎')
                  .fontSize(10).fontColor(AppColors.TEXT_HINT)
              }
            }
            .width('100%').padding(12).backgroundColor(AppColors.PRIMARY_10).borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.weightDialogCtrl = new CustomDialogController({
                builder: WeightDialog({ petId: this.currentPetId, onSaved: () => { this.loadData(); } }),
                autoCancel: true,
              });
              this.weightDialogCtrl.open();
            })
          }
          GridItem() {
            this.buildHealthMetric(this.health.temperature > 0 ? this.health.temperature.toString() : '--', '体温(°C)', AppColors.SECONDARY_10)
          }
        }
        .columnsTemplate('1fr 1fr').columnsGap(10).width('100%')
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

  // ==========================================================================
  // 本周运动趋势
  // ==========================================================================
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

  // ==========================================================================
  // 疫苗接种记录 — 可添加、可切换状态
  // ==========================================================================
  @Builder
  private buildVaccineCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Text('💉 疫苗接种记录')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text('＋ 添加')
            .fontSize(13).fontColor(AppColors.PRIMARY)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .border({ width: 1, color: AppColors.PRIMARY, style: BorderStyle.Dashed }).borderRadius(12)
            .onClick(() => {
              this.vaccineDialogCtrl = new CustomDialogController({
                builder: VaccineDialog({ petId: this.currentPetId, onSaved: () => { this.loadData(); } }),
                autoCancel: true,
              });
              this.vaccineDialogCtrl.open();
            })
        }
        if (this.vaccines.length === 0) {
          Text('暂无疫苗记录，点击右上角添加')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT).width('100%').padding(8)
        }
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
          .onClick(() => {
            // 点击切换状态
            if (v.id) {
              const newStatus = v.status === VaccineStatus.DONE ? VaccineStatus.PENDING : VaccineStatus.DONE;
              HealthService.updateVaccineStatus(v.id, newStatus).then(() => {
                this.loadData();
              }).catch((err: Error) => { hilog.error(0x0000, TAG, `Toggle vaccine failed: ${err.message}`); });
            }
          })
        })
      }
    }
  }

  // ==========================================================================
  // 就诊记录 — 可添加
  // ==========================================================================
  @Builder
  private buildMedicalCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Text('🏥 就诊记录')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text('＋ 添加')
            .fontSize(13).fontColor(AppColors.PRIMARY)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .border({ width: 1, color: AppColors.PRIMARY, style: BorderStyle.Dashed }).borderRadius(12)
            .onClick(() => {
              this.medicalDialogCtrl = new CustomDialogController({
                builder: MedicalDialog({ petId: this.currentPetId, onSaved: () => { this.loadData(); } }),
                autoCancel: true,
              });
              this.medicalDialogCtrl.open();
            })
        }
        if (this.medicals.length === 0) {
          Text('暂无就诊记录，点击右上角添加')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT).width('100%').padding(8)
        } else {
          ForEach(this.medicals, (m: MedicalRecord) => {
            Column({ space: 6 }) {
              Row() {
                Text(m.title).fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                Blank()
                Text(m.date).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
              }.width('100%')
              if (m.description.length > 0) {
                Text(m.description).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
              }
              if (m.hospital.length > 0) {
                Text(m.hospital).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
              }
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
