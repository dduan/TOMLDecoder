package struct TwitterArchive: Codable, Equatable {
    let statuses: [Status]

    package struct Status: Codable, Equatable {
        let id: UInt64
        let lang: String
        let text: String
        let source: String
        let metadata: [String: String]
        let user: User
        let place: String?
    }

    package struct StatusEntities: Codable, Equatable {
        let hashtags: [Hashtag]
        let media: [MediaItem]
    }

    package struct Hashtag: Codable, Equatable {
        let indices: [UInt64]
        let text: String
    }

    package struct MediaItem: Codable, Equatable {
        let display_url: String
        let expanded_url: String
        let id: UInt64
        let indices: [UInt64]
        let media_url: String
        let source_status_id: UInt64
        let type: String
        let url: String

        package struct Size: Codable, Equatable {
            let h: UInt64
            let w: UInt64
            let resize: String
        }

        let sizes: [String: Size]
    }

    package struct User: Codable, Equatable {
        let created_at: String
        let default_profile: Bool
        let description: String
        let favourites_count: UInt64
        let followers_count: UInt64
        let friends_count: UInt64
        let id: UInt64
        let lang: String
        let name: String
        let profile_background_color: String
        let profile_background_image_url: String
        let profile_banner_url: String?
        let profile_image_url: String?
        let profile_use_background_image: Bool
        let screen_name: String
        let statuses_count: UInt64
        let url: String?
        let verified: Bool
    }
}
