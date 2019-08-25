//
//  FluxStore.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 31/07/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2019 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

import Foundation
import ResolverContainer

#if canImport(Combine)
import Combine
#endif

extension Notification.Name {

    /// The notification will be send every time when store's state is changed. The notification sender will be the store object.
    public static let FluxStoreChanged = Notification.Name(rawValue: "FluxStoreChanged")

}

/// An observable container that stores state of specified type and send notifications when the state gets updated.
open class FluxStore<State>: FluxWorker {

    public typealias State = State

    /// A state reducer closure. Returns boolen flag indicating if the state is changed.
    /// - Parameter state: The mutable copy of current state to apply changes.
    /// - Parameter action: The action invoked the reducer.
    public typealias Reduce<Action: FluxAction> = (inout State, Action) -> Bool

    #if canImport(Combine)
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()
    #endif

    /// A unique identifier of the store.
    public let token: UUID

    /// A state of the store.
    public var state: State {
        get { return syncQueue.sync { return backingState } }
        set { syncQueue.sync(flags: .barrier) { backingState = newValue } }
    }

    var backingState: State {
        willSet {
            #if canImport(Combine)
            if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            #endif
        }
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .FluxStoreChanged, object: self)
            }
        }
    }

    let reducers: ResolverContainer
    let syncQueue: DispatchQueue

    /// Initialises the store
    /// - Parameter initialState: The initial state of the store
    /// - Parameter qos: The QOS of the underlying  sync state queue.
    public init(initialState: State, qos: DispatchQoS = .userInitiated) {
        token = UUID()
        backingState = initialState
        reducers = ResolverContainer()
        syncQueue = DispatchQueue(label: "FluxStore.SyncQueue", qos: qos, attributes: .concurrent)
    }

    /// Associates a reducer with the actions of specified type.
    /// - Parameter action: The type of the actions to associate with reducer.
    /// - Parameter reducer: The closure that will be invoked when the action received.
    public func registerReducer<Action: FluxAction>(for action: Action.Type = Action.self, reducer: @escaping Reduce<Action>) {
        reducers.register { reducer }
    }

    /// Unregisters reducer associated with specified action type.
    /// - Parameter action: The action for which the associated reducer should be removed.
    /// - Returns: True if the reducer is unregistered successfully. False when no reducer was registered for the action type.
    public func unregisterReducer<Action: FluxAction>(for action: Action.Type) -> Bool {

        typealias Reducer = Reduce<Action>

        return reducers.unregister(Reducer.self)
    }

    public func handle<Action: FluxAction>(action: Action, composer: FluxComposer) {

        typealias Reducer = Reduce<Action>

        if let reduce = try? reducers.resolve(Reducer.self) {

            var draft = state

            if reduce(&draft, action) {
                state = draft
            }
        }

        composer.next(action: action)
    }

}

#if canImport(Combine)
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension FluxStore: ObservableObject {}
#endif
