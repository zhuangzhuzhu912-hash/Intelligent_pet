// 服务模型统一导出
// 集中导出所有服务相关的接口定义

// 地图服务模型
export type {
  MapConfig,
  MapPoint,
  MapMarker,
  MapPolyline,
  MapCircle,
  MapCenter,
  MapServiceStatus
} from './MapModels';

// 定位服务模型
export type {
  LocationServiceStatus
} from './LocationModels';

// 硬件服务模型
export type {
  CollarGpioPins,
  CollarPwmPins,
  CollarAdcPins,
  CollarConfig,
  CollarHardwareServiceStatus,
  FeederGpioPins,
  FeederPwmPins,
  FeederAdcPins,
  FeederServoConfig,
  FeederWeightSensorConfig,
  FeederConfig,
  FeederHardwareServiceStatus
} from './HardwareServiceModels';
