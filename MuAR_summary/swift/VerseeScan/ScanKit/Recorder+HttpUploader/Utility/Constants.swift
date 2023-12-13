//
//  Constants.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/14.
//
import Foundation

struct Constants {
    static let sceneTypes: [String] = ["Please Select A Scene Type",
                                       "Apartment",
                                       "Bathroom",
                                       "Bedroom / Hotel",
                                       "Bookstore / Library",
                                       "Classroom",
                                       "Closet",
                                       "ComputerCluster",
                                       "Conference Room",
                                       "Copy Room",
                                       "Copy/Mail Room",
                                       "Dining Room",
                                       "Game room",
                                       "Gym",
                                       "Hallway",
                                       "Kitchen",
                                       "Laundromat",
                                       "Laundry Room",
                                       "Living room / Lounge",
                                       "Lobby",
                                       "Mailboxes",
                                       "Misc.",
                                       "Office",
                                       "Stairs",
                                       "Storage/Basement/Garage"]
    
    struct Server {
        static let chuckSize = 4096
        
        struct Endpoints {
            static let upload: String = "/upload"
            static let verify: String = "/verify"
        }
    }
}
