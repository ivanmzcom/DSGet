import WidgetKit
import SwiftUI

@main
struct DSGetWidgetBundle: WidgetBundle {
    var body: some Widget {
        DSGetWidget()
    }
}

struct DSGetWidget: Widget {
    let kind: String = "DSGetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DSGetTimelineProvider()) { entry in
            DSGetWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("DSGet Downloads")
        .description("Muestra el estado de tus descargas activas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
