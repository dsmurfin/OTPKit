//
//  Consumer.swift
//
//  Copyright (c) 2020 Daniel Murfin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CocoaAsyncSocket

/**
 OTP Consumer
 
 An `OTPConsumer` is the intended target of information from an `OTPProducer`.
 
 Consumers are OTP Components.
 
 Initialized Consumers may have their name, observed systems and supported modules changed. It is also possible to change the delegates without reinitializing.
 
 Example usage:
 
 ``` swift
    
    // create a new dispatch queue to receive delegate notifications
    let queue = DispatchQueue(label: "com.danielmurfin.OTPKit.consumerQueue")
 
    // a unique identifier for this consumer
    let uniqueIdentifier = UUID()
 
    // observe the position and reference frame modules
    let moduleTypes = [OTPModulePosition.self, OTPModuleReferenceFrame.self]
 
    // creates a new IPv6 only consumer which observes systems 1 and 20 and receives delegate notifications a maximum of every 50 ms
    let consumer = OTPConsumer(name: "My Consumer", cid: uniqueIdentifier, ipMode: ipv6Only, interface: "en0", moduleTypes: moduleTypes, observedSystems: [1,20], delegateQueue: Self.delegateQueue, delegateInterval: 50)
 
    // request consumer delegate notifications
    consumer.setConsumerDelegate(self)
 
    // starts the consumer transmitting network data
    consumer.start()
 
 ```

*/

final public class OTPConsumer: Component {
    
    /// The interval between checking for data loss.
    private static let dataLossInterval: Milliseconds = 1000
    
    /// The interval between transmitting system advertisement requests.
    internal static let systemAdvertisementInterval: Milliseconds = 10000

    /// The queue used for read/write operations.
    static let queue: DispatchQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.consumerQueue", attributes: .concurrent)
    
    /// The queue on which socket notifications occur.
    static let socketDelegateQueue: DispatchQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.consumerSocketDelegateQueue")
    
    /// The leeway used for timing. Informs the OS how accurate timings should be.
    private static let timingLeeway: DispatchTimeInterval = .nanoseconds(0)
    
    // MARK: General

    /// A globally unique identifier (UUID) representing the consumer.
    let cid: CID
    
    /// A human-readable name for the consumer.
    var name: ComponentName {
        didSet {
            if name != oldValue {
                nameData = buildNameData()
            }
        }
    }
    
    /// The Internet Protocol version(s) used by the consumer.
    let ipMode: OTPIPMode
    
    /// The `name` of the consumer stored as `Data`.
    var nameData: Data
    
    // MARK: Socket
    
    /// The interface for communications.
    let interface: String
    
    /// The socket used for unicast communications.
    let unicastSocket: ComponentSocket
    
    /// The socket used for multicast IPv4 communications.
    let multicast4Socket: ComponentSocket?
    
    /// The socket used for multicast IPv6 communications.
    let multicast6Socket: ComponentSocket?

    // MARK: Delegate
    
    /**
     Changes the consumer delegate of this consumer to the the object passed.
     
     - Parameters:
        - delegate: The delegate to receive notifications.
     
    */
    public func setConsumerDelegate(_ delegate: OTPConsumerDelegate?) {
        delegateQueue.sync {
            self.consumerDelegate = delegate
        }
    }
    
    /**
     Changes the protocol error delegate of this consumer to the the object passed.
     
     - Parameters:
        - delegate: The delegate to receive notifications.
     
    */
    public func setProtocolErrorDelegate(_ delegate: OTPComponentProtocolErrorDelegate?) {
        delegateQueue.sync {
            self.protocolErrorDelegate = delegate
        }
    }
    
    /**
     Changes the protocol error delegate of this consumer to the the object passed.
     
     - Parameters:
        - delegate: The delegate to receive notifications.
     
    */
    public func setDebugDelegate(_ delegate: OTPComponentDebugDelegate?) {
        delegateQueue.sync {
            self.debugDelegate = delegate
        }
    }
    
    /// The delegate which receives notifications from this consumer.
    private weak var consumerDelegate: OTPConsumerDelegate?
    
    /// The delegate which receives protocol error notifications from this consumer.
    weak var protocolErrorDelegate: OTPComponentProtocolErrorDelegate?
    
    /// The delegate which receives debug log messages from this consumer.
    weak var debugDelegate: OTPComponentDebugDelegate?
    
    /// The queue on which to send delegate notifications.
    let delegateQueue: DispatchQueue
    
    /// The consumer delegate timer.
    private var consumerDelegateTimer: DispatchSourceTimer?
        
    /// The maximum rate at which consumer delegate notifications will be provided.
    private let delegateInterval: Milliseconds
    
    /// The system numbers this consumer should observe.
    private var observedSystemNumbers: [SystemNumber]
    
    // MARK: Timer
    
    /// The queue on which timers run.
    let timerQueue: DispatchQueue
    
    // MARK: System Advertisement
    
    /// The system advertisement timer.
    var systemAdvertisementTimer: DispatchSourceTimer?
    
    /// The system advertisement timer used for delayed delegate notifications.
    var systemAdvertisementNotificationTimer: DispatchSourceTimer?
    
    /// The system numbers received in advertisement messages.
    var systemNumbers: [SystemNumber]
    
    /// A pre-compiled system advertisement message as `Data`.
    var systemAdvertisementMessage: Data?
    
    /// The last transmitted system advertisement folio number for this consumer.
    var systemAdvertisementFolio: FolioNumber
    
    // MARK: Name Advertisement

    /// The name advertisement timer
    var nameAdvertisementTimer: DispatchSourceTimer?
    
    /// A pre-compiled array of name advertisement messages as `Data`.
    var nameAdvertisementMessages: [Data]
    
    /// The last transmitted name advertisement folio number for this consumer.
    var nameAdvertisementFolio: FolioNumber

    // MARK: Module Advertisement

    /// The module advertisement timer
    var moduleAdvertisementTimer: DispatchSourceTimer?
    
    /// A pre-compiled array of module advertisement messages as `Data`.
    private var moduleAdvertisementMessages: [Data]
    
    /// The last transmitted module advertisement folio number for this consumer.
    private var moduleAdvertisementFolio: FolioNumber
    
    /// The module types which this consumer should observe.
    private var moduleTypes: [OTPModule.Type]
    
    // MARK: General
    
    /// The `OTPProducer`s from which this consumer has received advertisement and/or transform messages.
    private var producers: [ConsumerProducer]
    
    /// The combined/merged points from all `OTPProducer`s received by this consumer.
    private var points: [ConsumerPoint]
    
    /// The initial timer used when starting this consumer.
    private var initialTimer: DispatchSourceTimer?
    
    /// The timer used to evaluate for dataloss.
    private var dataLossTimer: DispatchSourceTimer?

    // MARK: - Initialization
    
    /**
     Creates a new Consumer using a name, interface and delegate queue, and optionally a CID, IP Mode, modules.
    
     The CID of a Consumer should persist across launches, so should be stored in persistent storage.

     - Parameters:
        - name: The human readable name of this Consumer.
        - cid: Optional: CID for this Consumer.
        - ipMode: Optional: IP mode for this Consumer (IPv4/IPv6/Both).
        - interface: The network interface for this Consumer. The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.4.35").
        - moduleTypes: An array of Module Types which the Consumer should observe.
        - systemNumbers: An array of System Numbers this Consumer should observe.
        - delegateQueue: A delegate queue on which to receive delegate calls from this Consumer.
        - delegateInterval: The minimum interval between `ConsumerDelegate` notifications (values permitted 1-10000ms).

    */
    public init(name: String, cid: UUID = UUID(), ipMode: OTPIPMode = .ipv4Only, interface: String, moduleTypes: [OTPModule.Type], observedSystems: [OTPSystemNumber], delegateQueue: DispatchQueue, delegateInterval: Int) {
        
        // initialize
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.nameData = name.data(paddedTo: ComponentName.maxComponentNameBytes)
        self.interface = interface
        self.unicastSocket = ComponentSocket(cid: cid, type: .unicast, interface: interface, delegateQueue: Self.socketDelegateQueue)
        self.multicast4Socket = ipMode.usesIPv4() ? ComponentSocket(cid: cid, type: .multicastv4, port: UDP.otpPort, interface: interface, delegateQueue: Self.socketDelegateQueue) : nil
        self.multicast6Socket = ipMode.usesIPv6() ? ComponentSocket(cid: cid, type: .multicastv6, port: UDP.otpPort, interface: interface, delegateQueue: Self.socketDelegateQueue) : nil
        self.delegateQueue = delegateQueue
        self.delegateInterval = max(1,min(10000, delegateInterval))
        self.observedSystemNumbers = observedSystems
        self.timerQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.consumerTimerQueue.\(cid.uuidString)")
        self.systemNumbers = []
        self.systemAdvertisementFolio = FolioNumber.min
        self.nameAdvertisementMessages = []
        self.nameAdvertisementFolio = FolioNumber.min
        self.moduleAdvertisementMessages = []
        self.moduleAdvertisementFolio = FolioNumber.min
        self.moduleTypes = []
        self.producers = []
        self.points = []
        
        // fully initialized
        self.moduleTypes = uniqueModuleTypes(from: moduleTypes)
        
    }
    
    // MARK: - Public API
    
    /**
     Starts this Consumer.
     
     The Consumer will begin transmitting OTP Advertisement Messages, and listening for OTP Advertisement and OTP Transform Messages.
     
     When a Consumer starts, it begins transmitting supported modules. It waits for 12 s, then starts transmitting System Advertisement Messages to discover the System Numbers being transmitted by Producers on the network.
     
     System Advertisement Messages:
     
     Requests for System Number are transmitted every 10 s. When System Numbers are received from a Producer, they are compared with a combined list of System Numbers from all Producers discovered. If a System Number is being advertised and it is also observed by this Consumer, then a multicast join is performed. When a System Number is no longer being transmitted then a multicast leave is performed.
     
     - Throws: An error of type `ComponentSocketError`.

    */

    public func start() throws {

        // pre-build messages
        let systemAdvertisementMessage = buildSystemAdvertisementMessage()
        let nameAdvertisementMessages = buildNameAdvertisementMessages()
        let moduleAdvertisementMessages = buildModuleAdvertisementMessages()
        Self.queue.sync(flags: .barrier) {
            self.systemAdvertisementMessage = systemAdvertisementMessage
            self.nameAdvertisementMessages = nameAdvertisementMessages
            self.moduleAdvertisementMessages = moduleAdvertisementMessages
        }

        // port reuse must be enabled to allow multiple producers/consumers
        try multicast4Socket?.enableReusePort()
        try multicast6Socket?.enableReusePort()
        
        // this consumer should be the delegate
        unicastSocket.delegate = self
        multicast4Socket?.delegate = self
        multicast6Socket?.delegate = self

        // begin listening
        try unicastSocket.startListening()
        try multicast4Socket?.startListening(multicastGroups: [IPv4.advertisementMessageHostname])
        try multicast6Socket?.startListening(multicastGroups: [IPv6.advertisementMessageHostname])
        
        // start advertising supported modules
        startModuleAdvertisement()
        startDataLossTimer()
        startDelegateNotifications()
        
        // wait, then request systems being transmitted
        startIntialWait()
        
    }
    
    /**
     Stops this Consumer.
     
     When stopped, this Consumer will no longer transmit or listen for OTP Messages.

    */
    public func stop() {
        
        // stops all running heartbeats
        stopInitialTimer()
        stopModuleAdvertisement()
        stopSystemAdvertisement()
        stopDataLossTimer()
        stopDelegateNotifications()
        
        // stops listening on all sockets
        unicastSocket.stopListening()
        multicast4Socket?.stopListening()
        multicast6Socket?.stopListening()

    }
    
    /**
     Updates the human-readable name of this Consumer.
     
     - Parameters:
        - name: A human-readable name for this consumer.
     
    */
    public func update(name: String) {
        
        Self.queue.sync(flags: .barrier) {
            self.name = name
        }
        
        // rebuild all messages
        let systemAdvertisementMessage = buildSystemAdvertisementMessage()
        let nameAdvertisementMessages = buildNameAdvertisementMessages()
        let moduleAdvertisementMessages = buildModuleAdvertisementMessages()
        
        Self.queue.sync(flags: .barrier) {
            self.systemAdvertisementMessage = systemAdvertisementMessage
            self.nameAdvertisementMessages = nameAdvertisementMessages
            self.moduleAdvertisementMessages = moduleAdvertisementMessages
        }
        
    }
    
    /**
     Adds additional module types to those supported by this Consumer.

     - Parameters:
        - moduleTypes: An array of Module Types which the Consumer should observe in addition to those already observed.

    */
    public func addModuleTypes(_ moduleTypes: [OTPModule.Type]) {

        Self.queue.sync(flags: .barrier) {
            self.moduleTypes = uniqueModuleTypes(from: self.moduleTypes + moduleTypes)
        }
        
        // rebuild module advertisement messages
        let moduleAdvertisementMessages = buildModuleAdvertisementMessages()
        
        Self.queue.sync(flags: .barrier) {
            self.moduleAdvertisementMessages = moduleAdvertisementMessages
        }
        
        // if the timer is currently active then another folio now
        timerQueue.async {
            if self.moduleAdvertisementTimer != nil {
                self.sendModuleAdvertisementMessages()
            }
        }
        
    }
    
    /**
     Removes module types from those supported by this Consumer.

     - Parameters:
        - moduleTypes: An array of Module Types which the Consumer should no longer observe.

    */
    public func removeModuleTypes(_ moduleTypes: [OTPModule.Type]) {

        let identifiers = moduleTypes.map { $0.identifier }
        
        Self.queue.sync(flags: .barrier) {
            var newModuleTypes = self.moduleTypes
            newModuleTypes.removeAll(where: { identifiers.contains($0.identifier) })
            self.moduleTypes = newModuleTypes
        }

        // rebuild module advertisement messages
        let moduleAdvertisementMessages = buildModuleAdvertisementMessages()
        
        Self.queue.sync(flags: .barrier) {
            self.moduleAdvertisementMessages = moduleAdvertisementMessages
        }
        
        // if the timer is currently active then another folio now
        timerQueue.async {
            if self.moduleAdvertisementTimer != nil {
                self.sendModuleAdvertisementMessages()
            }
        }
        
    }
    
    /**
     Updates the system numbers that are observed by this Consumer.

     - Parameters:
        - systemNumbers: An array of System Numbers this Consumer should observe.

    */
    public func observeSystemNumbers(_ systemNumbers: [OTPSystemNumber]) {
        
        Self.queue.sync(flags: .barrier) {
            self.observedSystemNumbers = systemNumbers
        }
        
        // joins any discovered systems which are now observed, and leaves and subscribed systems which are no longer observed
        refreshSystemSubscription()

    }
    
    /**
     Requests point names from all Producers.
     
     Names are also requested whenever a Producer is first discovered.
     
     When changed names are received, updated points will be provided to the `ConsumerDelegate` via `changes(forPoints: [OTPPoint])`.
     
    */
    public func requestProducerPointNames() {
        
        // request names from all producers
        self.sendNameAdvertisementMessages()

    }
    
    // MARK: - Delegate
    
    /**
     Removes any duplicates from an array of Module Types.

     - Parameters:
        - moduleTypes: An array of Module Types.
     
     - Returns: An array of unique Module Types.

    */
    private func uniqueModuleTypes(from moduleTypes: [OTPModule.Type]) -> [OTPModule.Type] {
        
        var uniqueModulesTypes = [OTPModule.Type]()
        
        for moduleType in moduleTypes {
            
            // ensure this module type doesn't already exist
            guard !uniqueModulesTypes.contains(where: { $0 == moduleType }) else { continue }
            
            uniqueModulesTypes.append(moduleType)
            
        }

        return uniqueModulesTypes
        
    }
    
    // MARK: - Timers / Messaging
    
    /**
     Starts this Consumer's System Advertisement timer to poll for available Producers.
     
     - Precondition: Must be on `timerQueue`.

    */
    private func startSystemAdvertisement() {
        
        // must be on the timer queue
        dispatchPrecondition(condition: .onQueue(timerQueue))
        
        self.sendSystemAdvertisementMessage()
        self.delayedSystemAdvertisementNotification()

        let timer = DispatchSource.repeatingTimer(interval: .milliseconds(Self.systemAdvertisementInterval), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
            
            if let _ = self?.systemAdvertisementTimer {
                self?.sendSystemAdvertisementMessage()
                self?.delayedSystemAdvertisementNotification()
            }
            
        }
        systemAdvertisementTimer = timer
        
    }

    /**
     Stops this Consumer's System Advertisement heartbeat.
    */
    private func stopSystemAdvertisement() {
        timerQueue.sync { systemAdvertisementTimer = nil }
    }
    
    /**
     Notifies the delegate of any received system numbers after the defined delay.
    */
    private func delayedSystemAdvertisementNotification() {
        
        // must be on the timer queue
        dispatchPrecondition(condition: .onQueue(timerQueue))
        
        // allow 2 seconds more than the back time for a response
        let time = SystemAdvertismentLayer.Timing.maxBackoff.rawValue + 2000
        
        let timer = DispatchSource.singleTimer(interval: .milliseconds(time), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
            
            if let _ = self?.systemAdvertisementNotificationTimer {

                if let systemNumbers = Self.queue.sync (execute: { self?.producers.flatMap { $0.systemNumbers } }) {
                    
                    self?.delegateQueue.async { self?.consumerDelegate?.discoveredSystemNumbers(Array(Set(systemNumbers))) }
                    
                }

            }
            
        }
        systemAdvertisementNotificationTimer = timer
        
    }
    
    /**
     Starts this Consumer's Module Advertisement timer.
    */
    private func startModuleAdvertisement() {
        
        timerQueue.sync {
            
            // send a message straight away
            self.sendModuleAdvertisementMessages()
                        
            let timer = DispatchSource.repeatingTimer(interval: .milliseconds(ModuleAdvertismentLayer.Timing.interval.rawValue), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.moduleAdvertisementTimer {
                    self?.sendModuleAdvertisementMessages()
                }
                
            }
            moduleAdvertisementTimer = timer
            
        }
        
    }
    
    /**
     Stops this Consumers's Module Advertisement heartbeat.
    */
    private func stopModuleAdvertisement() {
        timerQueue.sync { moduleAdvertisementTimer = nil }
    }
    
    /**
     Starts this Consumer's initial timer.
    */
    private func startIntialWait() {
        
        timerQueue.sync {
                        
            let timer = DispatchSource.singleTimer(interval: .milliseconds(ModuleAdvertismentLayer.Timing.startupWait.rawValue), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.initialTimer {
                    self?.startSystemAdvertisement()
                }
                
            }
            initialTimer = timer
            
        }
        
    }
    
    /**
     Stops this Consumer's initial timer.
    */
    private func stopInitialTimer() {
        timerQueue.sync { initialTimer = nil }
    }
    
    /**
     Starts this Consumer's data loss timer.
    */
    private func startDataLossTimer() {

        timerQueue.sync {
                        
            let timer = DispatchSource.repeatingTimer(interval: .milliseconds(Self.dataLossInterval), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.dataLossTimer {
                    self?.checkForProducerDataLoss()
                }
                
            }
            dataLossTimer = timer
            
        }
        
    }
    
    /**
     Stops this Consumer's data loss timer.
    */
    private func stopDataLossTimer() {
        timerQueue.sync { dataLossTimer = nil }
    }
    
    /**
     Starts this Consumer's delegate notifications timer to provide changes to points.
    */
    private func startDelegateNotifications() {
        
        timerQueue.sync {

            let timer = DispatchSource.repeatingTimer(interval: .milliseconds(self.delegateInterval), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.consumerDelegateTimer {
                    self?.mergeAndNotifyProducerPoints()
                }
                
            }
            consumerDelegateTimer = timer
            
        }
        
    }

    /**
     Stops this Consumer's delegate notifications heartbeat.
    */
    private func stopDelegateNotifications() {
        timerQueue.sync { consumerDelegateTimer = nil }
    }
    
    // MARK: - Advertisement / Transform
    
    /**
     Called when a new Folio has been received from an `OTPProducer`.
     
     - Parameters:
        - newFolio: The folio received from a producer.
        - systemNumber: The system number this folio was received in.
        - producer: The Producer which sent the folio.
     
     - Precondition: Must be on `Self.queue`.
     
    */
    private func receivedFolio(_ newFolio: Folio, forSystemNumber systemNumber: SystemNumber, forProducer producer: ConsumerProducer) {

        // must be on the read/write queue
        dispatchPrecondition(condition: .onQueue(Self.queue))
        
        // get the producer index
        guard let prodIndex = producers.firstIndex(where: { $0 == producer }) else { return }
        
        let systemNumberIndex = Int(systemNumber) - 1

        // decide whether to store this folio/page
        
        if let index = producer.systemTransformFolios[systemNumberIndex].folios.firstIndex(where: { $0.number == newFolio.number }) {
            
            // page for existing folio number for this producer

            // this page mustn't have already been added
            guard let page = newFolio.pages.first, !producers[prodIndex].systemTransformFolios[systemNumberIndex].folios[index].pages.contains(where: { $0 == page }) else { return }

            let newPoints = producers[prodIndex].systemTransformFolios[systemNumberIndex].folios[index].points + newFolio.points

            producers[prodIndex].systemTransformFolios[systemNumberIndex].folios[index].points = newPoints
            producers[prodIndex].systemTransformFolios[systemNumberIndex].folios[index].pages.append(page)

        } else {
            
            // new folio number for this producer and system

            if let last = producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.last {

                // other folios have been received

                // this folio must be in sequence (not allowing older numbers when a folio hasn't yet been seen)
                guard newFolio.number.isPartOfCurrentCommunication(previous: last.number) else { return }

                // add this folio at the end
                producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.append(newFolio)

            } else {

                // first folio received for this producer and system

                // add this folio at the end
                producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.append(newFolio)

            }
            
        }

        // decide what to do with stored folios

        // loop through folios from most recently received
        var folioProcessedAtIndex: Int?
        for (index, folio) in producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.enumerated().reversed() {

            if folio.isComplete() {

                // replace or add these points
                if folio.fullPointSet {

                    // all other points for other systems
                    let existingPoints = producers[prodIndex].points.filter { $0.address.systemNumber != systemNumber }

                    // replace these points
                    producers[prodIndex].points = existingPoints + folio.points
                    
                } else {

                    // add these points, keeping newly provided over existing which match
                    producers[prodIndex].points = Array(Set(folio.points).union(producers[prodIndex].points))
                    
                }
                
                // update names for all points
                for (pointIndex, _) in producers[prodIndex].points.enumerated() {
                    producers[prodIndex].points[pointIndex].updateName(fromAddressPointDescriptions: producer.addressPointDescriptions)
                }
                
                // this folio was successfully processed
                folioProcessedAtIndex = index
                
            }
            
        }

        // was any folio processed?
        if let processedIndex = folioProcessedAtIndex {
            
            // remove this folio and any received earlier
            producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.removeSubrange(...processedIndex)
            
        } else if producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.count > OTPLayer.transformFolioWindow {
            
            // get the oldest folio which is not a full point set
            guard let oldestFolioIndex = producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.firstIndex(where: { !$0.fullPointSet }) else { return }
            
            let oldestFolio = producers[prodIndex].systemTransformFolios[systemNumberIndex].folios[oldestFolioIndex]
            
            // add these points
            producers[prodIndex].points = Array(Set(producers[prodIndex].points + oldestFolio.points))
            
            // update names for all points
            for (pointIndex, _) in producers[prodIndex].points.enumerated() {
                producers[prodIndex].points[pointIndex].updateName(fromAddressPointDescriptions: producer.addressPointDescriptions)
            }
         
            // remove any folios prior to the oldest folio just processed
            producers[prodIndex].systemTransformFolios[systemNumberIndex].folios.removeSubrange(...oldestFolioIndex)
            
        }
        
    }
    
    /**
     Merges this producers points with those of other producers.
    */
    private func mergeAndNotifyProducerPoints() {

        // all points for all producers which are online sorted by address and highest priority first
        let allProducerPoints = Self.queue.sync { self.producers.filter { $0.notifiedState == .online }.flatMap { $0.points }.sorted() }

        // unique addresses for all producers in order
        let uniqueAddresses = Array(Set(allProducerPoints.map { $0.address })).sorted()

        var mergedPoints = [ConsumerPoint]()
        addressLoop: for address in uniqueAddresses {
            
            // all points with this address
            let points = allProducerPoints.filter { $0.address == address }
            
            if points.count == 1, let point = points.first {
                
                // single point found, so add it
                mergedPoints.append(point)
                
            } else if let point = points.first {
                
                // other points with the same priority as this one
                let samePriorityPoints = points.filter { $0.priority == point.priority }

                // multiple points at highest priority
                if samePriorityPoints.count > 1 {

                    // all modules
                    let allPointModules = samePriorityPoints.flatMap { $0.modules }
                    
                    // unique module identifiers
                    let uniqueModuleIdentifiers = Array(Set(allPointModules.map { $0.moduleIdentifier }))
                    
                    var mergedModules = [OTPModule]()
                    for moduleIdentifier in uniqueModuleIdentifiers {
                        
                        // all modules with this identifier
                        let modules = allPointModules.filter { $0.moduleIdentifier == moduleIdentifier }
                        
                        if modules.count == 1, let module = modules.first {
                            
                            // add this module
                            mergedModules.append(module)
                            
                        } else if let module = modules.first {
                            
                            // get the type of this module
                            let moduleType = type(of: module).self
                            
                            // merge the modules of this type
                            let moduleExclude = moduleType.merge(modules: modules)
                            
                            // should this point be excluded?
                            if moduleExclude.excludePoint {
                                
                                // continue to the next address
                                continue addressLoop
                                
                            } else if let module = moduleExclude.module {
                            
                                // append the merged module
                                mergedModules.append(module)
                                
                            }
                            
                        }
                        
                    }
                    
                    // create a new consumer point (no CID or sampled as it has multiple contributors)
                    let newPoint = ConsumerPoint(address: point.address, priority: point.priority, name: point.name, modules: mergedModules)
                    
                    // add this newly merged point
                    mergedPoints.append(newPoint)
                    
                } else {
                    
                    // single highest priority point found, so add it
                    mergedPoints.append(point)
                    
                }
                
            }
            
        }

        let existingPoints = Self.queue.sync { self.points }
            
        // replace existing points with these ones
        for (index, newPoint) in mergedPoints.enumerated() {

            // is this point already known about
            if let existingPoint = existingPoints.first(where: { $0.address == newPoint.address }) {
                
                // if the names or priorities don't match this point should be considered changed
                if newPoint.priority != existingPoint.priority || newPoint.name != existingPoint.name {
                    mergedPoints[index].hasChanges = true
                    break
                }

                for module in newPoint.modules {
                    
                    // does this module already exist?
                    if let existingModule = existingPoint.modules.first(where: { $0.moduleIdentifier == module.moduleIdentifier }) {
                        
                        if !module.isEqualToModule(existingModule) {
                            
                            // module is different module, so point has changes
                            mergedPoints[index].hasChanges = true
                            
                            // no need to check further modules as the point has changes
                            break
                            
                        }
                        
                    } else {
                        
                        // new module, so point has changes
                        mergedPoints[index].hasChanges = true
                        
                        // no need to check further modules as the point has changes
                        break
                        
                    }
                    
                }
                
            } else {
                
                // new point, so point has changes
                mergedPoints[index].hasChanges = true

            }
            
        }
        
        // all existing point addresses ordered
        let existingPointAddresses = Self.queue.sync { Array(Set(self.points.map { $0.address })) }.sorted()

        // do the new address match the previous ones?
        if existingPointAddresses != uniqueAddresses {

            // all points sorted by address
            let allPoints = mergedPoints.map { OTPPoint(address: $0.address, priority: $0.priority, name: $0.name, cid: $0.cid, sampled: $0.sampled, modules: $0.modules) }.sorted()
            
            // a newly addressed point has appeared or disappeared
            delegateQueue.async { self.consumerDelegate?.replaceAllPoints(allPoints) }
            
        } else {
            
            let pointsWithChanges = mergedPoints.filter { $0.hasChanges }.map { OTPPoint(address: $0.address, priority: $0.priority, name: $0.name, cid: $0.cid, sampled: $0.sampled, modules: $0.modules) }
            
            // at least 1 point has changes
            if !pointsWithChanges.isEmpty {
                delegateQueue.async { self.consumerDelegate?.changes(forPoints: pointsWithChanges) }
            }
            
        }

        // replace points
        Self.queue.sync(flags: .barrier) {
            self.points = mergedPoints.sorted()
        }

    }
    
    /**
     Checks for data loss for each Producer observed by this Consumer.
    */
    func checkForProducerDataLoss() {

        let producers = Self.queue.sync { self.producers }

        // all producers which should go into an offline state (those which haven't yet been notified)
        let lostProducers = producers.filter { $0.shouldGoOffline }
        
        for producer in lostProducers {
            delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: producer.name, cid: producer.cid, ipMode: producer.ipMode, ipAddresses: producer.ipAddresses, sequenceErrors: producer.sequenceErrors, state: .offline)) }
        }

        Self.queue.sync(flags: .barrier) {
            
            // flags this producer as offline
            for (index, producer) in self.producers.enumerated() where lostProducers.contains(producer) {
                self.producers[index].notifiedState = .offline
            }

        }
   
    }
    
    // MARK: - Systems
    
    /**
     Called to join or leave multicast groups for the observed systems which have been discovered from producers.
    */
    private func refreshSystemSubscription() {
        
        // get the new unique system numbers, and the existing joined ones
        var newSystemNumbers = Self.queue.sync { Array(Set(producers.flatMap { $0.systemNumbers })).filter { self.observedSystemNumbers.contains($0) } }
        let existingSystemNumbers = Self.queue.sync { self.systemNumbers }

        // loop through all possible system numbers
        for systemNumber in SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber {
            
            if existingSystemNumbers.contains(systemNumber) && !newSystemNumbers.contains(systemNumber) {
                
                // notify the debug delegate
                delegateQueue.async { self.debugDelegate?.debugLog("Attempting multicast leave for \(systemNumber)") }
                
                // the existing contains this number, but the new does not
                // try to leave the multicast group
                do {
                    if let ipv4Multicast = IPv4.transformHostname(for: systemNumber) {
                        try multicast4Socket?.leave(multicastGroup: ipv4Multicast)
                    }
                    if let ipv6Multicast = IPv6.transformHostname(for: systemNumber) {
                        try multicast6Socket?.leave(multicastGroup: ipv6Multicast)
                    }
                } catch _ {
                    // leave failed so add this back in as previously joined
                    newSystemNumbers.append(systemNumber)
                }
                
            } else if newSystemNumbers.contains(systemNumber) && !existingSystemNumbers.contains(systemNumber) {
                
                // notify the debug delegate
                delegateQueue.async { self.debugDelegate?.debugLog("Attempting multicast join for System \(systemNumber)") }
                
                // the new contains this number, but the existing does not
                // try to join the multicast group
                do {
                    if let ipv4Multicast = IPv4.transformHostname(for: systemNumber) {
                        try multicast4Socket?.join(multicastGroup: ipv4Multicast)
                    }
                    if let ipv6Multicast = IPv6.transformHostname(for: systemNumber) {
                        try multicast6Socket?.join(multicastGroup: ipv6Multicast)
                    }
                } catch _ {
                    // join failed, so do not mark as joined
                    newSystemNumbers.removeAll(where: { $0 == systemNumber })
                }
                
            }
            
        }
        
        // update the system numbers to be those which have been successfully joined
        Self.queue.sync(flags: .barrier) {
            self.systemNumbers = newSystemNumbers
        }
        
    }
    
}

// MARK: -
// MARK: -

/**
 OTP Consumer Extension
 
 Extensions to `OTPConsumer` to handle message creation and transmission.

*/

private extension OTPConsumer {
    
    /**
     Builds the Module Advertisement Messages for this Consumer.

     - Returns: An array of `Data`.

    */
    private func buildModuleAdvertisementMessages() -> [Data] {

        let cid = Self.queue.sync { self.cid }
        let nameData = Self.queue.sync { self.nameData }
        let moduleIdentifiers = Self.queue.sync { self.moduleTypes.map { $0.identifier } }
        
        let miCount = moduleIdentifiers.count
        let miMax = ModuleAdvertismentLayer.maxMessageModuleIdentifiers
        
        // how many pages are required (must be capped at max pages even if more exist)
        let pageCount = min((miCount / miMax) + (miCount % miMax == 0 ? 0 : 1 ), Int(Page.max))
        
        var pages = [Data]()

        // loop through each page
        for page in 0..<pageCount {
            
            let first = page*miMax
            let last = min(first+miMax, miCount)

            // the module identifiers for this page
            let pageModuleIdentifiers = Array(moduleIdentifiers[first..<last])
            
            // layers
            var otpLayerData = OTPLayer.createAsData(with: .advertisementMessage, cid: cid, nameData: nameData, page: Page(page), lastPage: Page(pageCount-1))
            var advertisementLayerData = AdvertismentLayer.createAsData(with: .module)
            var moduleAdvertisementLayerData = ModuleAdvertismentLayer.createAsData(with: .moduleList, moduleIdentifiers: pageModuleIdentifiers)
            
            // calculate and insert module advertisement layer length
            let moduleAdvertisementLayerLength: OTPPDULength = OTPPDULength(moduleAdvertisementLayerData.count - ModuleAdvertismentLayer.lengthCountOffset)
            moduleAdvertisementLayerData.replacingPDULength(moduleAdvertisementLayerLength, at: ModuleAdvertismentLayer.Offset.length.rawValue)

            // calculate and insert advertisement layer length
            let advertisementLayerLength: OTPPDULength = OTPPDULength(advertisementLayerData.count + moduleAdvertisementLayerData.count - AdvertismentLayer.lengthCountOffset)
            advertisementLayerData.replacingPDULength(advertisementLayerLength, at: AdvertismentLayer.Offset.length.rawValue)

            // calculate and insert otp layer length
            let otpLayerLength: OTPPDULength = OTPPDULength(otpLayerData.count + advertisementLayerData.count + moduleAdvertisementLayerData.count - OTPLayer.lengthCountOffset)
            otpLayerData.replacingPDULength(otpLayerLength, at: OTPLayer.Offset.length.rawValue)
            
            pages.append(otpLayerData + advertisementLayerData + moduleAdvertisementLayerData)
            
        }

        return pages
        
    }
    
    /**
     Sends the Module Advertisement Messages for this Consumer.
    */
    private func sendModuleAdvertisementMessages() {

        let theModuleAdvertisementMessages = Self.queue.sync { self.moduleAdvertisementMessages }
        
        guard !moduleAdvertisementMessages.isEmpty else { return }
        
        // get the folio number
        let folioNumber = Self.queue.sync { self.moduleAdvertisementFolio }

        // loop through all messages
        for message in theModuleAdvertisementMessages {
            
            var messageData = message

            messageData.replacingOTPLayerFolio(with: folioNumber)

            // send the message(s)
            if ipMode.usesIPv4() {
                unicastSocket.send(message: messageData, host: IPv4.advertisementMessageHostname, port: UDP.otpPort)
            }
            if ipMode.usesIPv6() {
                unicastSocket.send(message: messageData, host: IPv6.advertisementMessageHostname, port: UDP.otpPort)
            }
            
        }
        
        // notify the debug delegate
        delegateQueue.async { self.debugDelegate?.debugLog("Sending module advertisement message(s) multicast") }
        
        // increment the folio number
        Self.queue.sync(flags: .barrier) {
            self.moduleAdvertisementFolio &+= 1
        }
                
    }
    
}

// MARK: -
// MARK: -

/**
 Component Socket Delegate
 
 Required methods for objects implementing this delegate.

*/

extension OTPConsumer: ComponentSocketDelegate {
    
    /**
     Called whenever a message is received.
     
     - Parameters:
        - data: The message data.
        - hostname: The source hostname of the message.
        - port: The source port of the message.
        - ipFamily: The `ComponentSocketIPFamily` of the source of the message.
     
    */
    func receivedMessage(withData data: Data, sourceHostname hostname: Hostname, sourcePort port: UDPPort, ipFamily: ComponentSocketIPFamily) {

        Self.queue.sync(flags: .barrier) {
        
            do {

                // try to extract an OTP Layer
                let otpLayer = try OTPLayer.parse(fromData: data)
                
                // this message must not originate from this component
                let ownCid = self.cid
                guard otpLayer.cid != ownCid else { return }
                
                // get the current list of producers
                let producers = self.producers
                
                // if this component is newly discovered (or coming back online) this should be its mode
                let newComponentIPMode: OTPIPMode = ipFamily == .IPv4 ? .ipv4Only : .ipv6Only
                
                // if a previous message from this producer has been received decide whether to accept it
                if let producer = producers.first(where: { $0.cid == otpLayer.cid }) {
                    if producer.notifiedState == .offline, let index = self.producers.firstIndex(where: { $0.cid == otpLayer.cid }) {
                        // this producer had gone offline, so start allowing messages from another IP family
                        self.producers[index].ipMode = newComponentIPMode
                        
                        // reset folio and page numbers
                        self.producers[index].systemAdvertisementFolio = nil
                        self.producers[index].nameAdvertisementFolio = nil
                        self.producers[index].nameAdvertisementPage = nil
                        self.producers[index].systemTransformFolios = (SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber).map { (systemNumber: $0, folios: []) }
                    } else {
                        switch producer.ipMode {
                        case .ipv4Only:
                            if ipFamily == .IPv6 {
                                updateHostnames(withHostname: hostname, ipFamily: ipFamily, forProducer: producer)
                            }
                        case .ipv6Only, .ipv4And6:
                            // only allow IPv6 messages to be processed
                            guard ipFamily == .IPv6 else {
                                updateHostnames(withHostname: hostname, ipFamily: ipFamily, forProducer: producer)
                                return
                            }
                        }
                    }
                }

                switch otpLayer.vector {
                case .advertisementMessage:

                    // try to extract an advertisement layer
                    let advertisementLayer = try AdvertismentLayer.parse(fromData: otpLayer.data)

                    switch advertisementLayer.vector {
                    case .module:
                        // consumers don't care about module advertisement messages
                        break
                    case .name:
                        
                        // if a previous message of this type has been received, it must be within the valid range (always continue if the producer had previously gone offline)
                        if let producer = producers.first(where: { $0.cid == otpLayer.cid }), producer.notifiedState != .offline,  let previousFolio = producer.nameAdvertisementFolio, let previousPage = producer.nameAdvertisementPage {
                            guard otpLayer.isPartOfCurrentCommunication(previousFolio: previousFolio, previousPage: previousPage) else { throw OTPLayerValidationError.folioOutOfRange(producer.cid) }
                        }

                        // try to extract a name advertisement layer
                        let nameAdvertisementLayer = try NameAdvertismentLayer.parse(fromData: advertisementLayer.data)

                        guard let addressPointDescriptions = nameAdvertisementLayer?.addressPointDescriptions else { return }
                            
                        // does this producer already exist?
                        if let index = self.producers.firstIndex(where: { $0.cid == otpLayer.cid }) {
  
                            // add these address point descriptions
                            self.producers[index].addingAddressPointDescriptions(addressPointDescriptions)

                            // update the previously discovered producers name advertisement folio number and page
                            self.producers[index].nameAdvertisementFolio = otpLayer.folio
                            self.producers[index].nameAdvertisementPage = otpLayer.page
                            
                            // a new advertisement message has been received
                            self.producers[index].receivedAdvertisement = Date()
                            
                            let producer = self.producers[index]
                            
                            let existingComponentIPMode = newIPMode(from: ipFamily, for: producer)
                            
                            // only send a notification if this was previously notified as offline or the name, ip address, or ip mode is different
                            if producer.notifiedState == .offline || producer.name != otpLayer.componentName || !producer.ipAddresses.contains(hostname) || producer.ipMode != existingComponentIPMode {
                                                           
                                // the producer is now advertising
                                if producer.notifiedState == .offline {
                                    self.producers[index].notifiedState = .advertising
                                }
                                
                                // get the newly changed state
                                let notifiedState = self.producers[index].notifiedState
                                
                                let newIpAddresses = Array(Set(producer.ipAddresses).union(Set([hostname]))).sorted()
                                
                                // notify the delegate of the producer status
                                self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: otpLayer.componentName, cid: producer.cid, ipMode: existingComponentIPMode, ipAddresses: newIpAddresses, sequenceErrors: producer.sequenceErrors, state: notifiedState)) }
                                
                                // update both name and ip when this happens
                                self.producers[index].name = otpLayer.componentName
                                self.producers[index].ipAddresses = newIpAddresses
                                self.producers[index].ipMode = existingComponentIPMode

                            }
                            
                        } else {
                            
                            // create a new producer and add it to those already known about
                            let producer = ConsumerProducer(cid: otpLayer.cid, name: otpLayer.componentName, ipMode: newComponentIPMode, ipAddress: hostname, nameAdvertisementFolio: otpLayer.folio, nameAdvertisementPage: otpLayer.page, addressPointDescriptions: addressPointDescriptions)
                            
                            self.producers.append(producer)
                            
                            // notify the delegate of the producer status
                            self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: otpLayer.componentName, cid: otpLayer.cid, ipMode: newComponentIPMode, ipAddresses: [hostname], sequenceErrors: producer.sequenceErrors, state: .advertising)) }
                            
                        }
                        
                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Received name advertisement message from \(otpLayer.componentName) \(otpLayer.cid)") }
                            
                    case .system:

                        // if a previous message of this type has been received, it must be within the valid range (always continue if the producer had previously gone offline)
                        if let producer = producers.first(where: { $0.cid == otpLayer.cid }), producer.notifiedState != .offline, let previousFolio = producer.systemAdvertisementFolio {
                            guard otpLayer.isPartOfCurrentCommunication(previousFolio: previousFolio) else { throw OTPLayerValidationError.folioOutOfRange(producer.cid) }
                        }
                        
                        // get the delegate
                        let delegate = self.protocolErrorDelegate

                        // try to extract a system advertisement layer
                        let systemAdvertisementLayer = try SystemAdvertismentLayer.parse(fromData: advertisementLayer.data, delegate: delegate, delegateQueue: delegateQueue)

                        guard let systemNumbers = systemAdvertisementLayer?.systemNumbers else { return }
                            
                        // does this producer already exist?
                        if let index = self.producers.firstIndex(where: { $0.cid == otpLayer.cid }) {

                            // replace the system numbers with the new ones
                            self.producers[index].systemNumbers = systemNumbers
                            
                            // update the previously discovered producers system advertisement folio number
                            self.producers[index].systemAdvertisementFolio = otpLayer.folio
                            
                            // a new advertisement message has been received
                            self.producers[index].receivedAdvertisement = Date()
                            
                            let producer = self.producers[index]
                            
                            let existingComponentIPMode = newIPMode(from: ipFamily, for: producer)
                            
                            // only send a notification if this was previously notified as offline or the name, ip address, or ip mode is different
                            if producer.notifiedState == .offline || producer.name != otpLayer.componentName || !producer.ipAddresses.contains(hostname) || producer.ipMode != existingComponentIPMode {
                                
                                // the producer is now advertising
                                if producer.notifiedState == .offline {
                                    self.producers[index].notifiedState = .advertising
                                }
                                
                                // get the newly changed state
                                let notifiedState = self.producers[index].notifiedState
                                
                                let newIpAddresses = Array(Set(producer.ipAddresses).union(Set([hostname]))).sorted()
                                                            
                                // notify the delegate of the producer information
                                self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: otpLayer.componentName, cid: producer.cid, ipMode: existingComponentIPMode, ipAddresses: newIpAddresses, sequenceErrors: producer.sequenceErrors, state: notifiedState)) }
                                
                                // update both name and ip when this happens
                                self.producers[index].name = otpLayer.componentName
                                self.producers[index].ipAddresses = newIpAddresses
                                self.producers[index].ipMode = existingComponentIPMode

                            }
                            
                        } else {
                            
                            // create a new producer and add it to those already known about
                            let producer = ConsumerProducer(cid: otpLayer.cid, name: otpLayer.componentName, ipMode: newComponentIPMode, ipAddress: hostname, systemAdvertisementFolio: otpLayer.folio, systemNumbers: systemNumbers)
                            self.producers.append(producer)
                            
                            // notify the delegate of the producer information
                            self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: otpLayer.componentName, cid: otpLayer.cid, ipMode: newComponentIPMode, ipAddresses: [hostname], sequenceErrors: producer.sequenceErrors, state: .advertising)) }
                            
                            // request names from producers
                            Self.socketDelegateQueue.async { self.sendNameAdvertisementMessages() }
                            
                        }
                                                        
                        // joins newly discovered systems which are observed
                        Self.socketDelegateQueue.async { self.refreshSystemSubscription() }
                        
                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Received system advertisement message from \(otpLayer.componentName) \(otpLayer.cid)") }
                        
                    }

                case .transformMessage:

                    let moduleTypes = self.moduleTypes
                    let delegate = self.protocolErrorDelegate
                    
                    // try to extract a transform layer
                    let transformLayer = try TransformLayer.parse(fromData: otpLayer.data, moduleTypes: moduleTypes, delegate: delegate, delegateQueue: delegateQueue)
                    
                    let points = transformLayer.points.map { ConsumerPoint(address: OTPAddress(system: transformLayer.systemNumber, group: $0.groupNumber, point: $0.pointNumber), priority: $0.priority, cid: otpLayer.cid, sampled: $0.timestamp, modules: $0.modules) }
                    
                    let folio = Folio(number: otpLayer.folio, pages: [otpLayer.page], lastPage: otpLayer.lastPage, fullPointSet: transformLayer.fullPointSet, points: points)
                                            
                    // does this producer already exist?
                    if let index = self.producers.firstIndex(where: { $0.cid == otpLayer.cid }) {
                                     
                        let producer = self.producers[index]

                        // a transform message has been received
                        self.producers[index].transformMessageReceived()
                        
                        self.receivedFolio(folio, forSystemNumber: transformLayer.systemNumber, forProducer: producer)
                        
                        let existingComponentIPMode = newIPMode(from: ipFamily, for: producer)
                        
                        // only send a notification if this was previously notified as offline or the name, ip address, or ip mode is different
                        if producer.notifiedState != .online || producer.name != otpLayer.componentName || !producer.ipAddresses.contains(hostname) || producer.ipMode != existingComponentIPMode {
                            
                            // the producer is now online
                            self.producers[index].notifiedState = .online
                            
                            let newIpAddresses = Array(Set(producer.ipAddresses).union(Set([hostname]))).sorted()
                                                        
                            // notify the delegate this producer is online
                            self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: otpLayer.componentName, cid: producer.cid, ipMode: existingComponentIPMode, ipAddresses: newIpAddresses, sequenceErrors: producer.sequenceErrors, state: .online)) }
                            
                            // update both name and ip when this happens
                            self.producers[index].name = otpLayer.componentName
                            self.producers[index].ipAddresses = newIpAddresses
                            self.producers[index].ipMode = existingComponentIPMode

                        }

                    } else {
                        
                        // create a new producer and add it to those already known about
                        let producer = ConsumerProducer(cid: otpLayer.cid, name: otpLayer.componentName, ipMode: newComponentIPMode, ipAddress: hostname)
                        
                        self.producers.append(producer)
                        
                        self.receivedFolio(folio, forSystemNumber: transformLayer.systemNumber, forProducer: producer)

                        // notify the delegate this producer is online
                        self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: producer.name, cid: otpLayer.cid, ipMode: newComponentIPMode, ipAddresses: [hostname], sequenceErrors: producer.sequenceErrors, state: .online)) }
                        
                        // request names from producers
                        Self.socketDelegateQueue.async { self.sendNameAdvertisementMessages() }

                    }
                        
                }
                
            } catch let error as OTPLayerValidationError {
                
                switch error {
                case .lengthOutOfRange, .invalidPacketIdentifier:
                    
                    // these errors should not be notified
                    break
                    
                case let .folioOutOfRange(cid):
                                            
                    if let index = self.producers.firstIndex(where: { $0.cid == cid }) {

                        // increment the sequence errors
                        self.producers[index].sequenceErrors &+= 1
                        
                        let producer = self.producers[index]
                        
                        let producerStatus = OTPProducerStatus(name: producer.name, cid: cid, ipMode: producer.ipMode, ipAddresses: producer.ipAddresses, sequenceErrors: producer.sequenceErrors, state: producer.notifiedState)
                        
                        // notify the delegate
                        self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(producerStatus) }
                        
                    }
                                            
                default:
                    
                    // there was an error in the otp layer
                    delegateQueue.async { self.protocolErrorDelegate?.layerError(error.logDescription) }

                }
                
            } catch let error as AdvertisementLayerValidationError {
                
                // there was an error in the advertisement layer
                delegateQueue.async { self.protocolErrorDelegate?.layerError(error.logDescription) }
                
            } catch let error as ModuleAdvertisementLayerValidationError {
                
                // there was an error in the module advertisement layer
                delegateQueue.async { self.protocolErrorDelegate?.layerError(error.logDescription) }
                
            } catch let error as SystemAdvertisementLayerValidationError {

                // there was an error in the system advertisement layer
                delegateQueue.async { self.protocolErrorDelegate?.layerError(error.logDescription) }

            } catch let error as NameAdvertisementLayerValidationError {

                // there was an error in the name advertisement layer
                delegateQueue.async { self.protocolErrorDelegate?.layerError(error.logDescription) }
                
            } catch let error as TransformLayerValidationError {
                
                // there was an error in the transform layer
                delegateQueue.async { self.protocolErrorDelegate?.layerError(error.logDescription) }
                
            } catch let error {
                
                // there was an unknown error
                delegateQueue.async { self.protocolErrorDelegate?.unknownError(error.localizedDescription) }
                
            }
            
        }
        
    }
    
    /**
     Called to update hostnames and discovered IP families for a producer.
     
     This should only be used when a producer message is rejected due to invalid IP family checks.
     
     - Parameters:
        - hostname: A new hostname for this producer.
        - ipFamily: The `ComponentSocketIPFamily` that this message was received on.
        - producer: The producer to be updated.
     
     - Precondition: Must be on `queue`.

    */
    private func updateHostnames(withHostname hostname: String, ipFamily: ComponentSocketIPFamily, forProducer producer: ConsumerProducer) {
        // must be on the consumer read/write queue
        dispatchPrecondition(condition: .onQueue(Self.queue))
        
        let newIpMode = newIPMode(from: ipFamily, for: producer)
        
        if (!producer.ipAddresses.contains(hostname) || producer.ipMode != newIpMode), let index = self.producers.firstIndex(where: { $0.cid == producer.cid }) {
            let newIpAddresses = Array(Set(producer.ipAddresses).union(Set([hostname]))).sorted()

            // notify the delegate of the producer status
            self.delegateQueue.async { self.consumerDelegate?.producerStatusChanged(OTPProducerStatus(name: producer.name, cid: producer.cid, ipMode: newIpMode, ipAddresses: newIpAddresses, sequenceErrors: producer.sequenceErrors, state: producer.notifiedState)) }
            
            self.producers[index].ipAddresses = newIpAddresses
            self.producers[index].ipMode = newIpMode
        }
    }
    
    /**
     Calculates a new `OTPIPMode` from the existing mode and the newly received IP family.
     
     - Parameters:
        - ipFamily: The `ComponentSocketIPFamily` that this message was received on.
        - producer: The producer to be evaluated.
     
     - Precondition: Must be on `queue`.

    */
    private func newIPMode(from ipFamily: ComponentSocketIPFamily, for producer: ConsumerProducer) -> OTPIPMode {
        // must be on the consumer read/write queue
        dispatchPrecondition(condition: .onQueue(Self.queue))
        
        switch producer.ipMode {
        case .ipv4Only:
            if ipFamily == .IPv6 {
                return .ipv4And6
            }
        case .ipv6Only:
            if ipFamily == .IPv4 {
                return .ipv4And6
            }
        case .ipv4And6:
            break
        }
        return producer.ipMode
    }
    
    /**
     Called when a debug socket log is produced.
     
     - Parameters:
        - logMessage: The debug message.

    */
    func debugSocketLog(_ logMessage: String) {
        delegateQueue.async { self.debugDelegate?.debugSocketLog(logMessage) }
    }
    
}

// MARK: -
// MARK: -

/**
 OTP Consumer Delegate
 
 Required methods for objects implementing this delegate.

*/

public protocol OTPConsumerDelegate: AnyObject {
    
    /**
     Notifies the delegate of all points.
     
     - Parameters:
        - points: Merged points from all online producers sorted with the lowest address first.

    */
    func replaceAllPoints(_ points: [OTPPoint])
    
    /**
     Notifies the delegate that a consumer has changes for points.
     
     - Parameters:
        - points: The points with changes.

    */
    func changes(forPoints points: [OTPPoint])
    
    /**
     Notifies the delegate that a producer's status has changed.
     
     - Parameters:
        - producer: The producer which has changed.

    */
    func producerStatusChanged(_ producer: OTPProducerStatus)
    
    /**
     Notifies the delegate of the system numbers of producers on the network being advertised to this consumer.
     
     - Parameters:
        - systemNumbers: The system numbers this consumer has discovered.
     
    */
    func discoveredSystemNumbers(_ systemNumbers: [OTPSystemNumber])

}


