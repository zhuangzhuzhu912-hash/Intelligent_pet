// 地图服务相关接口
// 用于 MapService 的类型定义

// 地图配置
export interface MapConfig {
  zoomLevel: number;
  minZoomLevel: number;
  maxZoomLevel: number;
  tilt: number;
  bearing: number;
  showTraffic: boolean;
  showBuildings: boolean;
}

// 地图坐标点（通用）
export interface MapPoint {
  lat: number;
  lng: number;
}

// 地图标记点
export interface MapMarker {
  id: string;
  latitude: number;
  longitude: number;
  title: string;
  snippet: string;
}

// 地图轨迹线
export interface MapPolyline {
  id: string;
  points: MapPoint[];
  color: string;
  width: number;
}

// 地图圆形（地理围栏）
export interface MapCircle {
  id: string;
  center: MapPoint;
  radius: number;
  strokeColor: string;
}

// 地图中心点（与 MapPoint 相同，用于语义区分）
export type MapCenter = MapPoint;

// 地图服务状态
export interface MapServiceStatus {
  isInitialized: boolean;
  markerCount: number;
  polylineCount: number;
  circleCount: number;
  center: MapCenter;
  zoom: number;
}
