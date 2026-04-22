// 主入口页面 — 登录态路由守卫 + 全局宠物切换状态
import { AppColors, AppFonts } from '../common/constants/AppConstants';
import { HomePage } from './HomePage';
import { DevicesPage } from './DevicesPage';
import { HealthPage } from './HealthPage';
import { ProfilePage } from './ProfilePage';
import { UserService } from '../services/UserService';
import { router } from '@kit.ArkUI';

interface TabItem {
  label: string;
  icon: Resource;
  iconSelected: Resource;
}

@Entry
@Component
struct Index {
  @State private currentIndex: number = 0;
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;

  private tabItems: TabItem[] = [
    { label: '首页', icon: $r('app.media.ohos_ic_public_home'), iconSelected: $r('app.media.ohos_ic_public_home_filled') },
    { label: '设备', icon: $r('app.media.ohos_ic_public_device'), iconSelected: $r('app.media.ohos_ic_public_device_filled') },
    { label: '健康', icon: $r('app.media.ohos_ic_public_health'), iconSelected: $r('app.media.ohos_ic_public_health_filled') },
    { label: '我的', icon: $r('app.media.ohos_ic_public_contacts'), iconSelected: $r('app.media.ohos_ic_public_contacts_filled') }
  ];

  aboutToAppear(): void {
    // 初始化 AppStorage 默认值
    if (!AppStorage.has('isLoggedIn')) {
      AppStorage.setOrCreate<boolean>('isLoggedIn', false);
    }
    if (!AppStorage.has('currentUserId')) {
      AppStorage.setOrCreate<number>('currentUserId', -1);
    }
    if (!AppStorage.has('currentUsername')) {
      AppStorage.setOrCreate<string>('currentUsername', '');
    }
    if (!AppStorage.has('currentNickname')) {
      AppStorage.setOrCreate<string>('currentNickname', '');
    }
    if (!AppStorage.has('currentPetId')) {
      AppStorage.setOrCreate<number>('currentPetId', -1);
    }
    // 登录态检查
    if (!UserService.isLoggedIn()) {
      router.replaceUrl({ url: 'pages/LoginPage' });
    }
  }

  @Builder
  private buildTabBar(item: TabItem, index: number) {
    Column({ space: 4 }) {
      Image(this.currentIndex === index ? item.iconSelected : item.icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? AppColors.PRIMARY : AppColors.TEXT_HINT)
      Text(item.label)
        .fontSize(AppFonts.SMALL)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? AppColors.PRIMARY : AppColors.TEXT_HINT)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.buildTabBar(this.tabItems[0], 0))

      TabContent() {
        DevicesPage()
      }
      .tabBar(this.buildTabBar(this.tabItems[1], 1))

      TabContent() {
        HealthPage()
      }
      .tabBar(this.buildTabBar(this.tabItems[2], 2))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.buildTabBar(this.tabItems[3], 3))
    }
    .barHeight(56)
    .barBackgroundColor(Color.White)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
