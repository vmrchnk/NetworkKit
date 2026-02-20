//
//  DownloadDemoView.swift
//  Example
//

import SwiftUI
import NetworkKit

// MARK: - Download Request

struct DownloadFileRequest: Request, Sendable {
    struct Response: Decodable, Sendable {}

    let fileURL: String

    var baseURL: String? { "" }
    var path: String { fileURL }
    var method: HTTPMethod { .get }
}

// MARK: - Sample File

struct SampleFile: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let size: String
}

// MARK: - View

struct DownloadDemoView: View {
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadedFileURL: URL?
    @State private var errorMessage: String?
    @State private var selectedFile: SampleFile?

    private let sampleFiles: [SampleFile] = [
        SampleFile(
            name: "Big Buck Bunny (MP4)",
            url: "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4",
            size: "~60 MB"
        ),
        SampleFile(
            name: "Sintel Trailer (MP4)",
            url: "https://download.blender.org/durian/trailer/sintel_trailer-480p.mp4",
            size: "~18 MB"
        ),
        SampleFile(
            name: "Elephants Dream (MP4)",
            url: "https://download.blender.org/ED/ED_1024.avi",
            size: "~120 MB"
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Progress Card
                progressCard

                // File Selection
                fileSelectionList

                Spacer()
            }
            .padding()
            .navigationTitle("Download Demo")
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isDownloading ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)

                if isDownloading {
                    Circle()
                        .trim(from: 0, to: downloadProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: downloadProgress)
                }

                Image(systemName: downloadIcon)
                    .font(.system(size: 30))
                    .foregroundStyle(iconColor)
            }

            // Status Text
            Text(statusText)
                .font(.headline)

            // Progress Bar
            if isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                        .tint(.blue)

                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Downloaded File Info
            if let fileURL = downloadedFileURL {
                VStack(spacing: 4) {
                    Text("Saved to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(fileURL.lastPathComponent)
                        .font(.caption.monospaced())
                        .foregroundStyle(.blue)
                }
            }

            // Error Message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    private var downloadIcon: String {
        if downloadedFileURL != nil {
            return "checkmark.circle.fill"
        } else if isDownloading {
            return "arrow.down.circle"
        } else if errorMessage != nil {
            return "exclamationmark.circle"
        } else {
            return "arrow.down.circle"
        }
    }

    private var iconColor: Color {
        if downloadedFileURL != nil {
            return .green
        } else if errorMessage != nil {
            return .red
        } else {
            return .blue
        }
    }

    private var statusText: String {
        if downloadedFileURL != nil {
            return "Download Complete"
        } else if isDownloading {
            return "Downloading..."
        } else if errorMessage != nil {
            return "Download Failed"
        } else {
            return "Select a file to download"
        }
    }

    // MARK: - File Selection

    private var fileSelectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sample Files")
                .font(.headline)
                .padding(.horizontal)

            ForEach(sampleFiles) { file in
                Button {
                    Task { await downloadFile(file) }
                } label: {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading) {
                            Text(file.name)
                                .font(.subheadline)
                                .foregroundStyle(.primary)

                            Text(file.size)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedFile?.id == file.id && isDownloading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .disabled(isDownloading)
            }
        }
    }

    // MARK: - Download Action

    private func downloadFile(_ file: SampleFile) async {
        selectedFile = file
        isDownloading = true
        downloadProgress = 0
        downloadedFileURL = nil
        errorMessage = nil

        let fileExtension = URL(string: file.url)?.pathExtension ?? "bin"
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("downloaded_\(UUID().uuidString).\(fileExtension)")

        do {
            for try await event in DownloadFileRequest(fileURL: file.url).download(to: destination) {
                switch event {
                case .progress(let progress):
                    await MainActor.run {
                        downloadProgress = progress
                    }
                case .completed(let url):
                    await MainActor.run {
                        downloadedFileURL = url
                        downloadProgress = 1.0
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isDownloading = false
        }
    }
}

#Preview {
    DownloadDemoView()
}
