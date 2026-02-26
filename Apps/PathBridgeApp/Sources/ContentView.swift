import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PathBridge")
                .font(.title2)
                .fontWeight(.semibold)
            Text("工程骨架已初始化，可开始实现 Finder 工具栏与终端适配链路。")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 220)
    }
}
