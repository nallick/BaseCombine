//
//  FutureExtensionTests.swift
//
//  Copyright © 2020-2021 Purgatory Design. Licensed under the MIT License.
//

#if canImport(Combine)

import BaseCombine
import Combine
import XCTest

final class FutureExtensionTests: XCTestCase {
    enum TestError: Error {
        case somethingBad
    }

    func testFutureCompletesAfterReceivingValue() {
        let expectedResult = [1, 2, 3]
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<Never>?

        let subject = PassthroughSubject<Int, Never>()
        let testFuture = subject
            .collect(expectedResult.count)
            .eraseToFuture()

        let testSink = testFuture
            .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })
        withExtendedLifetime(testSink) {
            expectedResult.forEach {
                subject.send($0)
            }
        }

        XCTAssertEqual(actualCompletion, .finished)
        XCTAssertEqual(actualResult, expectedResult)
    }

    func testFutureCompletesAfterReceivingError() {
        let expectedError = TestError.somethingBad
        let expectedResult: [Int]? = nil
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<TestError>?

        let subject = PassthroughSubject<Int, TestError>()
        let testFuture = subject
            .collect(1)
            .eraseToFuture()

        let testSink = testFuture
            .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })
        withExtendedLifetime(testSink) {
            subject.send(completion: .failure(expectedError))
        }

        XCTAssertEqual(actualCompletion, .failure(expectedError))
        XCTAssertEqual(actualResult, expectedResult)
    }

    func testCloseableFutureCompletesAfterReceivingValue() {
        let expectedResult = [1, 2, 3]
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<CloseableError<Never>>?

        let subject = PassthroughSubject<Int, Never>()
        let testFuture = subject
            .collect(expectedResult.count)
            .eraseToCloseableFuture()

        let testSink = testFuture
            .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })
        withExtendedLifetime(testSink) {
            expectedResult.forEach {
                subject.send($0)
            }
        }

        XCTAssertEqual(actualCompletion, .finished)
        XCTAssertEqual(actualResult, expectedResult)
    }

    func testCloseableFutureCompletesAfterReceivingError() {
        let expectedError = TestError.somethingBad
        let expectedResult: [Int]? = nil
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<CloseableError<TestError>>?

        let subject = PassthroughSubject<Int, TestError>()
        let testFuture = subject
            .collect(1)
            .eraseToCloseableFuture()

        let testSink = testFuture
            .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })
        withExtendedLifetime(testSink) {
            subject.send(completion: .failure(expectedError))
        }

        XCTAssertEqual(actualCompletion, .failure(.error(expectedError)))
        XCTAssertEqual(actualResult, expectedResult)
    }

    func testCloseableFutureCompletesAfterConnectionClosedWithoutValue() {
        let expectedResult: [Int]? = nil
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<CloseableError<Never>>?

        let subject = PassthroughSubject<Int, Never>()
        let testFuture = subject
            .collect(1)
            .eraseToCloseableFuture()

        let testSink = testFuture
            .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })
        withExtendedLifetime(testSink) {
            subject.send(completion: .finished)
        }

        XCTAssertEqual(actualCompletion, .failure(.connectionClosed))
        XCTAssertEqual(actualResult, expectedResult)
    }
}

#endif
