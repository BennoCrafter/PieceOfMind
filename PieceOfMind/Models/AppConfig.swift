import Foundation
import ObservableDefaults

@ObservableDefaults
class AppConfig {
    var expandedTagsIds: Set<UUID> = Set()
    var selectedTagId: UUID?
}
