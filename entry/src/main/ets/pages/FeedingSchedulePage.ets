// 喂食计划管理页面
// 设置和管理多时段定时投喂计划，支持自适应投喂

import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { RdbHelper } from '../services/RdbHelper';
import { MotionService } from '../services/MotionService';
import { FeederHardwareService } from '../services/FeederHardwareService';
import { relationalStore } from '@kit.ArkData';
import type { FeedingScheduleItem, AdaptiveFeedingRule } from '../models/DataModels';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'FeedingSchedulePage';
const DAYS_OF_WEEK: string[] = ['日', '一', '二', '三', '四', '五', '六'];

@Component
export struct FeedingSchedulePage {
  @StorageProp('currentPetId') @Watch('onPetChanged') currentPetId: number = -1;
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;

  @State private schedules: FeedingScheduleItem[] = [];
  @State private adaptiveRules: AdaptiveFeedingRule[] = [];
  @State private isLoading: boolean = false;
  @State private errorMessage: string = '';
  @State private showAddDialog: boolean = false;
  @State private selectedDays: number[] = [1, 2, 3, 4, 5];

  // 新计划表单
  @State private newTime: string = '08:00';
  @State private newLabel: string = '早餐';
  @State private newAmount: number = 30;
  @State private newIsAdaptive: boolean = false;

  aboutToAppear(): void {
    if (this.isLoggedIn && this.currentPetId > 0) {
      this.loadData();
    }
  }

  // 当 currentPetId 变化时重新加载喂食计划
  onPetChanged(): void {
    if (this.currentPetId > 0) {
      this.loadData();
    }
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const scheduleData = await RdbHelper.getActiveFeedingSchedules(this.currentPetId);
      this.schedules = scheduleData.map((item: FeedingScheduleItem): FeedingScheduleItem => ({
        id: item.id,
        petId: this.currentPetId,
        time: item.time,
        label: item.label,
        amount: item.amount,
        unit: item.unit,
        isActive: item.isActive,
        isAdaptive: item.isAdaptive,
        minAmount: item.minAmount || 20,
        maxAmount: item.maxAmount || 50,
        daysOfWeek: item.daysOfWeek,
      }));

      this.adaptiveRules = [
        { stepsThreshold: 3000, amountAdjustment: 5, isReward: false },
        { stepsThreshold: 5000, amountAdjustment: 10, isReward: true },
        { stepsThreshold: 8000, amountAdjustment: 15, isReward: true },
      ];

      hilog.info(0x0000, TAG, `Loaded ${this.schedules.length} schedules`);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      this.errorMessage = `数据加载失败: ${errorMsg}`;
      hilog.error(0x0000, TAG, `Failed to load data: ${errorMsg}`);
    } finally {
      this.isLoading = false;
    }
  }

  private async saveSchedule(schedule: FeedingScheduleItem): Promise<void> {
    try {
      const now = new Date().toISOString();
      const values: relationalStore.ValuesBucket = {
        pet_id: schedule.petId,
        user_id: 1,
        time: schedule.time,
        label: schedule.label,
        amount: schedule.amount,
        unit: schedule.unit,
        is_active: schedule.isActive ? 1 : 0,
        is_adaptive: schedule.isAdaptive ? 1 : 0,
        min_amount: schedule.minAmount,
        max_amount: schedule.maxAmount,
        days_of_week: JSON.stringify(schedule.daysOfWeek),
        created_at: now,
        updated_at: now,
      };

      if (schedule.id) {
        const predicates = new relationalStore.RdbPredicates('feeding_schedule');
        predicates.equalTo('id', schedule.id);
        await RdbHelper.update(values, predicates);
      } else {
        await RdbHelper.insert('feeding_schedule', values);
      }

      await this.loadData();
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(0x0000, TAG, `Failed to save schedule: ${errorMsg}`);
      throw err;
    }
  }

  private async deleteSchedule(id: number): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates('feeding_schedule');
      predicates.equalTo('id', id);
      await RdbHelper.deleteData(predicates);
      this.schedules = this.schedules.filter((s: FeedingScheduleItem) => s.id !== id);
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to delete schedule: ${JSON.stringify(err)}`);
    }
  }

  private async toggleScheduleActive(id: number, isActive: boolean): Promise<void> {
    try {
      const schedule = this.schedules.find((s: FeedingScheduleItem) => s.id === id);
      if (!schedule) {
        return;
      }
      schedule.isActive = isActive;
      await this.saveSchedule(schedule);
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to toggle schedule: ${JSON.stringify(err)}`);
    }
  }

  private async executeFeedingNow(amount: number): Promise<void> {
    try {
      await FeederHardwareService.feed(amount);
      hilog.info(0x0000, TAG, `Manual feeding executed: ${amount}g`);
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      this.errorMessage = `投喂失败: ${errorMsg}`;
    }
  }

  private calculateAdaptiveAmount(baseAmount: number): number {
    try {
      const stats = MotionService.getRealTimeStats();
      return MotionService.calculateSuggestedFeedingAmount(stats.steps, baseAmount);
    } catch (err) {
      return baseAmount;
    }
  }

  @Builder
  private buildHeader() {
    Row() {
      Text('🍽️ 喂食计划').fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      Button('+ 添加计划', { type: ButtonType.Normal })
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(Color.White)
        .fontSize(AppFonts.CAPTION)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(20)
        .onClick(() => {
          this.showAddDialog = true;
        })
    }
    .width('100%')
    .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 12, bottom: 12 })
  }

  @Builder
  private buildScheduleList() {
    Column({ space: 12 }) {
      if (this.schedules.length === 0) {
        this.buildEmptyState()
      } else {
        ForEach(this.schedules, (schedule: FeedingScheduleItem) => {
          this.buildScheduleCard(schedule)
        })
      }
    }
    .width('100%')
    .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING })
  }

  @Builder
  private buildScheduleCard(schedule: FeedingScheduleItem) {
    GlassCard() {
      Column({ space: 8 }) {
        Row() {
          Column({ space: 4 }) {
            Text(schedule.label).fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Text(schedule.time).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
          }.layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: schedule.isActive })
            .onChange((isOn: boolean) => {
              this.toggleScheduleActive(schedule.id!, isOn);
            })
        }.width('100%')

        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text('基础量').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
            Text(`${schedule.amount}${schedule.unit}`)
              .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
          }.layoutWeight(1)

          Column({ space: 4 }) {
            Text('自适应').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
            Text(schedule.isAdaptive ? '启用' : '禁用')
              .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
              .fontColor(schedule.isAdaptive ? AppColors.SUCCESS : AppColors.TEXT_HINT)
          }.layoutWeight(1)

          Column({ space: 4 }) {
            Text('建议量').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
            Text(schedule.isAdaptive ? `${this.calculateAdaptiveAmount(schedule.amount)}${schedule.unit}` : '--')
              .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
              .fontColor(schedule.isAdaptive ? AppColors.SUCCESS : AppColors.TEXT_HINT)
          }.layoutWeight(1)
        }.width('100%')

        // 执行日期
        Row({ space: 4 }) {
          ForEach(DAYS_OF_WEEK, (day: string, index: number) => {
            Text(day)
              .fontSize(AppFonts.SMALL)
              .fontColor(schedule.daysOfWeek?.includes(index) ? AppColors.PRIMARY : AppColors.TEXT_HINT)
              .fontWeight(schedule.daysOfWeek?.includes(index) ? FontWeight.Bold : FontWeight.Normal)
              .width(20).height(20)
              .textAlign(TextAlign.Center)
          })
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)

        // 操作按钮
        Row({ space: 8 }) {
          Button('立即投喂', { type: ButtonType.Normal })
            .backgroundColor(AppColors.PRIMARY_10)
            .fontColor(AppColors.PRIMARY)
            .fontSize(AppFonts.CAPTION)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .borderRadius(16)
            .onClick(() => {
              const amount = schedule.isAdaptive
                ? this.calculateAdaptiveAmount(schedule.amount)
                : schedule.amount;
              this.executeFeedingNow(amount);
            })

          Button('删除', { type: ButtonType.Normal })
            .backgroundColor(AppColors.DANGER_10)
            .fontColor(AppColors.DANGER)
            .fontSize(AppFonts.CAPTION)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .borderRadius(16)
            .onClick(() => {
              if (schedule.id) {
                this.deleteSchedule(schedule.id);
              }
            })
        }.width('100%').justifyContent(FlexAlign.End)
      }
    }
  }

  @Builder
  private buildEmptyState() {
    Column({ space: 16 }) {
      Text('📅').fontSize(48)
      Text('暂无喂食计划').fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Text('添加计划后，喂食器将按计划自动投喂')
        .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('创建第一个计划', { type: ButtonType.Normal })
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(Color.White)
        .margin({ top: 8 })
        .onClick(() => {
          this.showAddDialog = true;
        })
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildAdaptiveRulesSection() {
    Column({ space: 12 }) {
      Row() {
        Text('⚡ 自适应投喂规则').fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      }.width('100%')

      if (this.adaptiveRules.length === 0) {
        Text('暂无自适应规则')
          .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_HINT)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 12, bottom: 12 })
      } else {
        ForEach(this.adaptiveRules, (rule: AdaptiveFeedingRule, index: number) => {
          GlassCard() {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(`规则 ${index + 1}`).fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
                Text(rule.isReward ? '奖励零食' : '增量调整')
                  .fontSize(AppFonts.CAPTION)
                  .fontColor(rule.isReward ? AppColors.SUCCESS : AppColors.PRIMARY)
              }.layoutWeight(1)

              Column({ space: 4 }) {
                Text('步数阈值').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
                Text(`${rule.stepsThreshold}步`)
                  .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
              }.layoutWeight(1)

              Column({ space: 4 }) {
                Text('调整量').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
                Text(`${rule.amountAdjustment > 0 ? '+' : ''}${rule.amountAdjustment}%`)
                  .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                  .fontColor(rule.amountAdjustment > 0 ? AppColors.SUCCESS : AppColors.DANGER)
              }.layoutWeight(1)
            }.width('100%')
          }
        })
      }
    }
    .width('100%')
    .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 12, bottom: 12 })
  }

  @Builder
  private buildAddScheduleDialog() {
    if (this.showAddDialog) {
      Stack() {
        Column()
          .width('100%').height('100%')
          .backgroundColor('#00000040')
          .onClick(() => {
            this.showAddDialog = false;
          })

        Column({ space: 16 }) {
          Row() {
            Text('添加喂食计划').fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            Button('×', { type: ButtonType.Normal })
              .fontSize(20).fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showAddDialog = false;
              })
          }.width('100%')

          Column({ space: 12 }) {
            // 时间输入
            Row({ space: 8 }) {
              Text('时间').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).width(60)
              TextInput({ placeholder: '08:00', text: this.newTime })
                .onChange((value: string) => {
                  this.newTime = value;
                })
                .layoutWeight(1)
            }.width('100%')

            // 标签
            Row({ space: 8 }) {
              Text('标签').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).width(60)
              TextInput({ placeholder: '例如：早餐', text: this.newLabel })
                .onChange((value: string) => {
                  this.newLabel = value;
                })
                .layoutWeight(1)
            }.width('100%')

            // 投喂量
            Row({ space: 8 }) {
              Text('投喂量').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).width(60)
              TextInput({ placeholder: '30', text: this.newAmount.toString() })
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.newAmount = parseInt(value) || 30;
                })
                .layoutWeight(1)
              Text('克').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%')

            // 自适应开关
            Row({ space: 8 }) {
              Text('自适应').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).width(60)
              Toggle({ type: ToggleType.Switch, isOn: this.newIsAdaptive })
                .onChange((isOn: boolean) => {
                  this.newIsAdaptive = isOn;
                })
              Text(this.newIsAdaptive ? '根据运动量调整' : '固定投喂量')
                .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%')

            // 执行日期
            Column({ space: 8 }) {
              Text('执行日期').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY)
              Row({ space: 4 }) {
                ForEach(DAYS_OF_WEEK, (day: string, index: number) => {
                  Button(day, { type: ButtonType.Normal })
                    .width(36).height(36)
                    .backgroundColor(this.selectedDays.includes(index) ? AppColors.PRIMARY : '#F3F4F6')
                    .fontColor(this.selectedDays.includes(index) ? Color.White : AppColors.TEXT_SECONDARY)
                    .borderRadius(18)
                    .onClick(() => {
                      const newDays = [...this.selectedDays];
                      const dayIndex = newDays.indexOf(index);
                      if (dayIndex >= 0) {
                        newDays.splice(dayIndex, 1);
                      } else {
                        newDays.push(index);
                      }
                      this.selectedDays = newDays.sort();
                    })
                })
              }.width('100%').justifyContent(FlexAlign.SpaceBetween)
            }.width('100%')
          }.width('100%')

          Row({ space: 12 }) {
            Button('取消', { type: ButtonType.Normal })
              .backgroundColor('#F3F4F6')
              .fontColor(AppColors.TEXT_SECONDARY)
              .layoutWeight(1)
              .onClick(() => {
                this.showAddDialog = false;
              })

            Button('保存', { type: ButtonType.Normal })
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(Color.White)
              .layoutWeight(1)
              .onClick(async () => {
                try {
                  const newSchedule: FeedingScheduleItem = {
                    petId: this.currentPetId,
                    time: this.newTime,
                    label: this.newLabel || '新计划',
                    amount: this.newAmount,
                    unit: 'g',
                    isActive: true,
                    isAdaptive: this.newIsAdaptive,
                    minAmount: 20,
                    maxAmount: 50,
                    daysOfWeek: this.selectedDays,
                  };

                  await this.saveSchedule(newSchedule);
                  this.showAddDialog = false;
                  this.resetForm();
                } catch (err) {
                  const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
                  this.errorMessage = `保存失败: ${errorMsg}`;
                }
              })
          }.width('100%')
        }
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .width('90%')
        .maxWidth(400)
      }
      .width('100%').height('100%')
    }
  }

  private resetForm(): void {
    this.newTime = '08:00';
    this.newLabel = '早餐';
    this.newAmount = 30;
    this.newIsAdaptive = false;
    this.selectedDays = [1, 2, 3, 4, 5];
  }

  build() {
    Stack() {
      if (!this.isLoggedIn || this.currentPetId <= 0) {
        this.buildLoginPrompt()
      } else {
        Column() {
          this.buildHeader()
          Scroll() {
            Column({ space: 20 }) {
              this.buildScheduleList()
              this.buildAdaptiveRulesSection()
            }
            .width('100%')
            .padding({ bottom: AppSizes.PAGE_PADDING })
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }

      this.buildAddScheduleDialog()

      if (this.errorMessage) {
        this.buildErrorOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  private buildErrorOverlay() {
    Stack() {
      Column({ space: 12 }) {
        Text('❌').fontSize(32)
        Text(this.errorMessage)
          .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .maxLines(3)

        Button('确定', { type: ButtonType.Normal })
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(Color.White)
          .margin({ top: 8 })
          .onClick(() => {
            this.errorMessage = '';
          })
      }
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .width('80%')
    }
    .width('100%').height('100%')
    .backgroundColor('#00000040')
  }

  @Builder
  private buildLoginPrompt() {
    Column({ space: 16 }) {
      Text('🍽️').fontSize(48)
      Text('喂食计划管理').fontSize(24).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text('请先登录并选择宠物以管理喂食计划')
        .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
