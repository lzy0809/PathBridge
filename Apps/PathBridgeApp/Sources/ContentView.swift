import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PathBridge")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Finder 扩展已可触发打开 Terminal。当前已接入扩展到主应用的请求通道（分布式通知），并保留直开兜底。")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 220)
    }
}
