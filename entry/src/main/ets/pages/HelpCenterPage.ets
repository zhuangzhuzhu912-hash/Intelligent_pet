// 帮助中心页面
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { router } from '@kit.ArkUI';

interface FaqItem {
  id: number;
  question: string;
  answer: string;
  expanded: boolean;
}

@Entry
@Component
struct HelpCenterPage {
  @State private faqs: FaqItem[] = [
    { id: 1, question: '如何添加宠物？', answer: '进入"我的"页面，点击"我的宠物"，然后点击右下角的"+"按钮即可添加新宠物。填写宠物名称、品种、年龄等信息后保存。', expanded: false },
    { id: 2, question: '如何连接智能设备？', answer: '确保设备已开机并与手机连接同一华为账号的Wi-Fi网络。打开应用进入"设备"页面，设备将自动被发现并显示在列表中。', expanded: false },
    { id: 3, question: '如何进行宠物喂食？', answer: '在"设备"页面中点击智能喂食器，可设置定时喂食计划或进行即时喂食。也可以在首页查看当前喂食状态。', expanded: false },
    { id: 4, question: '如何查看宠物运动轨迹？', answer: '确保宠物佩戴了智能项圈设备。在"设备"页面中点击智能项圈进入地图页面，可查看实时位置和今日运动轨迹。', expanded: false },
    { id: 5, question: '数据同步需要什么条件？', answer: '需要登录华为账号并开启设备数据同步权限。在"隐私设置"中确保"设备数据同步"选项已开启。所有设备需在同一华为账号下。', expanded: false },
    { id: 6, question: '设备连接不上怎么办？', answer: '首先检查设备是否已开机且电量充足，确认手机和设备连接同一Wi-Fi网络。尝试重启设备和手机蓝牙。若仍无法连接，请在设备管理页面删除该设备后重新添加。', expanded: false },
    { id: 7, question: '如何设置喂食计划？', answer: '在首页的喂食计划模块中点击加号，设置投喂时间和投喂量。可开启"自适应投喂"功能，系统将根据宠物每日运动量自动调整投喂量，避免过度或不足喂养。', expanded: false },
    { id: 8, question: '忘记密码怎么办？', answer: '在登录页面点击"忘记密码"，输入注册时使用的手机号或邮箱，系统将发送验证码。验证通过后即可设置新密码。', expanded: false }
  ];

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('帮助中心')
          .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
      }
      .width('100%').padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 8 })

      Scroll() {
        Column({ space: AppSizes.CARD_GAP }) {
          // 使用指南
          GlassCard() {
            Column({ space: 8 }) {
              Text('📖 快速入门指南')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')

              this.buildGuideStep('1', '注册/登录', '使用手机号或邮箱注册账号，登录后进入主界面')
              Divider().color(AppColors.DIVIDER).margin({ left: 32 })
              this.buildGuideStep('2', '添加宠物', '点击"我的" → "我的宠物" → "+"号，填写宠物信息')
              Divider().color(AppColors.DIVIDER).margin({ left: 32 })
              this.buildGuideStep('3', '绑定设备', '确保设备开机联网，进入"设备"页面自动发现并添加设备')
              Divider().color(AppColors.DIVIDER).margin({ left: 32 })
              this.buildGuideStep('4', '设置喂食计划', '在首页设置定时喂食，启用自适应投喂更省心')
            }
            .width('100%')
          }

          // 常见问题
          Text('❓ 常见问题')
            .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY).width('100%')
            .padding({ top: 4 })

          ForEach(this.faqs, (item: FaqItem) => {
            GlassCard() {
              Column({ space: 8 }) {
                Row() {
                  Text(item.question)
                    .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
                  Text(item.expanded ? '收起 ▲' : '展开 ▼')
                    .fontSize(AppFonts.CAPTION).fontColor(AppColors.PRIMARY)
                }
                .width('100%')
                .onClick(() => {
                  item.expanded = !item.expanded;
                })

                if (item.expanded) {
                  Text(item.answer)
                    .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
                    .width('100%').padding(12)
                    .backgroundColor(AppColors.BG_PAGE).borderRadius(8)
                    .lineHeight(20)
                }
              }
            }
          })

          // 联系我们
          GlassCard() {
            Column({ space: 10 }) {
              Text('📞 联系我们')
                .fontSize(AppFonts.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY).width('100%')

              Row({ space: 12 }) {
                Text('💬').fontSize(20).width(36).height(36)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(AppColors.SUCCESS_10).borderRadius(18)
                Column({ space: 2 }) {
                  Text('在线客服')
                    .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT_PRIMARY)
                  Text('实时对话，快速解决问题')
                    .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text('联系客服')
                  .fontSize(AppFonts.CAPTION).fontColor(AppColors.PRIMARY)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(AppColors.PRIMARY_10).borderRadius(12)
              }
              .width('100%')

              Divider().color(AppColors.DIVIDER)

              Text('客服热线：400-123-4567')
                .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
              Text('服务时间：周一至周日 9:00-21:00')
                .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_HINT)
              Text('联系邮箱：support@pethub.com')
                .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
            }
            .width('100%')
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
  private buildGuideStep(step: string, title: string, desc: string) {
    Row({ space: 12 }) {
      Text(step)
        .fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .width(24).height(24)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY).borderRadius(12)
      Column({ space: 1 }) {
        Text(title)
          .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(desc)
          .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }
}
