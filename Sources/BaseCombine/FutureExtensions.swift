//
//  FutureExtensions.swift
//
//  Copyright © 2020-2021 Purgatory Design. Licensed under the MIT License.
//

#if canImport(Combine)

import Combine
import Foundation

public enum CloseableError<EmbeddedError: Error>: Error {
    case connectionClosed
    case error(EmbeddedError)
}

extension Publisher {

    public func eraseToFuture() -> Future<Output, Failure> {
        Future { promise in
            var subscription: AnyCancellable?
            subscription = self.sink(
                receiveCompletion: {
                    guard subscription != nil else { return }
                    subscription = nil
                    if case .failure(let error) = $0 { promise(.failure(error)) }  // else: Future finished without value
                },
                receiveValue: {
                    guard let tmpSubscription = subscription else { return }
                    subscription = nil
                    tmpSubscription.cancel()
                    promise(.success($0))
                })
        }
    }

    public func eraseToCloseableFuture() -> Future<Output, CloseableError<Failure>> {
        Future { promise in
            var subscription: AnyCancellable?
            subscription = self.sink(
                receiveCompletion: {
                    guard subscription != nil else { return }
                    subscription = nil
                    switch $0 {
                        case .finished: promise(.failure(.connectionClosed))
                        case .failure(let error): promise(.failure(.error(error)))
                    }
                },
                receiveValue: {
                    guard let tmpSubscription = subscription else { return }
                    subscription = nil
                    tmpSubscription.cancel()
                    promise(.success($0))
                })
        }
    }
}

extension CloseableError: Equatable where EmbeddedError: Equatable {}

#endif
