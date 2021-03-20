//
//  AwaitExtensions.swift
//
//  Copyright © 2020-2021 Purgatory Design. Licensed under the MIT License.
//

#if canImport(Combine)

import Combine
import Foundation

public enum AwaitError<EmbeddedError: Error>: Error {
    case timeout
    case connectionClosed
    case error(EmbeddedError)
}

extension Publisher {

    @inlinable public func await<Output, S>(on scheduler: S, timeout: TimeInterval? = nil) -> Result<Output, AwaitError<Failure>> where Self.Output == Output, S: Scheduler {
        self.receive(on: scheduler).await(timeout: timeout)
    }

    public func await<Output>(timeout: TimeInterval? = nil) -> Result<Output, AwaitError<Failure>> where Self.Output == Output {
        var result: Result<Output, AwaitError<Failure>> = .failure(.connectionClosed)
        let semaphore = DispatchSemaphore(value: 0)
        let subscription = self.sink(
            receiveCompletion: {
                if case .success = result { return }
                switch $0 {
                    case .finished: result = .failure(.connectionClosed)
                    case .failure(let error): result = .failure(.error(error))
                }
                semaphore.signal()
            },
            receiveValue: {
                result = .success($0)
                semaphore.signal()
            })

        let timeout = (timeout != nil) ? .now() + timeout! : DispatchTime.distantFuture
        if semaphore.wait(timeout: timeout) == .timedOut { result = .failure(.timeout) }
        subscription.cancel()

        return result
    }

    @inlinable public func await<EmbeddedError, Output, S>(on scheduler: S, timeout: TimeInterval? = nil) -> Result<Output, AwaitError<EmbeddedError>> where Self.Output == Output, S: Scheduler, Failure == CloseableError<EmbeddedError> {
        self.receive(on: scheduler).await(timeout: timeout)
    }
    
    public func await<EmbeddedError, Output>(timeout: TimeInterval? = nil) -> Result<Output, AwaitError<EmbeddedError>> where Self.Output == Output, Failure == CloseableError<EmbeddedError> {
        let intermediateResult: Result<Output, AwaitError<Failure>> = self.await(timeout: timeout)
        return intermediateResult.mapError {
            switch $0 {
                case .timeout:
                    return .timeout
                case .connectionClosed:
                    return .connectionClosed
                case .error(let futureError):
                    guard case .error(let error) = futureError else { return .connectionClosed }
                    return .error(error)
            }
        }
    }
}

extension AwaitError: Equatable where EmbeddedError: Equatable {}

#endif
