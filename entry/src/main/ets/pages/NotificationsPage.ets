
// 消息通知页面 — 分类 Tab：宠物通知、平台公告、设备通知
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { router } from '@kit.ArkUI';

interface NotificationItem {
  id: number;
  icon: string;
  title: string;
  content: string;
  time: string;
  unread: boolean;
  type: string;
}

@Component
@Entry
@Component
export struct NotificationsPage {
  @State private currentTabIndex: number = 0;

  @State private petNotifications: NotificationItem[] = [
    { id: 1, icon: '🐾', title: '宠物运动提醒', content: '您的宠物今日运动量已达目标，继续保持！', time: '10分钟前', unread: true, type: '运动' },
    { id: 2, icon: '🍽️', title: '喂食完成通知', content: '智能喂食器已成功投放午餐，喂食量：50g', time: '2小时前', unread: true, type: '喂食' },
    { id: 4, icon: '💉', title: '疫苗接种提醒', content: '狂犬疫苗将于7天后到期，请及时接种', time: '昨天', unread: false, type: '健康' },
    { id: 10, icon: '❤️', title: '健康周报', content: '本周宠物健康报告已生成，体重稳定、运动量达标', time: '昨天', unread: true, type: '健康' },
    { id: 11, icon: '🏥', title: '体检提醒', content: '距离上次体检已过6个月，建议近期安排体检', time: '2天前', unread: false, type: '健康' },
    { id: 12, icon: '🦷', title: '口腔护理提醒', content: '本周还未给宠物刷牙，建议定期进行口腔护理', time: '3天前', unread: false, type: '健康' }
  ];

  @State private platformNotifications: NotificationItem[] = [
    { id: 5, icon: '📢', title: '版本更新公告', content: 'PetHub v1.1.0 即将发布，新增宠物社交功能，敬请期待！', time: '1天前', unread: true, type: '版本' },
    { id: 6, icon: '🎉', title: '新功能上线', content: '自适应投喂功能已上线！根据宠物运动量智能调整喂食量，快去体验吧', time: '3天前', unread: false, type: '功能' },
    { id: 7, icon: '🏆', title: '宠物运动挑战赛', content: '5月宠物运动挑战赛火热进行中，参与赢取宠物零食礼包！', time: '1周前', unread: false, type: '活动' },
    { id: 13, icon: '📋', title: '用户调研邀请', content: '诚邀您参与用户体验调研，帮助我们做得更好', time: '5天前', unread: true, type: '活动' }
  ];

  @State private deviceNotifications: NotificationItem[] = [
    { id: 3, icon: '🔋', title: '设备电量提醒', content: '智能项圈电量低于20%，请及时充电', time: '3小时前', unread: true, type: '设备' },
    { id: 8, icon: '📡', title: '设备连接通知', content: '智能喂食器已重新连接至网络', time: '昨天', unread: false, type: '设备' },
    { id: 9, icon: '⚙️', title: '固件更新可用', content: '智能饮水机有新固件 v2.3.1 可用，建议更新以获得更好的体验', time: '2天前', unread: true, type: '设备' },
    { id: 14, icon: '📊', title: '设备状态报告', content: '本周所有设备运行正常，喂食器余粮充足，项圈信号良好', time: '3天前', unread: false, type: '设备' }
  ];

  private tabTitles: string[] = ['宠物通知', '平台公告', '设备通知'];

  private getCurrentNotifications(): NotificationItem[] {
    if (this.currentTabIndex === 0) {
      return this.petNotifications;
    } else if (this.currentTabIndex === 1) {
      return this.platformNotifications;
    } else {
      return this.deviceNotifications;
    }
  }

  private getUnreadCount(list: NotificationItem[]): number {
    return list.filter((n: NotificationItem) => n.unread).length;
  }

  private getTabUnreadCount(index: number): number {
    if (index === 0) {
      return this.getUnreadCount(this.petNotifications);
    } else if (index === 1) {
      return this.getUnreadCount(this.platformNotifications);
    } else {
      return this.getUnreadCount(this.deviceNotifications);
    }
  }

  private markCurrentTabAllRead(): void {
    const list = this.getCurrentNotifications();
    for (let i = 0; i < list.length; i++) {
      list[i].unread = false;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('消息通知')
          .fontSize(AppFonts.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY).margin({ left: 8 })
        Blank()
        Text('全部已读')
          .fontSize(AppFonts.BODY).fontColor(AppColors.PRIMARY)
          .onClick(() => {
            this.markCurrentTabAllRead();
          })
      }
      .width('100%').padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 8, bottom: 8 })

      // Tab 切换栏
      Row({ space: 0 }) {
        ForEach(this.tabTitles, (title: string, index: number) => {
          Column({ space: 4 }) {
            Row({ space: 4 }) {
              Text(title)
                .fontSize(AppFonts.BODY)
                .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
              if (this.getTabUnreadCount(index) > 0) {
                Text(this.getTabUnreadCount(index).toString())
                  .fontSize(10).fontColor(Color.White)
                  .backgroundColor(AppColors.DANGER)
                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .borderRadius(8)
              }
            }
            Divider()
              .width('100%').height(2)
              .backgroundColor(this.currentTabIndex === index ? AppColors.PRIMARY : Color.Transparent)
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.currentTabIndex = index;
          })
        })
      }
      .width('100%').padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 4, bottom: 8 })

      Scroll() {
        Column({ space: AppSizes.CARD_GAP }) {
          if (this.getCurrentNotifications().length === 0) {
            GlassCard() {
              Text('暂无通知')
                .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT)
                .width('100%').textAlign(TextAlign.Center)
            }
          }

          ForEach(this.getCurrentNotifications(), (item: NotificationItem) => {
            GlassCard() {
              Row({ space: 12 }) {
                Text(item.icon).fontSize(24).width(40).height(40)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(item.unread ? AppColors.PRIMARY_10 : AppColors.DIVIDER)
                  .borderRadius(20)
                Column({ space: 4 }) {
                  Row() {
                    Text(item.title)
                      .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                      .fontColor(AppColors.TEXT_PRIMARY)
                    if (item.unread) {
                      Circle().width(8).height(8).fill(AppColors.DANGER).margin({ left: 6 })
                    }
                  }
                  Text(item.content)
                    .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: 8 }) {
                    Text(item.time)
                      .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
                    Text('· ' + item.type)
                      .fontSize(AppFonts.SMALL).fontColor(AppColors.PRIMARY)
                  }
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%')
              .onClick(() => {
                item.unread = false;
              })
            }
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
