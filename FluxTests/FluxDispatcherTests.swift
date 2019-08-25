//
//  FluxDispatcherTests.swift
//  FluxTests
//
//  Created by Natan Zalkin on 02/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import ClassyFlux

class FluxDispatcherTests: QuickSpec {

    override func spec() {

        describe("FluxDispatcher") {

            var dispatcher: FluxDispatcher!

            beforeEach {
                dispatcher = FluxDispatcher()
            }

            context("when registered worker") {

                var worker: TestWorker!

                beforeEach {
                    worker = TestWorker()
                    dispatcher.append(workers: [worker])
                }

                it("registers the worker and its token") {
                    dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                    expect(dispatcher.tokens.contains(worker.token)).to(beTrue())
                    expect(dispatcher.workers.first).to(beIdenticalTo(worker))
                }

                context("when unregisters worker by token") {

                    beforeEach {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        dispatcher.unregister(tokens: [worker.token])
                    }

                    it("unregisters the worker and its token") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(dispatcher.tokens.contains(worker.token)).to(beFalse())
                        expect(dispatcher.workers).to(beEmpty())
                    }
                }

                context("when tried to register worker with the same token") {

                    beforeEach {
                        dispatcher.append(workers: [worker])
                    }

                    it("does not registers new worker and token") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(dispatcher.tokens.count).to(equal(1))
                        expect(dispatcher.workers.count).to(equal(1))
                    }
                }

                context("when dispatched action") {

                    beforeEach {
                        dispatcher.dispatch(action: ChangeValueAction(value: "test"))
                    }

                    it("perform action with worker registered") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(worker.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "test")))
                    }
                }

                context("when dispatched block") {

                    var flag: Bool!

                    beforeEach {
                        flag = false
                        dispatcher.dispatch {
                            flag = true
                        }
                    }

                    it("perform action on registered worker") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(flag).to(beTrue())
                    }
                }

                context("when registered another worker") {

                    var another: TestWorker!

                    beforeEach {
                        another = TestWorker()
                        dispatcher.append(workers: [another])
                    }

                    it("registers the worker and its token") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(dispatcher.tokens.contains(another.token)).to(beTrue())
                        expect(dispatcher.workers.last).to(beIdenticalTo(another))
                    }

                    context("when dispatched action") {

                        beforeEach {
                            dispatcher.dispatch(action: ChangeValueAction(value: "test"))
                        }

                        it("passes the action to last worker") {
                            dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                            expect(another.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "test")))
                        }
                    }
                }
            }
        }
    }

}
