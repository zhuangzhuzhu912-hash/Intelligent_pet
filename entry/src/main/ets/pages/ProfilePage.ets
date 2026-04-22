// 个人中心页面 — 集成用户登录态、宠物切换、多宠物管理入口
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard } from '../components/CommonComponents';
import { UserService } from '../services/UserService';
import { PetService } from '../services/PetService';
import type { PetEntity } from '../services/PetService';
import { DeviceDiscoveryService } from '../services/DeviceDiscoveryService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ProfilePage';

@Component
export struct ProfilePage {
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;
  @StorageProp('currentNickname') currentNickname: string = '';
  @StorageProp('currentUsername') currentUsername: string = '';
  @StorageProp('currentUserId') currentUserId: number = -1;
  @StorageProp('currentPetId') currentPetId: number = -1;

  @State private petCount: number = 0;
  @State private deviceCount: number = 0;
  @State private pets: PetEntity[] = [];
  @State private showPetSwitcher: boolean = false;

  private menuGroup1: Array<[string, string, string]> = [
    ['🐾', AppColors.PRIMARY, '我的宠物'],
    ['📡', AppColors.SECONDARY, '设备管理'],
    ['🔗', AppColors.SUCCESS, '联动场景']
  ];

  private menuGroup2: Array<[string, string, string, number]> = [
    ['🔔', AppColors.WARNING, '消息通知', 3],
    ['🛡️', AppColors.PRIMARY, '隐私设置', 0],
    ['❓', AppColors.SECONDARY, '帮助中心', 0],
    ['ℹ️', AppColors.TEXT_HINT, '关于我们', 0]
  ];

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    if (!this.isLoggedIn) {
      return;
    }
    try {
      this.pets = await PetService.getPetsByCurrentUser();
      this.petCount = this.pets.length;
      this.deviceCount = DeviceDiscoveryService.getDeviceCount();
    } catch (err) {
      hilog.error(0x0000, TAG, `Load data failed: ${JSON.stringify(err)}`);
    }
  }

  private handleMenuClick(label: string): void {
    if (label === '我的宠物') {
      router.pushUrl({ url: 'pages/PetManagePage' });
    }
  }

  private handleLogout(): void {
    UserService.logout();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  private handleSwitchPet(petId: number): void {
    PetService.setCurrentPet(petId);
    this.showPetSwitcher = false;
  }

  @Builder
  private buildUserCard() {
    GlassCard() {
      Row({ space: 16 }) {
        Image($r('app.media.user_avatar'))
          .width(64)
          .height(64)
          .borderRadius(32)
          .objectFit(ImageFit.Cover)
          .border({ width: 2, color: Color.White })
        Column({ space: 4 }) {
          Text(this.currentNickname || this.currentUsername || '未登录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text('ID: ' + (this.currentUserId > 0 ? this.currentUserId.toString() : '--'))
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(16)
          .height(16)
          .fillColor(AppColors.TEXT_HINT)
      }
    }
  }

  @Builder
  private buildPetSwitchCard() {
    GlassCard() {
      Column({ space: 12 }) {
        Row() {
          Text('🐾 当前宠物')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text(this.showPetSwitcher ? '收起' : '切换')
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              this.showPetSwitcher = !this.showPetSwitcher;
            })
        }
        .width('100%')

        if (this.pets.length === 0) {
          Text('还没有添加宠物，去添加一只吧')
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_HINT)
            .width('100%')
            .onClick(() => {
              router.pushUrl({ url: 'pages/PetManagePage' });
            })
        } else {
          // 当前宠物信息
          ForEach(this.pets.filter((p: PetEntity) => p.id === this.currentPetId), (pet: PetEntity) => {
            Row({ space: 12 }) {
              Text('🐾')
                .fontSize(24)
                .width(44)
                .height(44)
                .textAlign(TextAlign.Center)
                .backgroundColor(AppColors.PRIMARY_10)
                .borderRadius(22)
              Column({ space: 2 }) {
                Text(pet.name)
                  .fontSize(AppFonts.BODY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.TEXT_PRIMARY)
                Text(`${pet.breed || '未知品种'} · ${pet.age > 0 ? pet.age + '岁' : ''} · ${pet.gender}`)
                  .fontSize(AppFonts.CAPTION)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
          })

          // 宠物切换列表
          if (this.showPetSwitcher && this.pets.length > 1) {
            Divider().color(AppColors.DIVIDER)
            ForEach(this.pets, (pet: PetEntity) => {
              Row({ space: 12 }) {
                Text('🐾')
                  .fontSize(18)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(pet.id === this.currentPetId ? AppColors.PRIMARY_10 : '#F3F4F6')
                  .borderRadius(18)
                Text(pet.name)
                  .fontSize(AppFonts.BODY)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .layoutWeight(1)
                if (pet.id === this.currentPetId) {
                  Text('当前')
                    .fontSize(AppFonts.SMALL)
                    .fontColor(AppColors.SUCCESS)
                    .backgroundColor(AppColors.SUCCESS_10)
                    .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                    .borderRadius(8)
                }
              }
              .width('100%')
              .padding(8)
              .borderRadius(10)
              .backgroundColor(pet.id === this.currentPetId ? 'rgba(255,159,67,0.05)' : Color.Transparent)
              .onClick(() => {
                this.handleSwitchPet(pet.id);
              })
            })
          }
        }
      }
    }
  }

  @Builder
  private buildStatsCard() {
    GlassCard() {
      Grid() {
        GridItem() {
          this.buildStatItem(this.petCount.toString(), '宠物')
        }

        GridItem() {
          this.buildStatItem(this.deviceCount.toString(), '设备')
        }

        GridItem() {
          this.buildStatItem('--', '使用天数')
        }

        GridItem() {
          this.buildStatItem('--', '联动场景')
        }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .width('100%')
    }
  }

  @Builder
  private buildStatItem(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text(label)
        .fontSize(AppFonts.SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildMenuGroup1() {
    GlassCard() {
      Column() {
        ForEach(this.menuGroup1, (item: [string, string, string], index: number) => {
          Row() {
            Text(item[0])
              .fontSize(18)
              .width(28)
            Text(item[2])
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .margin({ left: 8 })
            Blank()
            Image($r('sys.media.ohos_ic_public_arrow_right'))
              .width(14)
              .height(14)
              .fillColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding(12)
          .borderRadius(10)
          .onClick(() => {
            this.handleMenuClick(item[2]);
          })

          if (index < this.menuGroup1.length - 1) {
            Divider().color(AppColors.DIVIDER).margin({ left: 36 })
          }
        })
      }
    }
  }

  @Builder
  private buildMenuGroup2() {
    GlassCard() {
      Column() {
        ForEach(this.menuGroup2, (item: [string, string, string, number], index: number) => {
          Row() {
            Text(item[0])
              .fontSize(18)
              .width(28)
            Text(item[2])
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .margin({ left: 8 })
            Blank()
            if (item[3] > 0) {
              Text(item[3].toString())
                .fontSize(AppFonts.SMALL)
                .fontColor(Color.White)
                .backgroundColor(AppColors.DANGER)
                .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                .borderRadius(10)
                .margin({ right: 8 })
            }
            Image($r('sys.media.ohos_ic_public_arrow_right'))
              .width(14)
              .height(14)
              .fillColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding(12)
          .borderRadius(10)

          if (index < this.menuGroup2.length - 1) {
            Divider().color(AppColors.DIVIDER).margin({ left: 36 })
          }
        })
      }
    }
  }

  @Builder
  private buildLogoutCard() {
    GlassCard() {
      Text('退出登录')
        .fontSize(AppFonts.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.DANGER)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(12)
        .onClick(() => {
          this.handleLogout();
        })
    }
  }

  build() {
    Scroll() {
      Column({ space: AppSizes.CARD_GAP }) {
        Row() {
          Text('我的')
            .fontSize(AppFonts.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Image($r('app.media.ohos_ic_public_settings'))
            .width(22)
            .height(22)
            .fillColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ left: 4, right: 4, bottom: 4 })

        this.buildUserCard()
        this.buildPetSwitchCard()
        this.buildStatsCard()
        this.buildMenuGroup1()
        this.buildMenuGroup2()
        this.buildLogoutCard()
      }
      .width('100%')
      .padding({
        left: AppSizes.PAGE_PADDING,
        right: AppSizes.PAGE_PADDING,
        top: 8,
        bottom: 16
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.BG_PAGE)
  }
}
