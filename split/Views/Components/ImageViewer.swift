import SwiftUI

struct ImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 5)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale <= 1 {
                                    withAnimation {
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale > 1 {
                                scale = 1
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                            }
                        }
                    }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct ZoomableImageView: View {
    let imageData: Data
    @State private var showingFullScreen = false

    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
                .onTapGesture {
                    showingFullScreen = true
                }
                .fullScreenCover(isPresented: $showingFullScreen) {
                    ImageViewer(image: uiImage)
                }
        }
    }
}

struct TappableImage: View {
    let image: UIImage
    @State private var showingFullScreen = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .onTapGesture {
                showingFullScreen = true
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                ImageViewer(image: image)
            }
    }
}

#Preview {
    if let image = UIImage(systemName: "photo") {
        ImageViewer(image: image)
    }
}
