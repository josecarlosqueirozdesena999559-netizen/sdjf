import SwiftUI
import CoreLocation
#if canImport(MapboxMaps)
import MapboxMaps
#endif

struct Mapbox3DMapView: View {
    @ObservedObject var store: TrilhaGameStore
    var onSelectStore: (StoreLocation) -> Void

    var body: some View {
        ZStack {
            #if canImport(MapboxMaps)
            MapboxRepresentable(store: store, onSelectStore: onSelectStore)
                .ignoresSafeArea()
            #else
            Fallback3DMapCanvas(store: store, onSelectStore: onSelectStore)
                .ignoresSafeArea()
            #endif

            // Horizonte suave no topo (céu/neblina)
            VStack {
                LinearGradient(
                    colors: [
                        Color(hex: "#93C5FD").opacity(0.65),
                        Color(hex: "#E0F2FE").opacity(0.25),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
                Spacer()
            }
            .ignoresSafeArea()

            // Avatar centralizado com anel de radar nos pés
            PlayerRadarOverlay(avatarId: store.selectedAvatarId, teamColor: store.selectedTeam.color)
                .allowsHitTesting(false)
        }
    }
}

private struct PlayerRadarOverlay: View {
    let avatarId: Int
    let teamColor: Color
    @State private var expand = false

    var body: some View {
        ZStack {
            // Anel de alcance 40m (radar) no chão inclinado
            Ellipse()
                .stroke(teamColor.opacity(0.55), lineWidth: 2)
                .fill(teamColor.opacity(0.08))
                .frame(width: 150, height: 78)
                .offset(y: 28)

            Ellipse()
                .stroke(teamColor.opacity(expand ? 0 : 0.45), lineWidth: 2)
                .frame(width: expand ? 180 : 90, height: expand ? 92 : 46)
                .offset(y: 28)
                .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: expand)

            VStack(spacing: 2) {
                Image("avatar_\(avatarId)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(TrilhaColors.pureWhite, lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 4)

                Capsule()
                    .fill(Color.black.opacity(0.22))
                    .frame(width: 30, height: 8)
            }
        }
        .onAppear { expand = true }
    }
}

#if canImport(MapboxMaps)
private struct MapboxRepresentable: UIViewRepresentable {
    @ObservedObject var store: TrilhaGameStore
    var onSelectStore: (StoreLocation) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store, onSelectStore: onSelectStore)
    }

    func makeUIView(context: Context) -> MapView {
        let token = (Bundle.main.infoDictionary?["MBXAccessToken"] as? String) ?? ""
        if !token.isEmpty {
            MapboxOptions.accessToken = token
        }
        let camera = CameraOptions(
            center: store.userLocation,
            zoom: 17.2,
            bearing: 0,
            pitch: 60
        )
        let initOptions = MapInitOptions(cameraOptions: camera, styleURI: .light)
        let mapView = MapView(frame: .zero, mapInitOptions: initOptions)
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.ornaments.options.compass.visibility = .hidden

        context.coordinator.attach(mapView: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        mapView.mapboxMap.setCamera(to: CameraOptions(center: store.userLocation, zoom: 17.2, pitch: 60))
        context.coordinator.syncAnnotations(store: store)
    }

    final class Coordinator: NSObject {
        private var store: TrilhaGameStore
        private var onSelectStore: (StoreLocation) -> Void
        private weak var mapView: MapView?
        private var polygonManager: PolygonAnnotationManager?
        private var polylineManager: PolylineAnnotationManager?
        private var pointManager: PointAnnotationManager?
        private var storeIdByAnnotationId: [String: StoreLocation] = [:]

        init(store: TrilhaGameStore, onSelectStore: @escaping (StoreLocation) -> Void) {
            self.store = store
            self.onSelectStore = onSelectStore
        }

        func attach(mapView: MapView) {
            self.mapView = mapView
            mapView.mapboxMap.onStyleLoaded.observeNext { [weak self, weak mapView] _ in
                guard let self, let mapView else { return }
                self.applyCustom3DMapStyle(mapView.mapboxMap)
                self.polygonManager = mapView.annotations.makePolygonAnnotationManager()
                self.polylineManager = mapView.annotations.makePolylineAnnotationManager()
                self.pointManager = mapView.annotations.makePointAnnotationManager()
                self.pointManager?.delegate = self
                self.syncAnnotations(store: self.store)
            }.store(in: &cancellables)
        }

        private var cancellables = Set<MapboxMaps.AnyCancelable>()

        private func applyCustom3DMapStyle(_ mapboxMap: MapboxMap) {
            // Chão em verde-menta claro, ruas cinza-ardósia com bordas amarelas suaves e prédios 3D translúcidos
            try? mapboxMap.setLayerProperty(for: "land", property: "background-color", value: "#BCEBCB")
            try? mapboxMap.setLayerProperty(for: "road-primary", property: "line-color", value: "#546878")
            try? mapboxMap.setLayerProperty(for: "road-secondary-tertiary", property: "line-color", value: "#546878")
            try? mapboxMap.setLayerProperty(for: "road-street", property: "line-color", value: "#546878")
            try? mapboxMap.setLayerProperty(for: "road-primary-case", property: "line-color", value: "#FDE68A")
            try? mapboxMap.setLayerProperty(for: "road-street-case", property: "line-color", value: "#FDE68A")

            var buildingLayer = FillExtrusionLayer(id: "trilha-3d-buildings", source: "composite")
            buildingLayer.sourceLayer = "building"
            buildingLayer.minZoom = 15.0
            buildingLayer.fillExtrusionColor = .constant(StyleColor(UIColor(red: 0.56, green: 0.87, blue: 0.82, alpha: 0.65)))
            buildingLayer.fillExtrusionHeight = .expression(Exp(.get) { "height" })
            buildingLayer.fillExtrusionBase = .expression(Exp(.get) { "min_height" })
            buildingLayer.fillExtrusionOpacity = .constant(0.65)
            try? mapboxMap.addLayer(buildingLayer)
        }

        func syncAnnotations(store: TrilhaGameStore) {
            self.store = store

            if let polyMgr = polygonManager {
                polyMgr.annotations = store.territories.map { hex in
                    var ann = PolygonAnnotation(polygon: Polygon([hex.vertices]))
                    let baseColor: UIColor = {
                        switch hex.ownerTeam {
                        case .esmeralda: return UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 0.28)
                        case .horizonte: return UIColor(red: 14/255, green: 165/255, blue: 233/255, alpha: 0.26)
                        case .solar: return UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 0.26)
                        case .none: return UIColor.white.withAlphaComponent(0.12)
                        }
                    }()
                    ann.fillColor = StyleColor(baseColor)
                    ann.fillOutlineColor = StyleColor(UIColor.white.withAlphaComponent(0.55))
                    return ann
                }
            }

            if let lineMgr = polylineManager {
                if store.isWorkoutActive, store.workoutRoute.count >= 2 {
                    var line = PolylineAnnotation(lineCoordinates: store.workoutRoute)
                    line.lineColor = StyleColor(UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0))
                    line.lineWidth = 5.0
                    lineMgr.annotations = [line]
                } else {
                    lineMgr.annotations = []
                }
            }

            if let ptMgr = pointManager {
                storeIdByAnnotationId.removeAll()
                var points: [PointAnnotation] = []
                for s in store.stores {
                    var ann = PointAnnotation(coordinate: s.coordinate)
                    let imgName = (s.hasPremiumChest && s.premiumAvailableToday) ? "obj_chest_premium" : "obj_chest_common"
                    if let img = UIImage(named: imgName) {
                        ann.image = .init(image: img, name: imgName)
                    }
                    ann.iconSize = 0.24
                    storeIdByAnnotationId[ann.id] = s
                    points.append(ann)
                }
                for keyCoord in store.floatingKeys {
                    var ann = PointAnnotation(coordinate: keyCoord)
                    if let img = UIImage(named: "obj_key_3d") {
                        ann.image = .init(image: img, name: "obj_key_3d")
                    }
                    ann.iconSize = 0.20
                    points.append(ann)
                }
                ptMgr.annotations = points
            }
        }
    }
}

extension MapboxRepresentable.Coordinator: AnnotationInteractionDelegate {
    func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
        for ann in annotations {
            if let s = storeIdByAnnotationId[ann.id] {
                Task { @MainActor in
                    self.onSelectStore(s)
                }
                break
            }
        }
    }
}
#endif

private struct Fallback3DMapCanvas: View {
    @ObservedObject var store: TrilhaGameStore
    var onSelectStore: (StoreLocation) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#A7F3D0"), TrilhaColors.mapMintGround],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 12) {
                ForEach(store.stores) { s in
                    Button {
                        onSelectStore(s)
                    } label: {
                        HStack {
                            Image(s.hasPremiumChest && s.premiumAvailableToday ? "obj_chest_premium" : "obj_chest_common")
                                .resizable().scaledToFit().frame(width: 36, height: 36)
                            Text(s.name).font(TrilhaFont.body(14, weight: .semibold)).foregroundStyle(TrilhaColors.darkText)
                        }
                        .padding(10)
                        .background(TrilhaColors.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }
}
