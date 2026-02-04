import WidgetKit
import SwiftUI

struct QuickLogEntry: TimelineEntry {
    let date: Date
    let dogName: String?
    let lastLogType: String?
    let lastLogTime: Date?
}

struct QuickLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(date: Date(), dogName: "Your Pet", lastLogType: nil, lastLogTime: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
        let entry = QuickLogEntry(
            date: Date(),
            dogName: UserDefaults(suiteName: "group.com.petly.doghealthapp")?.string(forKey: "currentDogName"),
            lastLogType: UserDefaults(suiteName: "group.com.petly.doghealthapp")?.string(forKey: "lastLogType"),
            lastLogTime: UserDefaults(suiteName: "group.com.petly.doghealthapp")?.object(forKey: "lastLogTime") as? Date
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.petly.doghealthapp")
        
        let entry = QuickLogEntry(
            date: Date(),
            dogName: sharedDefaults?.string(forKey: "currentDogName"),
            lastLogType: sharedDefaults?.string(forKey: "lastLogType"),
            lastLogTime: sharedDefaults?.object(forKey: "lastLogTime") as? Date
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickLogWidgetEntryView: View {
    var entry: QuickLogProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }
    
    private var smallWidget: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 28))
                .foregroundColor(.green)
            
            if let dogName = entry.dogName {
                Text(dogName)
                    .font(.headline)
                    .lineLimit(1)
            } else {
                Text("Quick Log")
                    .font(.headline)
            }
            
            Text("Tap to log")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    
                    if let dogName = entry.dogName {
                        Text(dogName)
                            .font(.headline)
                    }
                }
                
                if let lastLogType = entry.lastLogType, let lastLogTime = entry.lastLogTime {
                    Text("Last: \(lastLogType)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(lastLogTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No recent logs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                QuickActionButton(icon: "fork.knife", label: "Meal", action: "meal")
                QuickActionButton(icon: "figure.walk", label: "Walk", action: "walk")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: String
    
    var body: some View {
        Link(destination: URL(string: "doghealthapp://quicklog/\(action)")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.caption2)
            }
            .frame(width: 60, height: 50)
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

struct DogHealthAppWidget: Widget {
    let kind: String = "DogHealthAppWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
            QuickLogWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Log")
        .description("Quickly log meals, walks, and more for your pet.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct DogHealthAppWidgetBundle: WidgetBundle {
    var body: some Widget {
        DogHealthAppWidget()
    }
}

#Preview(as: .systemSmall) {
    DogHealthAppWidget()
} timeline: {
    QuickLogEntry(date: Date(), dogName: "Buddy", lastLogType: "Walk", lastLogTime: Date().addingTimeInterval(-3600))
}

#Preview(as: .systemMedium) {
    DogHealthAppWidget()
} timeline: {
    QuickLogEntry(date: Date(), dogName: "Buddy", lastLogType: "Walk", lastLogTime: Date().addingTimeInterval(-3600))
}
