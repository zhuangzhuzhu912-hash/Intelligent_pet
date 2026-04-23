// 登录页面
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { UserService } from '../services/UserService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'LoginPage';

@Entry
@Component
struct LoginPage {
  @State private username: string = '';
  @State private password: string = '';
  @State private isLoading: boolean = false;
  @State private errorMsg: string = '';

  private async handleLogin(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMsg = '请输入用户名';
      return;
    }
    if (!this.password.trim()) {
      this.errorMsg = '请输入密码';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      await UserService.login(this.username.trim(), this.password);
      router.replaceUrl({ url: 'pages/Index' });
    } catch (err) {
      const error = err as Error;
      this.errorMsg = error.message || '登录失败';
      hilog.error(0x0000, TAG, `Login failed: ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部留白
      Blank().height(80)

      // Logo 区域
      Column({ space: 8 }) {
        Text('\u26A1')
          .fontSize(48)
        Text('宠联中枢')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('分布式智能养宠平台')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .margin({ bottom: 48 })

      // 表单区域
      Column({ space: 16 }) {
        // 用户名
        TextInput({ placeholder: '请输入用户名', text: $$this.username })
          .type(InputType.Normal)
          .height(48)
          .borderRadius(AppSizes.CARD_RADIUS)
          .backgroundColor('#F3F4F6')
          .padding({ left: 16, right: 16 })
          .fontSize(AppFonts.BODY)
          .onChange(() => {
            this.errorMsg = '';
          })

        // 密码
        TextInput({ placeholder: '请输入密码', text: $$this.password })
          .type(InputType.Password)
          .height(48)
          .borderRadius(AppSizes.CARD_RADIUS)
          .backgroundColor('#F3F4F6')
          .padding({ left: 16, right: 16 })
          .fontSize(AppFonts.BODY)
          .onChange(() => {
            this.errorMsg = '';
          })

        // 错误提示
        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.DANGER)
            .width('100%')
            .textAlign(TextAlign.Start)
        }

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(48)
          .fontSize(AppFonts.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(AppSizes.BTN_RADIUS)
          .enabled(!this.isLoading)
          .shadow({ radius: 8, color: 'rgba(255,159,67,0.3)', offsetY: 4 })
          .onClick(() => {
            this.handleLogin();
          })

        // 底部链接
        Row() {
          Text('忘记密码？')
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
            .onClick(() => {
              router.pushUrl({ url: 'pages/ForgotPasswordPage' });
            })
          Blank()
          Text('注册新账号')
            .fontSize(AppFonts.BODY)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              router.pushUrl({ url: 'pages/RegisterPage' });
            })
        }
        .width('100%')
        .padding({ top: 8 })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
    .justifyContent(FlexAlign.Start)
  }
}
