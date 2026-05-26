// 地图页面
// 显示宠物实时位置和运动轨迹

import { MapService } from '../services/MapService';
import { LocationService } from '../services/LocationService';
import { AppColors, AppSizes, AppFonts } from '../common/constants/AppConstants';
import { GlassCard, StatusBadge } from '../components/CommonComponents';
import { MapComponent } from '../components/MapComponent';
import type { LocationPoint } from '../models/DataModels';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'MapPage';

@Component
export struct MapPage {
  @StorageProp('currentPetId') @Watch('onPetChanged') currentPetId: number = -1;
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;

  @State private currentLocation: LocationPoint | null = null;
  @State private isTracking: boolean = false;
  @State private trajectoryPoints: LocationPoint[] = [];
  @State private showTrajectory: boolean = true;
  @State private mapLoaded: boolean = false;
  @State private isLoading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.isLoggedIn && this.currentPetId > 0) {
      this.initializeMap();
    }
  }

  // 当 currentPetId 变化时重新初始化地图
  onPetChanged(): void {
    if (this.currentPetId > 0) {
      this.mapLoaded = false;
      this.initializeMap();
    }
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  private async initializeMap(): Promise<void> {
    if (this.mapLoaded) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 初始化地图服务
      await MapService.initialize();

      // 获取当前位置
      const location = await LocationService.getCurrentLocation();
      this.currentLocation = location;

      // 设置地图中心
      await MapService.setCenter(location.latitude, location.longitude);

      // 添加宠物标记
      await MapService.addPetMarker('current_pet', location, '当前位置');

      // 开始位置跟踪
      await LocationService.startTracking(this.currentPetId, 'collar_001');
      this.isTracking = true;

      // 注册位置更新回调
      LocationService.onLocationUpdate((loc: LocationPoint) => {
        this.handleLocationUpdate(loc);
      });

      // 加载当日轨迹
      await this.loadTodayTrajectory();

      this.mapLoaded = true;
      hilog.info(0x0000, TAG, 'Map page initialized successfully');
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      this.errorMessage = `地图初始化失败: ${errorMsg}`;
      hilog.error(0x0000, TAG, `Failed to initialize map: ${errorMsg}`);
    } finally {
      this.isLoading = false;
    }
  }

  private async loadTodayTrajectory(): Promise<void> {
    try {
      const today = new Date().toISOString().split('T')[0];
      const points = await LocationService.getPetTrajectory(this.currentPetId, today);
      this.trajectoryPoints = points;

      if (points.length >= 2 && this.showTrajectory) {
        await MapService.drawTrajectory('today_trajectory', points);
      }

      hilog.debug(0x0000, TAG, `Loaded ${points.length} trajectory points for today`);
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to load trajectory: ${JSON.stringify(err)}`);
    }
  }

  private async handleLocationUpdate(location: LocationPoint): Promise<void> {
    this.currentLocation = location;

    try {
      await MapService.updatePetMarker('current_pet', location);

      if (this.mapLoaded) {
        await MapService.setCenter(location.latitude, location.longitude, true);
      }
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to update map marker: ${JSON.stringify(err)}`);
    }
  }

  private async toggleTrajectory(): Promise<void> {
    this.showTrajectory = !this.showTrajectory;

    if (this.showTrajectory && this.trajectoryPoints.length >= 2) {
      await MapService.drawTrajectory('today_trajectory', this.trajectoryPoints);
    } else {
      await MapService.removePolyline('today_trajectory');
    }
  }

  private async recenterMap(): Promise<void> {
    if (!this.currentLocation) {
      return;
    }

    try {
      await MapService.setCenter(this.currentLocation.latitude, this.currentLocation.longitude, true);
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to recenter map: ${JSON.stringify(err)}`);
    }
  }

  private async toggleTracking(): Promise<void> {
    try {
      if (this.isTracking) {
        await LocationService.stopTracking();
        this.isTracking = false;
      } else {
        await LocationService.startTracking(this.currentPetId, 'collar_001');
        this.isTracking = true;
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      this.errorMessage = `跟踪控制失败: ${errorMsg}`;
    }
  }

  private cleanup(): void {
    if (this.isTracking) {
      LocationService.stopTracking().catch(err => {
        hilog.error(0x0000, TAG, `Failed to stop tracking during cleanup: ${JSON.stringify(err)}`);
      });
      this.isTracking = false;
    }

    LocationService.clearAllCallbacks();

    MapService.release().catch(err => {
      hilog.error(0x0000, TAG, `Failed to release map service: ${JSON.stringify(err)}`);
    });
  }

  @Builder
  private buildMapContainer() {
    Column() {
      // 地图组件
      Stack() {
        MapComponent({
          centerLatitude: this.currentLocation?.latitude ?? 39.9042,
          centerLongitude: this.currentLocation?.longitude ?? 116.4074,
          markerCount: this.currentLocation ? 1 : 0,
          polylineCount: this.showTrajectory && this.trajectoryPoints.length >= 2 ? 1 : 0,
          showControls: false,
        })
          .width('100%')
          .height('100%')

        // 地图控制按钮
        Column({ space: 8 }) {
          this.buildMapControlButton('定位', AppColors.PRIMARY)
          this.buildMapControlButton(this.showTrajectory ? '隐藏轨迹' : '显示轨迹', AppColors.SECONDARY)
          this.buildMapControlButton(this.isTracking ? '停止跟踪' : '开始跟踪',
            this.isTracking ? AppColors.DANGER : AppColors.SUCCESS)
        }
        .position({ x: AppSizes.PAGE_PADDING, y: AppSizes.PAGE_PADDING })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('55%')
      .backgroundColor('#F3F4F6')

      // 位置信息卡片
      Scroll() {
        Column({ space: 8 }) {
          this.buildLocationCard()
          this.buildTrajectoryCard()
        }
        .width('100%')
        .padding({ bottom: AppSizes.PAGE_PADDING })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  private buildMapControlButton(label: string, color: string) {
    Button(label, { type: ButtonType.Normal })
      .backgroundColor(color)
      .fontColor(Color.White)
      .fontSize(AppFonts.CAPTION)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(20)
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.15)', offsetY: 2 })
      .onClick(() => {
        if (label === '定位') {
          this.recenterMap();
        } else if (label.includes('轨迹')) {
          this.toggleTrajectory();
        } else {
          this.toggleTracking();
        }
      })
  }

  @Builder
  private buildLocationCard() {
    if (this.currentLocation) {
      GlassCard() {
        Column({ space: 8 }) {
          Row() {
            Text('📍 实时位置').fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            StatusBadge({ label: this.isTracking ? '跟踪中' : '已停止', isOnline: this.isTracking })
          }.width('100%')

          Row({ space: 8 }) {
            Column({ space: 4 }) {
              Text('纬度').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              Text(this.currentLocation!.latitude.toFixed(6))
                .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            }.layoutWeight(1)

            Column({ space: 4 }) {
              Text('经度').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              Text(this.currentLocation!.longitude.toFixed(6))
                .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            }.layoutWeight(1)

            Column({ space: 4 }) {
              Text('精度').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              Text(`${this.currentLocation!.accuracy.toFixed(1)}米`)
                .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                .fontColor(this.currentLocation!.accuracy < 50 ? AppColors.SUCCESS : AppColors.WARNING)
            }.layoutWeight(1)
          }.width('100%')

          Text(`更新时间: ${this.currentLocation!.timestamp}`)
            .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_HINT)
        }
      }
      .margin({ top: 12, left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING })
    }
  }

  @Builder
  private buildTrajectoryCard() {
    GlassCard() {
      Column({ space: 8 }) {
        Row() {
          Text('🛤️ 今日轨迹').fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          Text(`${this.trajectoryPoints.length}个点`)
            .fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
        }.width('100%')

        if (this.trajectoryPoints.length > 0) {
          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Text('总距离').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              Text(`${(LocationService.calculateTrajectoryDistance(this.trajectoryPoints) / 1000).toFixed(2)}公里`)
                .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            }.layoutWeight(1)

            Column({ space: 4 }) {
              Text('点数').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              Text(this.trajectoryPoints.length.toString())
                .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            }.layoutWeight(1)

            Column({ space: 4 }) {
              Text('状态').fontSize(AppFonts.SMALL).fontColor(AppColors.TEXT_SECONDARY)
              Text(this.showTrajectory ? '显示中' : '已隐藏')
                .fontSize(AppFonts.BODY).fontWeight(FontWeight.Medium)
                .fontColor(this.showTrajectory ? AppColors.SUCCESS : AppColors.TEXT_HINT)
            }.layoutWeight(1)
          }.width('100%')
        } else {
          Text('暂无轨迹数据，开始运动后会自动记录')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_HINT)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 12, bottom: 12 })
        }
      }
    }
    .margin({ top: 8, left: AppSizes.PAGE_PADDING, right: AppSizes.PAGE_PADDING, bottom: AppSizes.PAGE_PADDING })
  }

  @Builder
  private buildLoadingOverlay() {
    if (this.isLoading) {
      Stack() {
        Column() {
          LoadingProgress()
            .color(AppColors.PRIMARY)
            .width(40).height(40)
          Text('地图加载中...')
            .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_PRIMARY)
            .margin({ top: 12 })
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#00000040')
    }
  }

  @Builder
  private buildErrorOverlay() {
    if (this.errorMessage) {
      Stack() {
        Column({ space: 12 }) {
          Text('❌').fontSize(32)
          Text('出错了').fontSize(AppFonts.BODY).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text(this.errorMessage)
            .fontSize(AppFonts.CAPTION).fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .maxLines(3)

          Button('重试', { type: ButtonType.Normal })
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(Color.White)
            .margin({ top: 8 })
            .onClick(() => {
              this.errorMessage = '';
              this.initializeMap();
            })
        }
        .padding(24)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .width('80%')
      }
      .width('100%').height('100%')
      .backgroundColor('#00000040')
    }
  }

  build() {
    Stack() {
      if (!this.isLoggedIn || this.currentPetId <= 0) {
        this.buildLoginPrompt()
      } else {
        this.buildMapContainer()
        this.buildLoadingOverlay()
        this.buildErrorOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  private buildLoginPrompt() {
    Column({ space: 16 }) {
      Text('🗺️').fontSize(48)
      Text('宠物地图').fontSize(24).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text('请先登录并选择宠物以查看位置信息')
        .fontSize(AppFonts.BODY).fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
