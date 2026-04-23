// 注册页面
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { UserService } from '../services/UserService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'RegisterPage';

@Entry
@Component
struct RegisterPage {
  @State private username: string = '';
  @State private nickname: string = '';
  @State private password: string = '';
  @State private confirmPassword: string = '';
  @State private phone: string = '';
  @State private isLoading: boolean = false;
  @State private errorMsg: string = '';

  private async handleRegister(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMsg = '请输入用户名';
      return;
    }
    if (this.username.trim().length < 3) {
      this.errorMsg = '用户名至少3个字符';
      return;
    }
    if (!this.password.trim()) {
      this.errorMsg = '请输入密码';
      return;
    }
    if (this.password.length < 6) {
      this.errorMsg = '密码至少6位';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码不一致';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const userId = await UserService.register(
        this.username.trim(),
        this.password,
        this.nickname.trim() || undefined
      );
      // 注册成功后如果填了手机号，更新手机号
      if (this.phone.trim()) {
        await UserService.updateProfile(userId, undefined, this.phone.trim());
      }
      // 自动登录
      await UserService.login(this.username.trim(), this.password);
      router.replaceUrl({ url: 'pages/Index' });
    } catch (err) {
      const error = err as Error;
      this.errorMsg = error.message || '注册失败';
      hilog.error(0x0000, TAG, `Register failed: ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => {
            router.back();
          })
        Text('注册新账号')
          .fontSize(AppFonts.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 56, bottom: 24 })

      // 表单
      Scroll() {
        Column({ space: 16 }) {
          // 用户名（必填）
          Column({ space: 4 }) {
            Text('用户名 *')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: '3个字符以上', text: $$this.username })
              .type(InputType.Normal)
              .height(48)
              .borderRadius(AppSizes.CARD_RADIUS)
              .backgroundColor('#F3F4F6')
              .padding({ left: 16, right: 16 })
              .fontSize(AppFonts.BODY)
              .onChange(() => {
                this.errorMsg = '';
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 昵称
          Column({ space: 4 }) {
            Text('昵称')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: '给自己取个名字吧', text: $$this.nickname })
              .type(InputType.Normal)
              .height(48)
              .borderRadius(AppSizes.CARD_RADIUS)
              .backgroundColor('#F3F4F6')
              .padding({ left: 16, right: 16 })
              .fontSize(AppFonts.BODY)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 手机号
          Column({ space: 4 }) {
            Text('手机号')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: '用于密码找回', text: $$this.phone })
              .type(InputType.PhoneNumber)
              .height(48)
              .borderRadius(AppSizes.CARD_RADIUS)
              .backgroundColor('#F3F4F6')
              .padding({ left: 16, right: 16 })
              .fontSize(AppFonts.BODY)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 密码
          Column({ space: 4 }) {
            Text('密码 *')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: '至少6位', text: $$this.password })
              .type(InputType.Password)
              .height(48)
              .borderRadius(AppSizes.CARD_RADIUS)
              .backgroundColor('#F3F4F6')
              .padding({ left: 16, right: 16 })
              .fontSize(AppFonts.BODY)
              .onChange(() => {
                this.errorMsg = '';
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 确认密码
          Column({ space: 4 }) {
            Text('确认密码 *')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: '再次输入密码', text: $$this.confirmPassword })
              .type(InputType.Password)
              .height(48)
              .borderRadius(AppSizes.CARD_RADIUS)
              .backgroundColor('#F3F4F6')
              .padding({ left: 16, right: 16 })
              .fontSize(AppFonts.BODY)
              .onChange(() => {
                this.errorMsg = '';
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 错误提示
          if (this.errorMsg.length > 0) {
            Text(this.errorMsg)
              .fontSize(AppFonts.CAPTION)
              .fontColor(AppColors.DANGER)
              .width('100%')
              .textAlign(TextAlign.Start)
          }

          // 注册按钮
          Button(this.isLoading ? '注册中...' : '注册')
            .width('100%')
            .height(48)
            .fontSize(AppFonts.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(AppSizes.BTN_RADIUS)
            .enabled(!this.isLoading)
            .shadow({ radius: 8, color: 'rgba(255,159,67,0.3)', offsetY: 4 })
            .margin({ top: 8 })
            .onClick(() => {
              this.handleRegister();
            })

          // 已有账号
          Row() {
            Text('已有账号？')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
            Text('去登录')
              .fontSize(AppFonts.BODY)
              .fontColor(AppColors.PRIMARY)
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                router.back();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding({ left: 32, right: 32, bottom: 32 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
