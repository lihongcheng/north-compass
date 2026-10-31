import SwiftUI
import CoreLocation

private enum Palette {
    static let background = Color(red: 0.055, green: 0.075, blue: 0.085)
    static let surface = Color(red: 0.09, green: 0.115, blue: 0.125)
    static let ivory = Color(red: 0.94, green: 0.92, blue: 0.84)
    static let muted = Color(red: 0.57, green: 0.63, blue: 0.63)
    static let gold = Color(red: 0.87, green: 0.73, blue: 0.47)
    static let red = Color(red: 0.98, green: 0.36, blue: 0.30)
}

struct CompassView: View {
    @StateObject private var model = CompassModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingHelp = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: geometry.size.height < 760 ? 10 : 20) {
                    header
                    headingReadout
                    CompassDial(rotation: model.dialRotation, lockedBearing: model.lockedBearing)
                        .frame(width: dialSize(geometry.size), height: dialSize(geometry.size))
                        .frame(maxWidth: .infinity)
                        .opacity(model.heading == nil ? 0.45 : 1)
                        .accessibilityHidden(true)
                    statusLine
                    controls
                    locationPanel
                    Text("手机顶部所指，即为当前方向")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.muted)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .foregroundColor(Palette.ivory)
        .sheet(isPresented: $showingHelp) { helpSheet }
        .onAppear { if scenePhase == .active { model.start() } }
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.start() } else { model.stop() }
        }
    }

    private func dialSize(_ size: CGSize) -> CGFloat {
        min(size.width - 64, size.height * 0.40, 350)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("寻北").font(.system(size: 25, weight: .semibold, design: .serif)).tracking(4)
                Text("FIND YOUR BEARING").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(2.5).foregroundColor(Palette.muted)
            }
            Spacer()
            Button { showingHelp = true } label: {
                Image(systemName: "info.circle").font(.system(size: 20)).foregroundColor(Palette.muted)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("使用与校准说明")
        }
    }

    private var headingReadout: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(model.heading.map { String(CompassMath.degrees($0)) } ?? "—")
                    .font(.system(size: 72, weight: .light, design: .rounded)).monospacedDigit()
                Text("°").font(.system(size: 40, weight: .ultraLight)).foregroundColor(Palette.gold)
            }
            Text(model.heading.map { CompassMath.cardinal($0) } ?? "等待方向")
                .font(.system(size: 15, weight: .medium)).tracking(4).foregroundColor(Palette.gold)
        }
        .frame(height: 112)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.heading.map { "\(CompassMath.cardinal($0))，\(CompassMath.degrees($0)) 度，\(model.referenceName)" } ?? model.status)
    }

    private var statusLine: some View {
        HStack(spacing: 7) {
            Circle().fill(model.heading == nil || model.accuracy > 20 ? Palette.gold : Color(red: 0.51, green: 0.75, blue: 0.65)).frame(width: 5, height: 5)
            Text(model.status).font(.system(size: 12, design: .monospaced)).foregroundColor(Palette.muted)
        }
        .padding(.top, -6)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    northButton("磁北", enabled: false)
                    northButton("真北", enabled: true)
                }
                .padding(4).background(Palette.surface).clipShape(Capsule())
                Button { model.toggleLock() } label: {
                    Label(model.lockedBearing == nil ? "锁定方向" : "解除锁定", systemImage: model.lockedBearing == nil ? "scope" : "lock.open")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .foregroundColor(model.lockedBearing == nil ? Palette.ivory : Palette.background)
                        .background(model.lockedBearing == nil ? Palette.surface : Palette.gold)
                        .clipShape(Capsule())
                }
                .disabled(model.heading == nil && model.lockedBearing == nil)
                .opacity(model.heading == nil && model.lockedBearing == nil ? 0.45 : 1)
            }
            if let locked = model.lockedBearing {
                HStack {
                    Text("目标 \(CompassMath.degrees(locked))°")
                    Spacer()
                    Text(model.guidance)
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Palette.gold)
                .padding(.horizontal, 10)
            } else if model.usesTrueNorth && !model.trueNorthAvailable {
                Text(model.locationDenied ? "定位未授权，当前使用磁北" : "真北等待定位，当前使用磁北")
                    .font(.system(size: 11)).foregroundColor(Palette.gold)
            }
        }
    }

    private func northButton(_ title: String, enabled: Bool) -> some View {
        Button { model.selectTrueNorth(enabled) } label: {
            Text(title).font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity).frame(height: 38)
                .foregroundColor(model.usesTrueNorth == enabled ? Palette.background : Palette.muted)
                .background(model.usesTrueNorth == enabled ? Palette.ivory : Color.clear)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(model.usesTrueNorth == enabled ? .isSelected : [])
    }

    private var locationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("所在位置", systemImage: "location").font(.system(size: 11)).foregroundColor(Palette.muted)
                Spacer()
                if let location = model.location {
                    Text("±\(Int(location.horizontalAccuracy.rounded())) m").font(.system(size: 10, design: .monospaced)).foregroundColor(Palette.muted)
                }
            }
            if let location = model.location {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "%@ %.4f°", location.coordinate.latitude >= 0 ? "N" : "S", abs(location.coordinate.latitude)))
                        Text(String(format: "%@ %.4f°", location.coordinate.longitude >= 0 ? "E" : "W", abs(location.coordinate.longitude)))
                    }.font(.system(size: 15, weight: .medium, design: .monospaced))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("海拔").font(.system(size: 10)).foregroundColor(Palette.muted)
                        Text(location.verticalAccuracy >= 0 ? "\(Int(location.altitude.rounded())) m" : "— m")
                            .font(.system(size: 17, weight: .light, design: .monospaced))
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Text(model.locationDenied ? "开启定位可显示经纬度与真北" : (model.locationError ?? (model.locationRequested ? "正在获取位置…" : "开启定位，查看经纬度与海拔")))
                        .font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button(model.locationDenied ? "设置" : (model.locationRequested ? "重试" : "开启")) {
                        if model.locationDenied {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        } else { model.requestLocation() }
                    }
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Palette.gold)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .padding(16)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var helpSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    helpItem("safari", "找到方向", "将手机大致放平，手机顶部指向你要测量的方向。红色 N 标记始终指向北方；顶部金色标记代表手机朝向。")
                    helpItem("location.north", "磁北与真北", "磁北来自手机磁力计，无需获取位置。真北指向地理北极，需要定位修正；定位不可用时会明确显示并使用磁北。")
                    helpItem("scope", "锁定一个方向", "点击「锁定方向」保存当前朝向。转动手机后，下方会显示回到目标需要向左或向右转多少度，对准时会轻触振动。切换北向基准或离开应用会清除锁定。")
                    helpItem("arrow.triangle.2.circlepath", "读数不稳定时", "远离磁吸手机壳、音箱和金属物体。轻缓地用手机在空中画几次 8 字，再放平观察。精度数值越小，方向越可信。")
                    helpItem("hand.raised", "位置留在设备上", "仅在你开启位置或选择真北后请求定位。应用不上传位置，不接入广告或分析服务；离开应用后停止传感器和定位更新。海拔与方位仅作日常参考。")
                }.padding(24)
            }
            .background(Palette.background)
            .navigationTitle("使用指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showingHelp = false }.tint(Palette.gold) } }
        }.preferredColorScheme(.dark)
    }

    private func helpItem(_ icon: String, _ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline).foregroundColor(Palette.gold)
            Text(body).font(.system(size: 15)).lineSpacing(5).foregroundColor(Palette.ivory)
        }
    }
}

private struct CompassDial: View {
    let rotation: Double
    let lockedBearing: Double?

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            ZStack {
                Circle().fill(RadialGradient(colors: [Palette.surface, Palette.background], center: .center, startRadius: 5, endRadius: side / 2))
                Circle().stroke(Palette.muted.opacity(0.18), lineWidth: 1)
                Circle().stroke(Palette.muted.opacity(0.10), lineWidth: 1).padding(43)
                ZStack {
                    ForEach(0..<120) { tick in
                        Rectangle()
                            .fill(tick == 0 ? Palette.red : Palette.ivory.opacity(tick % 10 == 0 ? 0.9 : (tick % 5 == 0 ? 0.5 : 0.2)))
                            .frame(width: tick % 10 == 0 ? 2 : 1, height: tick % 10 == 0 ? 20 : (tick % 5 == 0 ? 13 : 7))
                            .offset(y: -side / 2 + 20)
                            .rotationEffect(.degrees(Double(tick) * 3))
                    }
                    ForEach(0..<8) { index in
                        let angle = Double(index) * 45
                        Text(["N", "NE", "E", "SE", "S", "SW", "W", "NW"][index])
                            .font(.system(size: index % 2 == 0 ? 23 : 10, weight: index == 0 ? .bold : .regular, design: .monospaced))
                            .foregroundColor(index == 0 ? Palette.red : (index % 2 == 0 ? Palette.ivory : Palette.muted))
                            .rotationEffect(.degrees(rotation - angle))
                            .offset(y: -side / 2 + 64)
                            .rotationEffect(.degrees(angle))
                    }
                    Needle().fill(Palette.red).frame(width: 19, height: side * 0.24).offset(y: -side * 0.12)
                    Needle().fill(Palette.ivory.opacity(0.18)).frame(width: 19, height: side * 0.24).rotationEffect(.degrees(180)).offset(y: side * 0.12)
                    if let lockedBearing {
                        Circle().fill(Palette.gold).frame(width: 9, height: 9)
                            .offset(y: -side / 2 + 4).rotationEffect(.degrees(lockedBearing))
                    }
                }
                .rotationEffect(.degrees(-rotation))
                .animation(.linear(duration: 0.15), value: rotation)
                Path { p in
                    p.move(to: CGPoint(x: side / 2 - 18, y: side / 2))
                    p.addLine(to: CGPoint(x: side / 2 + 18, y: side / 2))
                    p.move(to: CGPoint(x: side / 2, y: side / 2 - 18))
                    p.addLine(to: CGPoint(x: side / 2, y: side / 2 + 18))
                }.stroke(Palette.ivory.opacity(0.3), lineWidth: 1)
                Circle().fill(Palette.background).frame(width: 12, height: 12)
                Circle().stroke(Palette.gold, lineWidth: 1.5).frame(width: 8, height: 8)
                Needle().fill(Palette.gold).frame(width: 12, height: 14).rotationEffect(.degrees(180)).offset(y: -side / 2 - 2)
            }
        }
    }
}

private struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.87))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
