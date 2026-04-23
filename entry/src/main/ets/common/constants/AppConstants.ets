// 应用主题色 — 对应原型 tailwind.config 中的色系
export class AppColors {
  static readonly PRIMARY: string = '#FF9F43';
  static readonly SECONDARY: string = '#00B4D8';
  static readonly SUCCESS: string = '#52C41A';
  static readonly WARNING: string = '#FAAD14';
  static readonly DANGER: string = '#FF4D4F';
  static readonly BG_PAGE: string = '#F8F9FA';
  static readonly CARD_BG: string = '#FFFFFF';
  static readonly TEXT_PRIMARY: string = '#1F2937';
  static readonly TEXT_SECONDARY: string = '#6B7280';
  static readonly TEXT_HINT: string = '#9CA3AF';
  static readonly BORDER: string = '#E5E7EB';
  static readonly DIVIDER: string = '#F3F4F6';
  // 10% 透明度背景
  static readonly PRIMARY_10: string = '#FFF5EB';
  static readonly SECONDARY_10: string = '#E6F7FB';
  static readonly SUCCESS_10: string = '#EDFCE5';
  static readonly WARNING_10: string = '#FFF8E6';
  static readonly DANGER_10: string = '#FFF1F0';
  // 别名（兼容不同页面引用）
  static readonly BACKGROUND: string = '#F8F9FA';
  static readonly ERROR: string = '#FF4D4F';
  static readonly ERROR_10: string = '#FFF1F0';
}

// 应用尺寸
export class AppSizes {
  static readonly CARD_RADIUS: number = 20;
  static readonly BTN_RADIUS: number = 30;
  static readonly PAGE_PADDING: number = 16;
  static readonly CARD_PADDING: number = 16;
  static readonly CARD_GAP: number = 12;
  static readonly TAB_BAR_HEIGHT: number = 56;
}

// 应用字号
export class AppFonts {
  static readonly TITLE: number = 20;
  static readonly SUBTITLE: number = 16;
  static readonly BODY: number = 14;
  static readonly CAPTION: number = 12;
  static readonly SMALL: number = 10;
}
