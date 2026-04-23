import { AppColors, AppSizes } from '../common/constants/AppConstants';

// 玻璃态卡片组件 — 对应原型中的 .glass-card
@Component
export struct GlassCard {
  @BuilderParam content: () => void = () => {};

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(AppSizes.CARD_PADDING)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(AppSizes.CARD_RADIUS)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.04)',
      offsetY: 4
    })
  }
}

// 在线/离线状态标签
@Component
export struct StatusBadge {
  label: string = '在线';
  isOnline: boolean = true;

  build() {
    Text(this.label)
      .fontSize(10)
      .fontColor(this.isOnline ? AppColors.SUCCESS : AppColors.TEXT_HINT)
      .backgroundColor(this.isOnline ? AppColors.SUCCESS_10 : AppColors.DIVIDER)
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .borderRadius(10)
  }
}

// 区块标题组件
@Component
export struct SectionHeader {
  icon: Resource | undefined = undefined;
  iconColor: string = AppColors.SECONDARY;
  title: string = '';
  trailing: string = '';

  build() {
    Row() {
      if (this.icon) {
        Image(this.icon)
          .width(18)
          .height(18)
          .fillColor(this.iconColor)
          .margin({ right: 6 })
      }
      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      if (this.trailing.length > 0) {
        Text(this.trailing)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}

// 环形进度条组件 — 对应原型中的 SVG 环形进度
@Component
export struct ProgressRing {
  @Prop percent: number = 0;
  strokeColor: string = AppColors.PRIMARY;
  trackColor: string = '#E8E8E8';
  strokeWidth: number = 6;
  ringSize: number = 80;
  @BuilderParam centerContent: () => void = () => {};

  build() {
    Stack() {
      // 背景轨道
      Circle()
        .width(this.ringSize)
        .height(this.ringSize)
        .fill(Color.Transparent)
        .stroke(this.trackColor)
        .strokeWidth(this.strokeWidth)

      // 进度弧线 — 使用 Progress 组件
      Progress({
        value: this.percent,
        total: 100,
        type: ProgressType.Ring
      })
        .width(this.ringSize)
        .height(this.ringSize)
        .color(this.strokeColor)
        .backgroundColor(this.trackColor)
        .style({ strokeWidth: this.strokeWidth })

      // 中心内容
      this.centerContent()
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}

// 快捷操作按钮
@Component
export struct QuickActionButton {
  icon: Resource | undefined = undefined;
  label: string = '';
  bgColor: string = AppColors.DIVIDER;
  iconColor: string = AppColors.TEXT_SECONDARY;
  onClicked?: () => void;

  build() {
    Column() {
      Image(this.icon)
        .width(22)
        .height(22)
        .fillColor(this.iconColor)
      Text(this.label)
        .fontSize(11)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(this.bgColor)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onClicked?.();
    })
  }
}
