//
//  AsyncReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 5/20/26.
//

import ReactorKit

protocol AsyncReactor: Reactor {
  typealias MutationStreamContinuation = AsyncThrowingStream<Mutation, Swift.Error>.Continuation

  func mutate(action: Action, continuation: MutationStreamContinuation) async throws
}

extension AsyncReactor {
  func mutate(action: Action) -> Observable<Mutation> {
    return Observable<Mutation>.create { [weak self] observer in
      guard let self else {
        return Disposables.create()
      }
      let stream = AsyncThrowingStream<Mutation, Error> { continuation in
        let mutationTask = Task { // mutate를 실행중인 Task
          do {
            try await self.mutate(action: action, continuation: continuation)
            continuation.finish()
          } catch {
            continuation.finish(throwing: error)
          }
        }
        continuation.onTermination = { _ in // stream 종료시 실행중인 Task도 함께 취소
          mutationTask.cancel()
        }
      }
      let task = Task {
        do {
          for try await mutation in stream {
            observer.on(.next(mutation))
          }
          observer.on(.completed)
        } catch {
          observer.on(.error(error))
        }
      }
      return Disposables.create {
        task.cancel()
      }
    }
  }
}
