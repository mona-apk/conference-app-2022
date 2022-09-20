import CommonComponents
import ComposableArchitecture
import Model
import SafariView
import Strings
import SwiftUI
import Theme

public struct SponsorState: Equatable {
    public var sponsors: [Sponsor]

    public init(sponsors: [Sponsor] = []) {
        self.sponsors = sponsors
    }
}

public enum SponsorAction {
    case refresh
    case refreshResponse(TaskResult<[Sponsor]>)
}
public struct SponsorEnvironment {
    public let sponsorsRepository: SponsorsRepository

    public init(sponsorsRepository: SponsorsRepository) {
        self.sponsorsRepository = sponsorsRepository
    }
}
public let sponsorReducer = Reducer<SponsorState, SponsorAction, SponsorEnvironment> { state, action, environment in
    switch action {
    case .refresh:
        return .run { @MainActor subscriber in
            for try await result: [Sponsor] in environment.sponsorsRepository.sponsors().stream() {
                await subscriber.send(
                    .refreshResponse(
                        TaskResult {
                            result
                        }
                    )
                )
            }
        }
        .receive(on: DispatchQueue.main.eraseToAnyScheduler())
        .eraseToEffect()
    case .refreshResponse(.success(let sponsors)):
        state.sponsors = sponsors
        return .none
    case .refreshResponse(.failure):
        return .none
    }
}

public struct SponsorView: View {
    private let store: Store<SponsorState, SponsorAction>

    public init(store: Store<SponsorState, SponsorAction>) {
        self.store = store
    }

    @State private var sheetItem: SheetItem?
    private struct SheetItem: Identifiable {
        var id: UUID = UUID()
        var sponsor: Sponsor
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SponsorGridView(
                        title: "PLATINUM SPONSORS",
                        sponsors: viewStore.sponsors.filter { $0.plan == .platinum },
                        columns: 1
                    )
                    .onTapItem { sponsor in
                        sheetItem = SheetItem(sponsor: sponsor)
                    }
                    Divider().padding(.horizontal, 16)
                    SponsorGridView(
                        title: "GOLD SPONSORS",
                        sponsors: viewStore.sponsors.filter { $0.plan == .gold },
                        columns: 2
                    )
                    .onTapItem { sponsor in
                        sheetItem = SheetItem(sponsor: sponsor)
                    }
                    Divider().padding(.horizontal, 16)
                    SponsorGridView(
                        title: "SPONSORS",
                        sponsors: viewStore.sponsors.filter { $0.plan == .supporter },
                        columns: 2
                    )
                    .onTapItem { sponsor in
                        sheetItem = SheetItem(sponsor: sponsor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .task {
                viewStore.send(.refresh)
            }
            .sheet(item: $sheetItem) { item in
                if let url = URL(string: item.sponsor.link) {
                    SafariView(url: url)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(minHeight: 0, maxHeight: .infinity)
            .background(AssetColors.background.swiftUIColor)
            .foregroundColor(AssetColors.onBackground.swiftUIColor)
            .navigationTitle(L10n.Sponsor.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SponsorGridView: View {

    let title: String
    let sponsors: [Sponsor]
    let columns: Int
    var action: (Sponsor) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .default))
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 16), count: columns), spacing: 16) {
                ForEach(sponsors, id: \.self) { sponsor in
                    SponsorItemView(sponsor: sponsor) {
                        action(sponsor)
                    }
                }
            }
        }
    }

    func onTapItem(perform action: @escaping (Sponsor) -> Void) -> some View {
        var view = self
        view.action = action
        return view
    }
}

struct SponsorItemView: View {

    let sponsor: Sponsor
    let action: () -> Void

    var body: some View {
        ZStack {
            AssetColors.white.swiftUIColor
            Button {
                action()
            } label: {
                NetworkImage(url: URL(string: sponsor.logo))
                    .scaledToFit()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(minHeight: 0, maxHeight: .infinity)
            }
        }
        .frame(height: height(of: sponsor.plan))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func height(of plan: Plan) -> CGFloat {
        switch plan {
        case .platinum:
            return 112
        case .gold:
            return 112
        case .supporter:
            return 72
        default:
            return 72
        }
    }
}

#if DEBUG
struct SponsorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SponsorView(
                store: .init(
                    initialState: .init(
                        sponsors: Sponsor.companion.fakes()
                    ),
                    reducer: .empty,
                    environment: SponsorEnvironment(
                        sponsorsRepository: FakeSponsorsRepository()
                    )
                )
            )
        }
    }
}
#endif
