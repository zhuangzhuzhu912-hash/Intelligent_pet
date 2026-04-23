// 地图组件
// 可复用的地图显示组件（模拟实现）
// 注意：鸿蒙Map Kit需要AGC配置，此处使用模拟UI展示

import { AppColors, AppFonts } from '../common/constants/AppConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'MapComponent';
const DOMAIN: number = 0x0000;

// 标记点数据
export interface MapMarkerData {
  id: string;
  latitude: number;
  longitude: number;
  title: string;
}

// 轨迹线数据
export interface MapPolylineData {
  id: string;
  points: Array<{ latitude: number; longitude: number }>;
  color: string;
}

@Component
export struct MapComponent {
  @State private isMapReady: boolean = false;
  @State private mapError: string = '';

  // 地图配置属性
  @Prop centerLatitude: number = 39.9042;
  @Prop centerLongitude: number = 116.4074;
  @Prop zoomLevel: number = 15;
  @Prop showControls: boolean = true;
  @Prop markerCount: number = 0;
  @Prop polylineCount: number = 0;

  aboutToAppear(): void {
    // 模拟地图加载
    setTimeout(() => {
      this.isMapReady = true;
      hilog.info(DOMAIN, TAG, 'Map component ready (simulated)');
    }, 500);
  }

  @Builder
  private buildMapPlaceholder() {
    Stack() {
      // 地图背景
      Column() {
        // 模拟地图网格
        Column({ space: 2 }) {
          Text('🗺️').fontSize(32)
          Text('地图区域').fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT)
          Text(`中心: ${this.centerLatitude.toFixed(4)}, ${this.centerLongitude.toFixed(4)}`)
            .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
          if (this.markerCount > 0) {
            Text(`📍 ${this.markerCount} 个标记点`)
              .fontSize(AppFonts.SMALL).fontColor(AppColors.PRIMARY)
          }
          if (this.polylineCount > 0) {
            Text(`🛤️ ${this.polylineCount} 条轨迹`)
              .fontSize(AppFonts.SMALL).fontColor(AppColors.SECONDARY)
          }
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#E8F4E8')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(16)

      // 地图控制按钮
      if (this.showControls) {
        Column({ space: 8 }) {
          Button('+', { type: ButtonType.Normal })
            .width(36).height(36)
            .backgroundColor(Color.White)
            .fontColor(AppColors.TEXT_PRIMARY)
            .borderRadius(18)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })

          Button('-', { type: ButtonType.Normal })
            .width(36).height(36)
            .backgroundColor(Color.White)
            .fontColor(AppColors.TEXT_PRIMARY)
            .borderRadius(18)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })

          Button('📍', { type: ButtonType.Normal })
            .width(36).height(36)
            .backgroundColor(Color.White)
            .fontColor(AppColors.PRIMARY)
            .borderRadius(18)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
        }
        .position({ x: 16, y: 16 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildLoadingState() {
    Column({ space: 12 }) {
      LoadingProgress()
        .color(AppColors.PRIMARY)
        .width(32).height(32)
      Text('地图加载中...')
        .fontSize(AppFonts.BODY)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F3F4F6')
    .borderRadius(16)
  }

  @Builder
  private buildErrorState() {
    Column({ space: 12 }) {
      Text('❌').fontSize(24)
      Text('地图加载失败')
        .fontSize(AppFonts.SUBTITLE)
        .fontColor(AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
      Text(this.mapError)
        .fontSize(AppFonts.CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .width('80%')

      Button('重试', { type: ButtonType.Normal })
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(Color.White)
        .margin({ top: 8 })
        .onClick(() => {
          this.mapError = '';
          this.isMapReady = false;
          setTimeout(() => {
            this.isMapReady = true;
          }, 500);
        })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F3F4F6')
    .borderRadius(16)
  }

  build() {
    Column() {
      if (this.mapError) {
        this.buildErrorState()
      } else if (!this.isMapReady) {
        this.buildLoadingState()
      } else {
        this.buildMapPlaceholder()
      }
    }
    .width('100%')
    .height('100%')
  }
}
