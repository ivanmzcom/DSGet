//
//  ContentView.swift
//  iDSGet Watch App
//
//  Created by Iván Moreno Zambudio on 25/1/26.
//

import SwiftUI
import DSGetCore

struct ContentView: View {
    @State private var viewModel = WatchTasksViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView("Loading...")
                } else if viewModel.tasks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Downloads")
                            .font(.headline)
                        Text("Add tasks from your iPhone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(viewModel.tasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            await viewModel.loadTasks()
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: DownloadTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)
                .lineLimit(2)

            HStack {
                statusIcon
                Text(task.status.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if task.isDownloading || task.status == .waiting {
                ProgressView(value: task.progress)
                    .progressViewStyle(.linear)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .downloading:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.blue)
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .paused:
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(.orange)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        default:
            Image(systemName: "clock.fill")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
