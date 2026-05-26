// 隐私设置页面
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { router } from '@kit.ArkUI';

interface PrivacyOption {
  id: number;
  icon: string;
  title: string;
  description: string;
  enabled: boolean;
}

@Entry
@Component
struct PrivacySettingsPage {
  @State private options: PrivacyOption[] = [
    { id: 1, icon: '📍', title: '位置信息共享', description: '允许应用获取宠物实时位置信息', enabled: true },
    { id: 2, icon: '📊', title: '数据收集与分析', description: '收集使用数据以优化服务体验', enabled: true },
    { id: 3, icon: '🔔', title: '个性化推荐', description: '根据使用习惯推荐内容与服务', enabled: false },
    { id: 4, icon: '📡', title: '设备数据同步', description: '通过华为账号同步设备与宠物数据', enabled: true },
    { id: 5, icon: '👤', title: '个人资料公开', description: '允许其他用户查看您的部分资料', enabled: false },
    { id: 6, icon: '🔔', title: '推送通知', description: '接收宠物活动、喂食、设备告警等通知推送', enabled: true },
    { id: 7, icon: '❤️', title: '健康数据共享', description: '与宠物医院共享健康数据以便远程会诊', enabled: false }
  ];

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('隐私设置')
          .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
      }
      .width('100%').padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 8 })

      Scroll() {
        Column({ space: AppSizes.CARD_GAP }) {
          // 权限设置区
          GlassCard() {
            Column() {
              Text('权限设置')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')
                .padding({ bottom: 4 })

              ForEach(this.options, (item: PrivacyOption, index: number) => {
                Row({ space: 12 }) {
                  Text(item.icon).fontSize(20).width(36).height(36)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(item.enabled ? AppColors.PRIMARY_10 : AppColors.DIVIDER)
                    .borderRadius(18)
                  Column({ space: 2 }) {
                    Text(item.title)
                      .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                      .fontColor(AppColors.TEXT_PRIMARY)
                    Text(item.description)
                      .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
                  }
                  .alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Toggle({ type: ToggleType.Switch, isOn: item.enabled })
                    .selectedColor(AppColors.PRIMARY)
                    .onChange((value: boolean) => {
                      item.enabled = value;
                    })
                }
                .width('100%').padding({ top: 10, bottom: 10 })
                if (index < this.options.length - 1) {
                  Divider().color(AppColors.DIVIDER)
                }
              })
            }
          }

          // 数据管理区
          GlassCard() {
            Column() {
              Text('数据管理')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')
                .padding({ bottom: 4 })

              this.buildDataRow('🗑️', '清除缓存数据', '128MB')
              Divider().color(AppColors.DIVIDER)
              this.buildDataRow('🏃', '删除运动记录', '')
              Divider().color(AppColors.DIVIDER)
              this.buildDataRow('🍽️', '删除喂食记录', '')
              Divider().color(AppColors.DIVIDER)
              this.buildDataRow('📤', '导出个人数据', '')
              Divider().color(AppColors.DIVIDER)
              Row() {
                Text('❌').fontSize(18).width(28)
                Text('注销账号').fontSize(AppFonts.BODY).fontColor(AppColors.DANGER).margin({ left: 8 })
                Blank()
                Image($r('sys.media.ohos_ic_public_arrow_right'))
                  .width(14).height(14).fillColor(AppColors.TEXT_HINT)
              }
              .width('100%').padding({ top: 10, bottom: 4 })
            }
          }
        }
        .width('100%')
        .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 12, bottom: 16 })
      }
      .scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  private buildDataRow(icon: string, label: string, hint: string) {
    Row() {
      Text(icon).fontSize(18).width(28)
      Text(label).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
      Blank()
      if (hint !== '') {
        Text(hint).fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_HINT).margin({ right: 6 })
      }
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(14).height(14).fillColor(AppColors.TEXT_HINT)
    }
    .width('100%').padding({ top: 10, bottom: 10 })
  }
}
