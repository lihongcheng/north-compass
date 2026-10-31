# 寻北 · North Compass

原生 SwiftUI / Core Location 指南针。最低 iOS 16.0，面向 iPhone 8 Plus / iOS 16.7.10，竖屏使用，无第三方运行依赖。

## 使用

- 手机大致放平，顶部朝向测量方向。大字为当前角度，红色 N 和指针指向北方。
- 默认磁北；选择真北后使用定位数据修正。真北不可用时明确提示并回退到磁北。
- 「锁定方向」保存当前方位，显示回到目标需向左或向右转多少度；对准时轻触反馈。
- 「所在位置」显示经纬度、水平定位精度和海拔。权限被拒绝时可进入系统设置，指南针仍保留磁北模式。
- 右上角说明包含磁场干扰与校准方法。离开应用时停止定位、方向更新并清除锁定。

所有位置处理在设备上完成，不包含服务器、广告或分析 SDK。磁力计易受磁吸配件和金属干扰，方位与海拔仅供日常参考。

## 开发与安装

1. 在 Xcode 打开 `NorthCompass.xcodeproj`，选择 `NorthCompass` scheme。
2. 连接 iPhone，在运行目标中选择手机，按 Command-R 安装并启动。
3. 已配置当前本机 Personal Team 自动签名；换电脑或账号时在 Signing & Capabilities 选择自己的 Team，并使用唯一 Bundle Identifier。

```bash
./scripts/test.sh
./scripts/build-device.sh
```

当前 Bundle Identifier：`dev.northcompass.app.b451bc`。开发签名有效期至 **2026-11-07 22:45（北京时间）**；到期后连接本机、通过 Xcode 重新构建安装即可续签。

## 代码

- `CompassModel.swift`：传感器、权限、生命周期、北向基准回退、方向锁定。
- `CompassMath.swift`：角度归一化、最短转角和八方位计算。
- `CompassView.swift`：自绘表盘、中文界面、位置与帮助页。
- `Tests/main.swift`：跨越 0°、左右转向、多圈旋转和方位边界测试。
- `scripts/make-icon.swift`：AppKit 图标绘制源；PNG 已包含在工程中，无需重新生成。

Debug 构建支持 `--preview-heading` 参数，仅用于无磁力计的模拟器界面检查；真机正常启动不传此参数。模拟器不能验证真实磁场精度。

API 参考：[Apple CLLocationManager](https://developer.apple.com/documentation/corelocation/cllocationmanager)、[Apple CLHeading](https://developer.apple.com/documentation/corelocation/clheading)。
