// 地图服务
// 模拟地图功能，提供地图显示和轨迹可视化接口
// 注意：鸿蒙Map Kit需要在DevEco Studio中通过AGC配置，此处使用模拟实现

import { hilog } from '@kit.PerformanceAnalysisKit';
import type { LocationPoint } from '../models/DataModels';

const TAG: string = 'MapService';
const DOMAIN: number = 0x0000;

// 地图配置
const MAP_CONFIG = {
  zoomLevel: 15,
  minZoomLevel: 10,
  maxZoomLevel: 20,
  tilt: 0,
  bearing: 0,
  showTraffic: false,
  showBuildings: true,
};

// 模拟标记点
interface SimulatedMarker {
  id: string;
  latitude: number;
  longitude: number;
  title: string;
  snippet: string;
}

// 模拟轨迹线
interface SimulatedPolyline {
  id: string;
  points: Array<{ lat: number; lng: number }>;
  color: string;
  width: number;
}

// 模拟圆形
interface SimulatedCircle {
  id: string;
  center: { lat: number; lng: number };
  radius: number;
  strokeColor: string;
}

class MapServiceClass {
  private markers: Map<string, SimulatedMarker> = new Map();
  private polylines: Map<string, SimulatedPolyline> = new Map();
  private circles: Map<string, SimulatedCircle> = new Map();
  private isInitialized: boolean = false;
  private currentCenter: { lat: number; lng: number } = { lat: 39.9042, lng: 116.4074 };
  private currentZoom: number = MAP_CONFIG.zoomLevel;

  // 初始化地图
  async initialize(mapElement?: object): Promise<void> {
    if (this.isInitialized) {
      hilog.warn(DOMAIN, TAG, 'Map service already initialized');
      return;
    }

    try {
      // 模拟地图初始化
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'Map service initialized (simulated mode)');
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : JSON.stringify(err);
      hilog.error(DOMAIN, TAG, `Failed to initialize map service: ${errorMessage}`);
      throw new Error(`地图服务初始化失败: ${errorMessage}`);
    }
  }

  // 设置地图中心点
  async setCenter(latitude: number, longitude: number, animate: boolean = true): Promise<void> {
    this.currentCenter = { lat: latitude, lng: longitude };
    hilog.debug(DOMAIN, TAG, `Map center set to: ${latitude}, ${longitude}, animate: ${animate}`);
  }

  // 添加宠物标记
  async addPetMarker(id: string, location: LocationPoint, title: string = ''): Promise<void> {
    await this.removeMarker(id);

    const marker: SimulatedMarker = {
      id: id,
      latitude: location.latitude,
      longitude: location.longitude,
      title: title || '宠物位置',
      snippet: `精度: ${location.accuracy.toFixed(1)}米`,
    };

    this.markers.set(id, marker);
    hilog.info(DOMAIN, TAG, `Pet marker added: ${id} at (${location.latitude}, ${location.longitude})`);
  }

  // 更新宠物标记位置
  async updatePetMarker(id: string, location: LocationPoint): Promise<void> {
    const marker = this.markers.get(id);
    if (!marker) {
      await this.addPetMarker(id, location);
      return;
    }

    marker.latitude = location.latitude;
    marker.longitude = location.longitude;
    marker.snippet = `精度: ${location.accuracy.toFixed(1)}米`;
    hilog.debug(DOMAIN, TAG, `Pet marker updated: ${id}`);
  }

  // 添加家庭位置标记
  async addHomeMarker(id: string, latitude: number, longitude: number): Promise<void> {
    const marker: SimulatedMarker = {
      id: id,
      latitude: latitude,
      longitude: longitude,
      title: '家庭位置',
      snippet: '宠物活动中心',
    };

    this.markers.set(id, marker);
    hilog.info(DOMAIN, TAG, `Home marker added: ${id}`);
  }

  // 添加喂食器标记
  async addFeederMarker(id: string, latitude: number, longitude: number): Promise<void> {
    const marker: SimulatedMarker = {
      id: id,
      latitude: latitude,
      longitude: longitude,
      title: '智能喂食器',
      snippet: '自动投喂设备',
    };

    this.markers.set(id, marker);
    hilog.info(DOMAIN, TAG, `Feeder marker added: ${id}`);
  }

  // 绘制轨迹线
  async drawTrajectory(id: string, points: LocationPoint[]): Promise<void> {
    if (points.length < 2) {
      hilog.warn(DOMAIN, TAG, 'Not enough points to draw trajectory');
      return;
    }

    await this.removePolyline(id);

    const path = points.map(point => ({
      lat: point.latitude,
      lng: point.longitude,
    }));

    const polyline: SimulatedPolyline = {
      id: id,
      points: path,
      color: '#FF9F43',
      width: 6,
    };

    this.polylines.set(id, polyline);
    hilog.info(DOMAIN, TAG, `Trajectory drawn with ${points.length} points`);
  }

  // 绘制地理围栏
  async drawGeoFence(id: string, center: { latitude: number; longitude: number }, radius: number): Promise<void> {
    await this.removeCircle(id);

    const circle: SimulatedCircle = {
      id: id,
      center: { lat: center.latitude, lng: center.longitude },
      radius: radius,
      strokeColor: '#00B4D8',
    };

    this.circles.set(id, circle);
    hilog.info(DOMAIN, TAG, `Geo fence drawn: radius ${radius}m`);
  }

  // 移除标记
  async removeMarker(id: string): Promise<void> {
    if (this.markers.has(id)) {
      this.markers.delete(id);
      hilog.debug(DOMAIN, TAG, `Marker removed: ${id}`);
    }
  }

  // 移除轨迹线
  async removePolyline(id: string): Promise<void> {
    if (this.polylines.has(id)) {
      this.polylines.delete(id);
      hilog.debug(DOMAIN, TAG, `Polyline removed: ${id}`);
    }
  }

  // 移除圆形
  async removeCircle(id: string): Promise<void> {
    if (this.circles.has(id)) {
      this.circles.delete(id);
      hilog.debug(DOMAIN, TAG, `Circle removed: ${id}`);
    }
  }

  // 清除所有覆盖物
  async clearAllOverlays(): Promise<void> {
    this.markers.clear();
    this.polylines.clear();
    this.circles.clear();
    hilog.info(DOMAIN, TAG, 'All map overlays cleared');
  }

  // 计算两点间距离（Haversine公式）
  calculateDistance(point1: LocationPoint, point2: LocationPoint): number {
    const R = 6371000;
    const lat1 = point1.latitude * Math.PI / 180;
    const lat2 = point2.latitude * Math.PI / 180;
    const deltaLat = (point2.latitude - point1.latitude) * Math.PI / 180;
    const deltaLon = (point2.longitude - point1.longitude) * Math.PI / 180;

    const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1) * Math.cos(lat2) *
      Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  // 获取所有标记点（供UI使用）
  getMarkers(): SimulatedMarker[] {
    return Array.from(this.markers.values());
  }

  // 获取所有轨迹线（供UI使用）
  getPolylines(): SimulatedPolyline[] {
    return Array.from(this.polylines.values());
  }

  // 获取当前中心点
  getCenter(): { lat: number; lng: number } {
    return { ...this.currentCenter };
  }

  // 获取服务状态
  getStatus(): object {
    return {
      isInitialized: this.isInitialized,
      markerCount: this.markers.size,
      polylineCount: this.polylines.size,
      circleCount: this.circles.size,
      center: this.currentCenter,
      zoom: this.currentZoom,
    };
  }

  // 释放资源
  async release(): Promise<void> {
    await this.clearAllOverlays();
    this.isInitialized = false;
    hilog.info(DOMAIN, TAG, 'Map service released');
  }
}

// 单例导出
export const MapService = new MapServiceClass();
