import SwiftUI

struct TrackRow: View {
    let track: Track
    var isResolving: Bool = false
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: track.artUri ?? "")) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color(white: 0.2)
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline).bold()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(track.artist) • \(track.album)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                Spacer()
                if isResolving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isResolving)
    }
}
