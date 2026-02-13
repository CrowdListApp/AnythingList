import Foundation

enum AnythingTemplateLibrary {
    static let all: [AnythingTemplateDocument] = [
        AnythingTemplateDocument(
            version: "1.0",
            title: "WWDC Watch Log",
            subtitle: "Track session watch history",
            symbol: "play.rectangle.on.rectangle",
            fields: [
                .init(id: "session_title", key: "sessionTitle", title: "Session Title", kind: .text),
                .init(id: "session_url", key: "url", title: "URL", kind: .url),
                .init(id: "watched_at", key: "watchedAt", title: "Watched At", kind: .dateTime)
            ]
        ),
        AnythingTemplateDocument(
            version: "1.0",
            title: "Habit Tracker",
            subtitle: "Keep habits moving",
            symbol: "checkmark.circle",
            fields: [
                .init(id: "habit_name", key: "name", title: "Habit", kind: .text),
                .init(id: "last_done", key: "lastExecutedAt", title: "Last Executed", kind: .dateTime),
                .init(id: "done_today", key: "doneToday", title: "Done Today", kind: .toggle, isRequired: false)
            ]
        ),
        AnythingTemplateDocument(
            version: "1.0",
            title: "Anime List",
            subtitle: "Track what to watch",
            symbol: "tv",
            fields: [
                .init(id: "anime_title", key: "title", title: "Title", kind: .text),
                .init(id: "episodes", key: "episodes", title: "Episodes", kind: .number),
                .init(id: "status", key: "status", title: "Status", kind: .text, isRequired: false)
            ]
        ),
        AnythingTemplateDocument(
            version: "1.0",
            title: "Book List",
            subtitle: "Books to read",
            symbol: "books.vertical",
            fields: [
                .init(id: "book_title", key: "title", title: "Title", kind: .text),
                .init(id: "author", key: "author", title: "Author", kind: .text),
                .init(id: "read", key: "isRead", title: "Finished", kind: .toggle, isRequired: false)
            ]
        ),
        AnythingTemplateDocument(
            version: "1.0",
            title: "Game Backlog",
            subtitle: "What to play next",
            symbol: "gamecontroller",
            fields: [
                .init(id: "game_title", key: "title", title: "Title", kind: .text),
                .init(id: "platform", key: "platform", title: "Platform", kind: .text, isRequired: false),
                .init(id: "status", key: "status", title: "Status", kind: .text)
            ]
        ),
        AnythingTemplateDocument(
            version: "1.0",
            title: "Subscription Tracker",
            subtitle: "Video/creator subscriptions",
            symbol: "bell.badge",
            fields: [
                .init(id: "channel", key: "channel", title: "Channel", kind: .text),
                .init(id: "url", key: "url", title: "URL", kind: .url, isRequired: false),
                .init(id: "started", key: "startedAt", title: "Started", kind: .date)
            ]
        )
    ]
}
