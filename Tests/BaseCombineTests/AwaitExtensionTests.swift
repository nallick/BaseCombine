//
//  AwaitExtensionTests.swift
//
//  Copyright © 2020-2021 Purgatory Design. Licensed under the MIT License.
//

#if canImport(Combine)

import BaseCombine
import Combine
import XCTest

final class AwaitExtensionTests: XCTestCase {
    enum TestError: Error {
        case somethingBad
    }

    func testAwaitReturnsTimeOut() {
        let subject = PassthroughSubject<Int, Never>()
        let testCollect = subject
            .collect(1)

        let awaitResult = testCollect.await(timeout: 0.01)

        guard case let .failure(actualError) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualError, .timeout)
    }

    func testAwaitCloseableFutureReturnsTimeOut() {
        let subject = PassthroughSubject<Int, Never>()
        let testFuture = subject
            .collect(1)
            .eraseToCloseableFuture()

        let awaitResult = testFuture.await(timeout: 0.01)

        guard case let .failure(actualError) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualError, .timeout)
    }

    func testAwaitReturnsConnectionClosedWhenFinishedBeforeSendingValue() {
        let subject = PassthroughSubject<Int, Never>()
        let testCollect = subject
            .collect(1)

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            subject.send(completion: .finished)
        }

        let awaitResult = testCollect.await(timeout: 1.0)

        guard case let .failure(actualError) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualError, .connectionClosed)
    }

    func testAwaitCloseableFutureReturnsConnectionClosedWhenFinishedBeforeSendingValue() {
        let subject = PassthroughSubject<Int, Never>()
        let testFuture = subject
            .collect(1)
            .eraseToCloseableFuture()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            subject.send(completion: .finished)
        }

        let awaitResult = testFuture.await(timeout: 1.0)

        guard case let .failure(actualError) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualError, .connectionClosed)
    }

    func testAwaitReturnsErrorOnFailure() {
        let expectedError = TestError.somethingBad
        let subject = PassthroughSubject<Int, TestError>()
        let testCollect = subject
            .collect(1)

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            subject.send(completion: .failure(expectedError))
        }

        let awaitResult = testCollect.await(timeout: 1.0)

        guard case let .failure(actualError) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualError, .error(expectedError))
    }

    func testAwaitCloseableFutureReturnsErrorOnFailure() {
        let expectedError = TestError.somethingBad
        let subject = PassthroughSubject<Int, TestError>()
        let testFuture = subject
            .collect(1)
            .eraseToCloseableFuture()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            subject.send(completion: .failure(expectedError))
        }

        let awaitResult = testFuture.await(timeout: 1.0)

        guard case let .failure(actualError) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualError, .error(expectedError))
    }

    func testAwaitReturnsValueOnSuccess() {
        let expectedResult = [1, 2, 3]
        let subject = PassthroughSubject<Int, Never>()
        let testCollect = subject
            .collect(expectedResult.count)

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            expectedResult.forEach {
                subject.send($0)
            }
        }

        let awaitResult = testCollect.await(timeout: 1.0)

        guard case let .success(actualResult) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualResult, expectedResult)
    }

    func testAwaitCloseableFutureReturnsValueOnSuccess() {
        let expectedResult = [1, 2, 3]
        let subject = PassthroughSubject<Int, Never>()
        let testFuture = subject
            .collect(expectedResult.count)
            .eraseToCloseableFuture()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            expectedResult.forEach {
                subject.send($0)
            }
        }

        let awaitResult = testFuture.await(timeout: 1.0)

        guard case let .success(actualResult) = awaitResult else { XCTFail(); return }
        XCTAssertEqual(actualResult, expectedResult)
    }
}

#endif
