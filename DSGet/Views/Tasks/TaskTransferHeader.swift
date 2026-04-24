//
//  TaskTransferHeader.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct TaskTransferHeader<AddButton: View>: View {
    let layoutWidth: AdaptiveLayoutWidth
    let tasksViewModel: TasksViewModel
    let statusFilter: TaskStatusFilter
    let onStatusFilterChange: ((TaskStatusFilter) -> Void)?
    let addTaskButton: AddButton
    let usesCompactToolbarLayout: Bool

    private var totalCount: Int { tasksViewModel.tasks.count }
    private var downloadingCount: Int { tasksViewModel.tasks.filter(\.isDownloading).count }
    private var pausedCount: Int { tasksViewModel.tasks.filter(\.isPaused).count }
    private var completedCount: Int { tasksViewModel.tasks.filter(\.isCompleted).count }

    private var totalDownloadSpeed: String {
        ByteSize(bytes: tasksViewModel.visibleTasks.reduce(0) { $0 + $1.downloadSpeed.bytes }).formatted
    }

    private var totalUploadSpeed: String {
        ByteSize(bytes: tasksViewModel.visibleTasks.reduce(0) { $0 + $1.uploadSpeed.bytes }).formatted
    }

    private var filterItems: [TaskStatusFilterItem] {
        [
            TaskStatusFilterItem(filter: .all, count: totalCount),
            TaskStatusFilterItem(filter: .downloading, count: downloadingCount),
            TaskStatusFilterItem(filter: .paused, count: pausedCount),
            TaskStatusFilterItem(filter: .completed, count: completedCount)
        ]
    }

    var body: some View {
        #if os(iOS)
        iosHeader
        #else
        macHeader
        #endif
    }

    #if os(iOS)
    private var iosHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 36)

                titleBlock(font: .title3.weight(.semibold))

                Spacer(minLength: 0)

                if layoutWidth == .compact {
                    addTaskButton
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                } else {
                    addTaskButton
                        .labelStyle(.titleAndIcon)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)

            statusFilterStrip
            Divider()
        }
        .background(.bar)
    }
    #endif

    private var macHeader: some View {
        VStack(spacing: 0) {
            if layoutWidth == .compact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 32)
                        titleBlock(font: .headline)
                        Spacer(minLength: 0)
                        addTaskButton
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderedProminent)
                    }

                    transferStats
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 36)
                    titleBlock(font: .title3.weight(.semibold))
                    Spacer(minLength: 0)
                    transferStats
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }

            if !usesCompactToolbarLayout {
                statusFilterStrip
            }

            Divider()
        }
        .background(.bar)
    }

    private func titleBlock(font: Font) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String.localized("tasks.header.transfers"))
                .font(font)
            Text(String.localized("tasks.header.items", totalCount))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var transferStats: some View {
        HStack(spacing: 10) {
            TaskTransferStat(title: String.localized("tasks.header.down"), value: totalDownloadSpeed + "/s")
            TaskTransferStat(title: String.localized("tasks.header.up"), value: totalUploadSpeed + "/s")
            TaskTransferStat(title: String.localized("tasks.header.active"), value: "\(downloadingCount)")
        }
    }

    @ViewBuilder
    private var statusFilterStrip: some View {
        if let onStatusFilterChange {
            TaskStatusFilterStrip(
                items: filterItems,
                selectedFilter: statusFilter,
                select: onStatusFilterChange
            )
        }
    }
}

private struct TaskTransferStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit())
        }
        .frame(minWidth: 56, alignment: .leading)
    }
}

private struct TaskStatusFilterItem: Identifiable {
    let filter: TaskStatusFilter
    let count: Int

    var id: TaskStatusFilter { filter }
}

private struct TaskStatusFilterStrip: View {
    let items: [TaskStatusFilterItem]
    let selectedFilter: TaskStatusFilter
    let select: (TaskStatusFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    TaskStatusChip(
                        title: item.filter.localizedLabel,
                        count: item.count,
                        isSelected: item.filter == selectedFilter
                    ) {
                        select(item.filter)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }
}

private struct TaskStatusChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background(
                isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
