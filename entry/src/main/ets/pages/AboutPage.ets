// 关于我们页面
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('关于我们')
          .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
      }
      .width('100%').padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 8 })

      Scroll() {
        Column({ space: AppSizes.CARD_GAP }) {
          // App 信息
          GlassCard() {
            Column({ space: 12 }) {
              Text('🐾')
                .fontSize(48).width(80).height(80)
                .textAlign(TextAlign.Center)
                .backgroundColor(AppColors.PRIMARY_10).borderRadius(40)
              Text('PetHub 智能宠物管家')
                .fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
              Text('版本 1.0.0 (Build 2026.05)')
                .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
              Row({ space: 8 }) {
                Text('检查更新')
                  .fontSize(AppFonts.CAPTION).fontColor(AppColors.PRIMARY)
                  .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                  .backgroundColor(AppColors.PRIMARY_10).borderRadius(16)
                Text('已是最新')
                  .fontSize(AppFonts.CAPTION).fontColor(AppColors.SUCCESS)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(AppColors.SUCCESS_10).borderRadius(10)
              }
            }
            .width('100%').alignItems(HorizontalAlign.Center)
          }

          // 应用简介
          GlassCard() {
            Column({ space: 8 }) {
              Text('📖 应用简介')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')
              Text('PetHub 是一款基于 HarmonyOS 的智能宠物管理应用，支持宠物健康监测、智能设备联动、位置追踪、喂食计划等功能。通过分布式软总线技术实现多设备协同，为宠物主人提供全方位的智能养宠体验。')
                .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
                .lineHeight(22)
            }
            .width('100%')
          }

          // 功能介绍
          GlassCard() {
            Column({ space: 8 }) {
              Text('✨ 核心功能')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')

              this.buildFeatureRow('🐾', '宠物档案管理', '支持多宠物信息管理，健康数据追踪')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildFeatureRow('📡', '智能设备联动', '项圈、喂食器、饮水机等智能设备协同工作')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildFeatureRow('🍽️', '喂食计划与自适应', '定时投喂+根据运动量智能调整喂食量')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildFeatureRow('🗺️', '实时位置追踪', 'GPS + 运动轨迹记录，电子围栏安全预警')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildFeatureRow('📊', '健康数据分析', '体重、体温趋势，疫苗到期提醒')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildFeatureRow('🔗', '分布式组网', '基于鸿蒙软总线实现多设备无感协同')
            }
            .width('100%')
          }

          // 技术信息
          GlassCard() {
            Column() {
              Text('📋 技术信息')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')
              Divider().color(AppColors.DIVIDER).margin({ top: 8, bottom: 8 })
              this.buildInfoRow('开发框架', 'HarmonyOS ArkTS / ArkUI')
              Divider().color(AppColors.DIVIDER)
              this.buildInfoRow('SDK 版本', 'API 12+')
              Divider().color(AppColors.DIVIDER)
              this.buildInfoRow('数据库', 'RelationalStore（SQLite）')
              Divider().color(AppColors.DIVIDER)
              this.buildInfoRow('分布式', '软总线 DeviceManager')
              Divider().color(AppColors.DIVIDER)
              this.buildInfoRow('版权所有', '© 2026 PetHub Team')
            }
            .width('100%')
          }

          // 法律与链接
          GlassCard() {
            Column() {
              this.buildLinkRow('📄 用户协议')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildLinkRow('🔒 隐私政策')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildLinkRow('📦 开源许可')
              Divider().color(AppColors.DIVIDER).margin({ left: 36 })
              this.buildLinkRow('⭐ 去应用市场评分')
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
  private buildInfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY).width(80)
      Text(value).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
    }
    .width('100%').padding({ top: 8, bottom: 8 })
  }

  @Builder
  private buildLinkRow(label: string) {
    Row() {
      Text(label).fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(14).height(14).fillColor(AppColors.TEXT_HINT)
    }
    .width('100%').padding({ top: 10, bottom: 10 })
  }

  @Builder
  private buildFeatureRow(icon: string, title: string, desc: string) {
    Row({ space: 10 }) {
      Text(icon).fontSize(18).width(28)
      Column({ space: 1 }) {
        Text(title)
          .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(desc)
          .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding({ top: 4, bottom: 4 })
  }
}
