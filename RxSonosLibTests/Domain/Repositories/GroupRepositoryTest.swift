//
//  GroupRepositoryTest.swift
//  RxSonosLibTests
//
//  Created by Stefan Renne on 16/03/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
import RxSSDP
import Mockingjay
@testable import RxSonosLib

class GroupRepositoryTest: XCTestCase {
    
    private let ssdpRepository: SSDPRepository = FakeSSDPRepositoryImpl()
    private let roomRepository: RoomRepository = FakeRoomRepositoryImpl()
    private let groupRepository: GroupRepository = GroupRepositoryImpl()
    
    override func setUp() {
        CacheManager.shared.clear(removeLongCache: true)
    }
    
    func testItCanGetGroups() throws {
        
        var response = "<ZoneGroupState>"
            response += "<ZoneGroups>".encodeString()
                response += "<ZoneGroup Coordinator=\"RINCON_000001\" ID=\"RINCON_000001:314\">".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000006\"/>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000007\" Invisible=\"1\"/>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000005\"/>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000001\">".encodeString()
                        response += "<Satellite UUID=\"RINCON_000002\" Invisible=\"1\"/>".encodeString()
                        response += "<Satellite UUID=\"RINCON_000003\" Invisible=\"1\"/>".encodeString()
                        response += "<Satellite UUID=\"RINCON_000004\"/>".encodeString()
                    response += "</ZoneGroupMember>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000008\"/>".encodeString()
                response += "</ZoneGroup>".encodeString()
            response += "</ZoneGroups>".encodeString()
        response += "</ZoneGroupState>"
        stub(soap(call: GroupTarget.state), soapXml(response))
        
        let groups = try groupRepository
            .getGroups(for: getRooms())
            .toBlocking()
            .single()
        
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].master.uuid, "RINCON_000001")
        XCTAssertEqual(groups[0].slaves.count, 4)
        XCTAssertEqual(groups[0].slaves[0].uuid, "RINCON_000006")
        XCTAssertEqual(groups[0].slaves[1].uuid, "RINCON_000005")
        XCTAssertEqual(groups[0].slaves[2].uuid, "RINCON_000004")
        XCTAssertEqual(groups[0].slaves[3].uuid, "RINCON_000008")
    }
    
    func testItCanNotPerformTheRequestWhenThereAreNoRooms() throws {
        
        var response = "<ZoneGroupState>"
            response += "<ZoneGroups>".encodeString()
                response += "<ZoneGroup Coordinator=\"RINCON_000001\" ID=\"RINCON_000001:314\">".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000006\"/>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000007\" Invisible=\"1\"/>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000005\"/>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000001\">".encodeString()
                        response += "<Satellite UUID=\"RINCON_000002\" Invisible=\"1\"/>".encodeString()
                        response += "<Satellite UUID=\"RINCON_000003\" Invisible=\"1\"/>".encodeString()
                        response += "<Satellite UUID=\"RINCON_000004\" Invisible=\"1\"/>".encodeString()
                    response += "</ZoneGroupMember>".encodeString()
                    response += "<ZoneGroupMember UUID=\"RINCON_000008\"/>".encodeString()
                response += "</ZoneGroup>".encodeString()
            response += "</ZoneGroups>".encodeString()
        response += "</ZoneGroupState>"
        stub(soap(call: GroupTarget.state), soapXml(response))
        
        let groups = try groupRepository
            .getGroups(for: [])
            .toBlocking()
            .single()
        
        XCTAssertEqual(groups, [])
    }
    
}

private extension GroupRepositoryTest {
    
    /* Rooms */
    func getRooms() throws -> [Room] {
        return try ssdpRepository
            .scan(searchTarget: "urn:schemas-upnp-org:device:ZonePlayer:1")
            .flatMap(mapSSDPToRooms)
            .toBlocking()
            .single()
    }
    func mapSSDPToRooms(ssdpDevices: [SSDPResponse]) throws -> Single<[Room]> {
        let collection = try ssdpDevices.compactMap(mapSSDPToRoom)
        return Single.zip(collection)
    }
    
    func mapSSDPToRoom(response: SSDPResponse) throws -> Single<Room>? {
        guard let device = try SSDPDevice.map(response) else { return nil }
        return roomRepository.getRoom(device: device)
    }
}
