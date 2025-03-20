import Testing

@testable import MonkeySwift

@Suite("Test Test")
struct MonkeySwift {
    @Test func testExample() {
        // Given
        let value = 42

        // When
        let result = value

        // Then
        #expect(result == 42)
    }
}
