// 忘记密码页面
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { UserService } from '../services/UserService';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ForgotPasswordPage';

@Entry
@Component
struct ForgotPasswordPage {
  @State private username: string = '';
  @State private phone: string = '';
  @State private newPassword: string = '';
  @State private confirmPassword: string = '';
  @State private isLoading: boolean = false;
  @State private errorMsg: string = '';
  @State private successMsg: string = '';

  private async handleReset(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMsg = '请输入用户名';
      return;
    }
    if (!this.phone.trim()) {
      this.errorMsg = '请输入注册时的手机号';
      return;
    }
    if (!this.newPassword.trim() || this.newPassword.length < 6) {
      this.errorMsg = '新密码至少6位';
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      this.errorMsg = '两次密码不一致';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    this.successMsg = '';
    try {
      const result = await UserService.resetPassword(
        this.username.trim(),
        this.phone.trim(),
        this.newPassword
      );
      if (result) {
        this.successMsg = '密码重置成功，请返回登录';
      } else {
        this.errorMsg = '重置失败，请重试';
      }
    } catch (err) {
      const error = err as Error;
      this.errorMsg = error.message || '重置失败';
      hilog.error(0x0000, TAG, `Reset failed: ${JSON.stringify(err)}`);
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
        Text('找回密码')
          .fontSize(AppFonts.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, top: 56, bottom: 24 })

      // 表单
      Column({ space: 16 }) {
        Text('请输入注册时的用户名和手机号来重置密码')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '用户名', text: this.username })
          .type(InputType.Normal)
          .height(48)
          .borderRadius(AppSizes.CARD_RADIUS)
          .backgroundColor('#F3F4F6')
          .padding({ left: 16, right: 16 })
          .fontSize(AppFonts.BODY)
          .onChange((value: string) => {
            this.username = value;
            this.errorMsg = '';
          })

        TextInput({ placeholder: '注册手机号', text: this.phone })
          .type(InputType.PhoneNumber)
          .height(48)
          .borderRadius(AppSizes.CARD_RADIUS)
          .backgroundColor('#F3F4F6')
          .padding({ left: 16, right: 16 })
          .fontSize(AppFonts.BODY)
          .onChange((value: string) => {
            this.phone = value;
            this.errorMsg = '';
          })

        TextInput({ placeholder: '新密码（至少6位）', text: this.newPassword })
          .type(InputType.Password)
          .height(48)
          .borderRadius(AppSizes.CARD_RADIUS)
          .backgroundColor('#F3F4F6')
          .padding({ left: 16, right: 16 })
          .fontSize(AppFonts.BODY)
          .onChange((value: string) => {
            this.newPassword = value;
            this.errorMsg = '';
          })

        TextInput({ placeholder: '确认新密码', text: this.confirmPassword })
          .type(InputType.Password)
          .height(48)
          .borderRadius(AppSizes.CARD_RADIUS)
          .backgroundColor('#F3F4F6')
          .padding({ left: 16, right: 16 })
          .fontSize(AppFonts.BODY)
          .onChange((value: string) => {
            this.confirmPassword = value;
            this.errorMsg = '';
          })

        // 错误提示
        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.DANGER)
            .width('100%')
        }

        // 成功提示
        if (this.successMsg.length > 0) {
          Text(this.successMsg)
            .fontSize(AppFonts.CAPTION)
            .fontColor(AppColors.SUCCESS)
            .width('100%')
        }

        // 重置按钮
        Button(this.isLoading ? '重置中...' : '重置密码')
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
            this.handleReset();
          })

        // 返回登录
        Text('返回登录')
          .fontSize(AppFonts.BODY)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
