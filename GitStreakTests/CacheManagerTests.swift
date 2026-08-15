import XCTest
@testable import GitStreakKit

final class CacheManagerTests: XCTestCase {
    
    func testCacheSaveAndLoad() throws {
        let cacheManager = CacheManager()
        let sample = MockContributions.highActivity
        
        XCTAssertNoThrow(try cacheManager.save(sample))
        
        let loaded = cacheManager.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.user.username, sample.user.username)
        XCTAssertEqual(loaded?.totalContributions, sample.totalContributions)
        XCTAssertEqual(loaded?.currentStreak, sample.currentStreak)
        XCTAssertTrue(cacheManager.isFresh())
        
        XCTAssertNoThrow(try cacheManager.clear())
        XCTAssertNil(cacheManager.load())
    }
}
