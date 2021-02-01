//
//  Producer.swift
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
 OTP Producer
 
 An `OTPProducer` transmits OTP Transform Messages.

 Producers are OTP Components.
 
 Initialized Producers may have their name and transmitted points/modules changed. It is also possible to change the delegates without reinitializing.
 
 Example usage:

 ``` swift
    
    // create a new dispatch queue to receive delegate notifications
    let queue = DispatchQueue(label: "com.danielmurfin.OTPKit.producerQueue")

    // a unique identifier for this producer
    let uniqueIdentifier = UUID()
 
    // creates a new IPv4 only producer, which has a default priority of 120, and transmits changes every 10 ms
    let producer = OTPProducer(name: "My Producer", cid: uniqueIdentifier, ipMode: ipv4Only, interface: "en0", priority: 120, interval: 10, delegateQueue: Self.delegateQueue)
 
    // request producer delegate notifications
    producer.setProducerDelegate(self)
 
    // starts the producer transmitting network data
    producer.start()
 
    do {
       
        let address = try OTPAddress(1,2,10)

        // add a new point using the producer's default priority (120)
        try producer.addPoint(with: address, name: "My Point")
    
        // create a new position module with default values
        let module = OTPModulePosition()
 
        // add this module to all points with this address
        producer.addModule(module, toPoint: address)

    } catch let error as OTPPointValidationError {
        
        // handle error
        print(error.logDescription)
 
    } catch let error {
 
        // handle unknown error
        print(error)
 
    }
 
 ```

*/

final public class OTPProducer: Component {
    
    /// The interval between checking for data loss.
    private static let dataLossInterval: Milliseconds = 1000

    /// The queue used for read/write operations.
    static let queue: DispatchQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.producerQueue", attributes: .concurrent)
    
    /// The queue on which socket notifications occur.
    static let socketDelegateQueue: DispatchQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.producerSocketDelegateQueue")
    
    /// The leeway used for timing. Informs the OS how accurate timings should be.
    private static let timingLeeway: DispatchTimeInterval = .nanoseconds(0)

    // MARK: General

    /// A globally unique identifier (UUID) representing the producer.
    let cid: CID
    
    /// A human-readable name for the producer.
    var name: ComponentName {
        didSet {
            if name != oldValue {
                nameData = buildNameData()
            }
        }
    }
    
    /// The Internet Protocol version(s) used by the producer.
    let ipMode: OTPIPMode
    
    /// The `name` of the producer stored as `Data`.
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
     Changes the producer delegate of this producer to the the object passed.
     
     - Parameters:
        - delegate: The delegate to receive notifications.
     
    */
    public func setProducerDelegate(_ delegate: OTPProducerDelegate?) {
        Self.queue.sync(flags: .barrier) {
            self.producerDelegate = delegate
        }
    }
    
    /**
     Changes the protocol error delegate of this producer to the the object passed.
     
     - Parameters:
        - delegate: The delegate to receive notifications.
     
    */
    public func setProtocolErrorDelegate(_ delegate: OTPComponentProtocolErrorDelegate?) {
        Self.queue.sync(flags: .barrier) {
            self.protocolErrorDelegate = delegate
        }
    }
    
    /**
     Changes the protocol error delegate of this producer to the the object passed.
     
     - Parameters:
        - delegate: The delegate to receive notifications.
     
    */
    public func setDebugDelegate(_ delegate: OTPComponentDebugDelegate?) {
        Self.queue.sync(flags: .barrier) {
            self.debugDelegate = delegate
        }
    }
    
    /// The delegate which receives notifications from this producer.
    weak var producerDelegate: OTPProducerDelegate?
    
    /// The delegate which receives protocol error notifications from this producer.
    weak var protocolErrorDelegate: OTPComponentProtocolErrorDelegate?
    
    /// The delegate which receives debug log messages from this producer.
    weak var debugDelegate: OTPComponentDebugDelegate?

    /// The queue on which to send delegate notifications.
    let delegateQueue: DispatchQueue
    
    // MARK: Timer
    
    /// The queue on which timers run.
    let timerQueue: DispatchQueue
    
    /// The timer used to delay execution of functions.
    var delayExecutionTimer: DispatchSourceTimer?
    
    // MARK: System Advertisement
    
    /// The system advertisement timer
    var systemAdvertisementTimer: DispatchSourceTimer?
    
    /// The system numbers received in advertisement messages.
    var systemNumbers: [SystemNumber]
    
    /// A pre-compiled system advertisement message as `Data`.
    var systemAdvertisementMessage: Data?
    
    /// The last transmitted system advertisement folio number for this producer.
    var systemAdvertisementFolio: FolioNumber
    
    // MARK: Name Advertisement

    /// The name advertisement timer
    var nameAdvertisementTimer: DispatchSourceTimer?
    
    /// The address point descriptions being transmitted by the producer.
    var nameAddressPointDescriptions: [AddressPointDescription]
    
    /// A pre-compiled array of name advertisement messages as `Data`.
    var nameAdvertisementMessages: [Data]
    
    /// The last transmitted name advertisement folio number for this producer.
    var nameAdvertisementFolio: FolioNumber
    
    // MARK: Module Advertisement

    /// The module advertisement timer
    var moduleAdvertisementTimer: DispatchSourceTimer?
    
    /// The module identifiers received from `OTPConsumer`s via advertisement messages.
    var moduleIdentifiers: [ModuleIdentifierNotification]
    
    // MARK: Transform

    /// The transform timer
    private var transformTimer: DispatchSourceTimer?
    
    /// The interval between transmitting system advertisement requests
    private var transformInterval: Milliseconds
    
    /// A looping counter which increments after the transform interval.
    private var transformCounter: Milliseconds
    
    /// The last transmitted transform folio numbers for every possible system of this producer 1-200 (accessed by index).
    private var transformFolios: [FolioNumber]
    
    // MARK: General

    /// The `OTPConsumer`s from which this producer has received advertisement messages.
    private var consumers: [ProducerConsumer]
    
    /// The default priority for `OTPPoint`s added to this producer.
    private var priority: Priority
    
    /// The point in time at which this producer is 'started'.
    private var timeOrigin: Date
    
    /// The points added to this producer which may be transmitted.
    private var points: [ProducerPoint]
    
    /// The timer used to evaluate for dataloss.
    private var dataLossTimer: DispatchSourceTimer?

    /// The number of points that exist for this producer.
    internal var numberOfPoints: Int {
        points.count
    }
    
    // MARK: - Initialization

    /**
     Creates a new Producer using a name, interface and delegate queue, and optionally a CID, IP Mode, Priority, interval.
     
     The CID of a Producer should persist across launches, so should be stored in persistent storage.

     - Parameters:
        - name: The human readable name of this Producer.
        - cid: Optional: CID for this Producer.
        - ipMode: Optional: IP mode for this Producer (IPv4/IPv6/Both).
        - interface: The network interface for this Consumer. The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.4.35").
        - priority: Optional: Default Priority for this Producer, used when Points do not have explicit priorities (values permitted 0-200).
        - interval: Optional: Interval for Transform Messages from this Producer (values permitted 1-50ms).
        - delegateQueue: A delegate queue on which to receive delegate calls from this Producer.

    */
    public init(name: String, cid: UUID = UUID(), ipMode: OTPIPMode = .ipv4Only, interface: String, priority: UInt8 = 100, interval: Int = 50, delegateQueue: DispatchQueue) {
        self.cid = cid
        self.name = name
        self.ipMode = ipMode
        self.nameData = name.data(paddedTo: ComponentName.maxComponentNameBytes)
        self.interface = interface
        self.unicastSocket = ComponentSocket(cid: cid, type: .unicast, interface: interface, delegateQueue: Self.socketDelegateQueue)
        self.multicast4Socket = ipMode.usesIPv4() ? ComponentSocket(cid: cid, type: .multicastv4, port: UDP.otpPort, interface: interface, delegateQueue: Self.socketDelegateQueue) : nil
        self.multicast6Socket = ipMode.usesIPv6() ? ComponentSocket(cid: cid, type: .multicastv6, port: UDP.otpPort, interface: interface, delegateQueue: Self.socketDelegateQueue) : nil
        self.delegateQueue = delegateQueue
        self.timerQueue = DispatchQueue(label: "com.danielmurfin.OTPKit.producerTimerQueue.\(cid.uuidString)")
        self.systemNumbers = []
        self.systemAdvertisementFolio = FolioNumber.min
        self.nameAddressPointDescriptions = []
        self.nameAdvertisementMessages = []
        self.nameAdvertisementFolio = FolioNumber.min
        self.moduleIdentifiers = []
        self.transformInterval = TransformLayer.nearestValidTransformInterval(to: interval)
        self.transformCounter = TransformLayer.Timing.fullPointSetMax.rawValue
        self.transformFolios = (SystemNumber.minSystemNumber...SystemNumber.maxSystemNumber+1).map { _ in FolioNumber.min }
        self.consumers = []
        self.priority = priority.nearestValidPriority()
        self.timeOrigin = Date()
        self.points = []
    }
        
    // MARK: - Public API
    
    /**
     Starts this Producer.
     
     The Producer will begin transmitting and listening for OTP Advertisement Messages.
     
     When a Producer starts, it first waits for 12 s to receive modules being advertised by Consumers. Once this time has elapsed, the Producer will begin transmitting Transform Messages at the interval specified. Any modules which have not been received within the last 30 s are purged.
     
     Transform Messages:
     
     Producers only transmit Points which have been sampled at least once, and have Modules which have been requested by Consumers within the last 30 s.
     
     Name Advertisement Messages:
     
     When a request for Point names is received, the Producer will transmit all non-empty Point names for Points which have at least one Module that has been requested by Consumers.
     
     System Advertisement Messages:
     
     When a request for System Numbers is received, the Producer will transmit all the System Numbers of all Points which have been sampled at least once, and have Modules which have been requested by Consumers within the last 30 s.
     
     - Throws: An error of type `ComponentSocketError`.

    */
    public func start() throws {

        // pre-build messages
        let systemAdvertisementMessage = buildSystemAdvertisementMessage()
        let nameAdvertisementMessages = buildNameAdvertisementMessages()
        Self.queue.sync(flags: .barrier) {
            self.systemAdvertisementMessage = systemAdvertisementMessage
            self.nameAdvertisementMessages = nameAdvertisementMessages
        }

        // port reuse must be enabled to allow multiple producers/consumers
        try multicast4Socket?.enableReusePort()
        try multicast6Socket?.enableReusePort()
        
        // this producer should be the delegate
        unicastSocket.delegate = self
        multicast4Socket?.delegate = self
        multicast6Socket?.delegate = self

        // begin listening
        try unicastSocket.startListening()
        try multicast4Socket?.startListening(multicastGroups: [IPv4.advertisementMessageHostname])
        try multicast6Socket?.startListening(multicastGroups: [IPv6.advertisementMessageHostname])
        
        // begins the required initial wait
        startInitialWait()
        
    }
    
    /**
     Stops this Producer.
     
     When stopped, this Component will no longer transmit or listen for OTP Messages.
     
    */
    public func stop() {
        
        // stops all running heartbeats
        stopTransform()
        stopModuleAdvertisement()
        stopSystemAdvertisement()
        stopDataLossTimer()
        
        // stops listening on all sockets
        unicastSocket.stopListening()
        multicast4Socket?.stopListening()
        multicast6Socket?.stopListening()
        
    }
    
    /**
     Updates the human-readable name of this Producer.
     
     - Parameters:
        - name: A human-readable name for this producer.
     
    */
    public func update(name: String) {
        
        Self.queue.sync(flags: .barrier) {
            self.name = name
        }
        
        // rebuild all messages
        let systemAdvertisementMessage = buildSystemAdvertisementMessage()
        let nameAdvertisementMessages = buildNameAdvertisementMessages()
        Self.queue.sync(flags: .barrier) { self.systemAdvertisementMessage = systemAdvertisementMessage }
        Self.queue.sync(flags: .barrier) { self.nameAdvertisementMessages = nameAdvertisementMessages }
        
    }
    
    /**
     Adds a new Point with this Address and optionally Priority. If a Priority is not provided, the default Priority for this Producer is used.
        
     A single Producer shall not use the same Address to describe multiple Points, unless they represent the same point on the same physical object and are transmitted using different priorities. *See E1.59 Section 7.1.2.2.*
     
     If a name is provided, and an existing point exists with the same address, its name will be updated to the name provided, as names must be consistent for all points using the same address regardless of priority.

     - Parameters:
        - address: The Address of the Point.
        - priority: Optional: An optional Priority for this Point.
        - name: Optional: A human-readable name for this Point.

     - Throws: An error of type `PointValidationError`.

    */
    public func addPoint(with address: OTPAddress, priority: UInt8? = nil, name: String = "") throws {

        try address.isValid()
        
        let producerPriority = Self.queue.sync(flags: .barrier) { self.priority }
        
        let thePriority = priority ?? producerPriority
        
        try thePriority.validPriority()
        
        try Self.queue.sync(flags: .barrier) {
            
            // all points matching this address
            let sameAddressPoints = self.points.filter { $0.address == address }
            
            // no existing points with the same address and priority must exist
            guard !sameAddressPoints.contains(where: { $0.priority == thePriority }) else { throw OTPPointValidationError.exists }
        
            let point = ProducerPoint(address: address, priority: thePriority, name: name)
        
            self.points.append(point)

            // if other points exist with this address rename them to match
            if sameAddressPoints.count > 0 {
                for (index, point) in self.points.enumerated() where point.address == address {
                    self.points[index].rename(name: name)
                }
            }
            
        }
        
        // delays building new lists
        delayExecution(by: Milliseconds(10)) {
            self.buildSystemNumbersList()
            self.buildNameAddressPointDescriptionsList()
        }
        
    }
    
    /**
     Removes any existing Points with this Address and optionally Priority. If a Priority is not provided, all Points with this Address are removed.

     - Parameters:
        - address: The Address of the Points to be removed.
        - priority: Optional: An optional priority for the Point to be removed.
     
     - Throws: An error of type `PointValidationError`.

    */
    public func removePoints(with address: OTPAddress, priority: UInt8? = nil) throws {
        
        try address.isValid()
                
        if let priority = priority {
            
            try priority.validPriority()
            
            try Self.queue.sync(flags: .barrier) {
            
                // an existing point with the same address and priority must exist
                guard self.points.contains(where: { $0.address == address && $0.priority == priority }) else { throw OTPPointValidationError.notExists(priority: true) }
            
                self.points = points.compactMap { $0.address == address && $0.priority == priority ? nil : $0 }
                
            }
            
        } else {
            
            try Self.queue.sync(flags: .barrier) {
            
                // an existing point with the same address must exist
                guard self.points.contains(where: { $0.address == address }) else { throw OTPPointValidationError.notExists(priority: false) }
            
                self.points = points.filter { $0.address != address }
                
            }
            
        }
        
        // delays building new lists
        delayExecution(by: Milliseconds(10)) {
            self.buildSystemNumbersList()
            self.buildNameAddressPointDescriptionsList()
        }
        
    }
    
    /**
     Renames any existing Points with this Address. All points using the same address must have the same name, even if they are transmitted with different priorities.

     - Parameters:
        - address: The Address of the Points to be renamed.
        - name: The name to be assigned to the Points.
     
     - Throws: An error of type `PointValidationError`.

    */
    public func renamePoints(with address: OTPAddress, name: String) throws {
        
        try address.isValid()

        try Self.queue.sync(flags: .barrier) {

            // an existing point with the same address must exist
            guard self.points.contains(where: { $0.address == address }) else { throw OTPPointValidationError.notExists(priority: false) }
                
            // rename each point
            for (index, point) in self.points.enumerated() where point.address == address {
                self.points[index].rename(name: name)
            }
            
        }
        
        // delays building new lists
        delayExecution(by: Milliseconds(10)) {
            self.buildNameAddressPointDescriptionsList()
        }
        
    }
    
    /**
     Adds a new module to the Point with this Address and optionally Priority. If a Priority is not provided, this Module is added to all Points with this Address.

     - Parameters:
        - module: The Module to be added.
        - address: The Address of the Point this Module should be added to.
        - priority: Optional: An optional Priority for the Point this Module should be added to.

     - Throws: An error of type `PointValidationError`

    */
    public func addModule(_ module: OTPModule, toPoint address: OTPAddress, priority: UInt8? = nil) throws {

        try address.isValid()
        
        let timeOrigin = Self.queue.sync { self.timeOrigin }
                
        if let priority = priority {
            
            try priority.validPriority()
            
            try Self.queue.sync(flags: .barrier) {

                // an existing point with the same address and priority must exist
                guard let index = self.points.firstIndex(where: { $0.address == address && $0.priority == priority }) else { throw OTPPointValidationError.notExists(priority: true) }

                try self.points[index].addModule(module, timeOrigin: timeOrigin)

                // if this module's identifier is in the list of those to be transmitted flag the point
                if self.moduleIdentifiers.map ({ $0.moduleIdentifier }).contains(where: { $0 == module.moduleIdentifier }) {
                    self.points[index].hasRequestedModules = true
                }
            
            }
            
        } else {

            try Self.queue.sync(flags: .barrier) {
            
                // at least one existing point with the same address must exist
                guard self.points.contains(where: { $0.address == address } ) else { throw OTPPointValidationError.notExists(priority: false) }
                
                // attempt to add this module to each point
                var errors = [Error]()
                for (index, point) in self.points.enumerated() where point.address == address {
                    do {
                        
                        try self.points[index].addModule(module, timeOrigin: timeOrigin)
                        
                        // if this module's identifier is in the list of those to be transmitted flag the point
                        if self.moduleIdentifiers.map ({ $0.moduleIdentifier }).contains(where: { $0 == module.moduleIdentifier }) {
                            self.points[index].hasRequestedModules = true
                        }
                        
                    } catch let error {
                        errors.append(error)
                    }
                }
                
                // did any fail?
                if !errors.isEmpty {

                    if errors.count == 1 {
                        throw errors[0]
                    } else {
                        throw OTPPointValidationError.moduleSomeExist
                    }
                    
                }
                
            }
            
        }
        
        // delays building new lists
        delayExecution(by: Milliseconds(10)) {
            self.buildSystemNumbersList()
            self.buildNameAddressPointDescriptionsList()
        }

    }
    
    /**
     Removes an existing Module with the Module Identifier provided from any Point with this Address and optionally Priority. If a Priority is not provided, Modules with this Module Identifier are removed from all Points with this Address.

     - Parameters:
        - moduleIdentifier: The Module Identifier of the Module to be removed.
        - address: The Address of the Point this Module should be removed from.
        - priority: Optional: An optional Priority for the Point this Module should be removed from.

     - Throws: An error of type `PointValidationError`

    */
    public func removeModule(with moduleIdentifier: OTPModuleIdentifier, fromPoint address: OTPAddress, priority: UInt8? = nil) throws {

        try address.isValid()
        
        if let priority = priority {
            
            try priority.validPriority()
            
            try Self.queue.sync(flags: .barrier) {
            
                // an existing point with the same address and priority must exist
                guard let index = self.points.firstIndex(where: { $0.address == address && $0.priority == priority }) else { throw OTPPointValidationError.notExists(priority: true) }
                
                try self.points[index].removeModule(with: moduleIdentifier)
                
            }
            
        } else {
            
            try Self.queue.sync(flags: .barrier) {

                // at least one existing point with the same address must exist
                guard self.points.contains(where: { $0.address == address } ) else { throw OTPPointValidationError.notExists(priority: false) }
                
                // attempt to remove a module with this identifier from each point
                var errors = [Error]()
                for (index, point) in self.points.enumerated() where point.address == address {
                    do {
                        try self.points[index].removeModule(with: moduleIdentifier)
                    } catch let error {
                        errors.append(error)
                    }
                }
                
                // did any fail?
                if !errors.isEmpty {

                    if errors.count == 1 {
                        throw errors[0]
                    } else {
                        throw OTPPointValidationError.moduleSomeNotExist
                    }
                    
                }
                
            }
            
        }
        
        // delays building new lists
        delayExecution(by: Milliseconds(10)) {
            self.buildSystemNumbersList()
            self.buildNameAddressPointDescriptionsList()
        }

    }
    
    /**
     Updates this module for the Point with this Address and optionally Priority. If a Priority is not provided, this Module is updated for all Points using this Address.

     - Parameters:
        - module: The Module to be added.
        - address: The Address of the Point this Module should be added to.
        - priority: Optional: An optional Priority for the Point this Module should be added to.

     - Throws: An error of type `PointValidationError`

    */
    public func updateModule(_ module: OTPModule, forPoint address: OTPAddress, priority: UInt8? = nil) throws {

        try address.isValid()
        
        let timeOrigin = Self.queue.sync { self.timeOrigin }
        
        if let priority = priority {
            
            try priority.validPriority()
            
            try Self.queue.sync(flags: .barrier) {
            
                // an existing point with the same address and priority must exist
                guard let index = self.points.firstIndex(where: { $0.address == address && $0.priority == priority }) else { throw OTPPointValidationError.notExists(priority: true) }
                
                try self.points[index].update(module: module, timeOrigin: timeOrigin)
                
            }
            
        } else {
            
            try Self.queue.sync(flags: .barrier) {

                // at least one existing point with the same address must exist
                guard self.points.contains(where: { $0.address == address } ) else { throw OTPPointValidationError.notExists(priority: false) }
                
                // attempt to update this module for each point
                var errors = [Error]()
                for (index, point) in self.points.enumerated() where point.address == address {
                    do {
                        try self.points[index].update(module: module, timeOrigin: timeOrigin)
                    } catch let error {
                        errors.append(error)
                    }
                }
                
                // did any fail?
                if !errors.isEmpty {
                    
                    if errors.count == 1 {
                        throw errors[0]
                    } else {
                        throw OTPPointValidationError.moduleSomeNotExist
                    }
                    
                }
                
            }
            
        }

    }

    // MARK: - Timers / Messaging
    
    /**
     Starts this Producer's required initial wait.
    */
    private func startInitialWait() {
        
        timerQueue.sync {

            let timer = DispatchSource.singleTimer(interval: .milliseconds(ModuleAdvertismentLayer.Timing.startupWait.rawValue), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.moduleAdvertisementTimer {
                    
                    // notify the debug delegate
                    self?.delegateQueue.async { self?.debugDelegate?.debugLog("Completed initial wait for module advertisement messages") }

                    // start the transform heartbeat
                    self?.startTransform()
                    
                    // start the module advertisement heartbeat
                    self?.startModuleAdvertisement()
                    
                    // start the data loss heartbeat
                    self?.startDataLossTimer()
                    
                }
                
            }
            moduleAdvertisementTimer = timer
            
        }
        
    }
    
    /**
     Starts this Producer's Module Advertisement timer.
     
     - Precondition: Must be on `timerQueue`.
     
    */
    private func startModuleAdvertisement() {
        
        // must be on the timer queue
        dispatchPrecondition(condition: .onQueue(timerQueue))

        let timer = DispatchSource.repeatingTimer(interval: .milliseconds(ModuleAdvertismentLayer.Timing.interval.rawValue), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
            
            if let _ = self?.moduleAdvertisementTimer {

                let now = Date()
                let timeout = TimeInterval(ModuleAdvertismentLayer.Timing.timeout.rawValue/1000)
                
                Self.queue.sync(flags: .barrier) {
                    
                    // only get identifiers received in the last timeout interval
                    if let newModuleIdentifiers = self?.moduleIdentifiers.filter({ now.timeIntervalSince($0.notified) < timeout }) {
                    
                        // store the new module identifier
                        self?.moduleIdentifiers = newModuleIdentifiers
                        
                        // notify the debug delegate
                        self?.delegateQueue.async { self?.debugDelegate?.debugLog("Check for stale modules. Resulting modules \(newModuleIdentifiers.map { $0.moduleIdentifier.logDescription }.joined(separator: ", "))") }
                        
                    }
                
                }
                
            }
            
        }
        moduleAdvertisementTimer = timer

    }
    
    /**
     Stops this Producer's Module Advertisement heartbeat.
    */
    private func stopModuleAdvertisement() {
        timerQueue.sync { moduleAdvertisementTimer = nil }
    }
    
    /**
     Starts this Producer's Transform heartbeat.
     
     - Precondition: Must be on `timerQueue`.

    */
    private func startTransform() {
        
        // must be on the timer queue
        dispatchPrecondition(condition: .onQueue(timerQueue))
        
        let timer = DispatchSource.repeatingTimer(interval: .milliseconds(transformInterval), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
            
            if let unwrappedSelf = self {

                // get the saved transform counter
                let transformCounter = Self.queue.sync { unwrappedSelf.transformCounter }
                
                if transformCounter > TransformLayer.Timing.fullPointSetMin.rawValue {

                    // send a full point set
                    unwrappedSelf.sendTransformMessages(withFullPointSet: true)
                    
                    // reset the counter
                    Self.queue.sync(flags: .barrier) {
                        unwrappedSelf.transformCounter = 0
                    }
                    
                } else {

                    // send changes only
                    unwrappedSelf.sendTransformMessages(withFullPointSet: false)
                    
                    // increment the counter
                    Self.queue.sync(flags: .barrier) {
                        unwrappedSelf.transformCounter += unwrappedSelf.transformInterval
                    }
                    
                }
                
            }
            
        }
        transformTimer = timer

    }
    
    /**
     Stops this Producer's Transform heartbeat.
    */
    private func stopTransform() {
        timerQueue.sync { transformTimer = nil }
    }

    /**
     Sends a System Advertisement message after a random delay.
     
     - Parameters:
        - host: The destination hostname for the message..
        - port: The destination port for the message.
     
    */
    private func sendDelayedSystemAdvertisementMessage(to host: Hostname, port: UDPPort) {
        
        timerQueue.sync {
            
            let randomTime = Int.random(in: 0...SystemAdvertismentLayer.Timing.maxBackoff.rawValue)
            
            let timer = DispatchSource.singleTimer(interval: .milliseconds(randomTime), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.systemAdvertisementTimer {
                    self?.sendSystemAdvertisementMessage(to: (host: host, port: port))
                }
                
            }
            systemAdvertisementTimer = timer
            
        }
        
    }
    
    /**
     Stops any pending System Advertisement message from sending.
    */
    private func stopSystemAdvertisement() {
        timerQueue.sync { systemAdvertisementTimer = nil }
    }
    
    /**
     Sends a Name Advertisement message after a random delay.
     
     - Parameters:
        - host: The destination hostname for the message..
        - port: The destination port for the message.
     
    */
    private func sendDelayedNameAdvertisementMessage(to host: Hostname, port: UDPPort) {
        
        timerQueue.sync {
            
            let randomTime = Int.random(in: 0...NameAdvertismentLayer.Timing.maxBackoff.rawValue)
            
            let timer = DispatchSource.singleTimer(interval: .milliseconds(randomTime), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.nameAdvertisementTimer {
                    self?.sendNameAdvertisementMessages(to: (host: host, port: port))
                }
                
            }
            nameAdvertisementTimer = timer
            
        }
        
    }
    
    /**
     Stops any pending Name Advertisement message from sending.
    */
    private func stopNameAdvertisement() {
        timerQueue.sync { nameAdvertisementTimer = nil }
    }
    
    /**
     Delays the execution of a closure.
     
     - Parameters:
        - interval: The number of milliseconds to delay the execution.
        - completion: The closure to be executed on completion.
     
    */
    private func delayExecution(by interval: Milliseconds, completion: @escaping () -> Void) {
        
        timerQueue.sync {
        
            let timer = DispatchSource.singleTimer(interval: .milliseconds(interval), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
                
                if let _ = self?.delayExecutionTimer {
                    completion()
                }
                
            }
            delayExecutionTimer = timer
            
        }

    }
    
    /**
     Stops this Producer's delayed execution timer.
    */
    private func stopDelayExecution() {
        timerQueue.sync { delayExecutionTimer = nil }
    }
    
    /**
     Starts this Producer's data loss timer.
    */
    private func startDataLossTimer() {

        // must be on the timer queue
        dispatchPrecondition(condition: .onQueue(timerQueue))
                        
        let timer = DispatchSource.repeatingTimer(interval: .milliseconds(Self.dataLossInterval), leeway: Self.timingLeeway, queue: timerQueue) { [weak self] in
            
            if let _ = self?.dataLossTimer {
                self?.checkForConsumerDataLoss()
            }
            
        }
        dataLossTimer = timer
        
    }
    
    /**
     Stops this Producer's data loss timer.
    */
    private func stopDataLossTimer() {
        timerQueue.sync { dataLossTimer = nil }
    }
    
    // MARK: - Advertisement

    
    /**
    Checks for data loss for each Consumer observed by this Producer.
    */
    func checkForConsumerDataLoss() {

        let consumers = Self.queue.sync { self.consumers }

        // all consumers which should go into an offline state (those which haven't yet been notified)
        let lostConsumers = consumers.filter { $0.shouldGoOffline }

        for consumer in lostConsumers {
            delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: consumer.name, cid: consumer.cid, ipMode: consumer.ipMode, ipAddresses: consumer.ipAddresses, sequenceErrors: consumer.sequenceErrors, state: .offline, moduleIdentifiers: consumer.moduleIdentifiers)) }
        }

        Self.queue.sync(flags: .barrier) {
         
            // flags this consumer as offline
            for (index, consumer) in self.consumers.enumerated() where lostConsumers.contains(consumer) {
                self.consumers[index].notifiedState = .offline
            }

        }

    }
    
    // MARK: - Build Lists
    
    /**
     Rebuilds the array of System Numbers assigned to Points of this Producer
    */
    private func buildSystemNumbersList() {
        
        DispatchQueue.global().async {

            let previousSystemNumbers = Self.queue.sync { self.systemNumbers }

            // get the new system numbers for all points which have modules which have been requested
            let systemNumbers = Self.queue.sync { self.points.filter { !$0.modules.isEmpty && $0.hasRequestedModules }.map { $0.address.systemNumber } }
            let newSystemNumbers = Array(Set(systemNumbers)).sorted()
            
            // if different, assign and build the advertisement message
            if newSystemNumbers != previousSystemNumbers {
                
                Self.queue.sync(flags: .barrier) {
                    self.systemNumbers = newSystemNumbers
                }
                
                let systemAdvertisementMessage = self.buildSystemAdvertisementMessage()
                
                Self.queue.sync(flags: .barrier) {
                    self.systemAdvertisementMessage = systemAdvertisementMessage
                }

            }
            
        }
        
    }
    
    /**
     Rebuilds the array of name Address Point Descriptions for this Producer
    */
    private func buildNameAddressPointDescriptionsList() {
        
        DispatchQueue.global().async {
        
            let previousAddressPointDescriptions = Self.queue.sync { self.nameAddressPointDescriptions }

            // get the new address point descriptions (must not be empty), and the point should have modules

            let addressPointDescriptions = Self.queue.sync { self.points.filter { !$0.modules.isEmpty && !$0.name.isEmpty }.map { AddressPointDescription(address: $0.address, pointName: $0.name) } }
            let newAddressPointDescriptions = Array(Set(addressPointDescriptions)).sorted()
            
            var changes = false
            for newDescription in newAddressPointDescriptions {
                
                // did this address previously exist?
                if let previousDescription = previousAddressPointDescriptions.first(where: { $0.address == newDescription.address }) {
                    
                    // was the name different?
                    if previousDescription.pointName != newDescription.pointName {
                        changes = true
                        break
                    }
                    
                    // try the next description
                    continue
                    
                }
                
                // this address doesn't exist
                changes = true
                break
                
            }
            
            // if there are changes assign and build the advertisement message
            if changes {

                Self.queue.sync(flags: .barrier) {
                    self.nameAddressPointDescriptions = newAddressPointDescriptions
                }
                
                let nameAdvertisementMessages = self.buildNameAdvertisementMessages()
                
                Self.queue.sync(flags: .barrier) {
                    self.nameAdvertisementMessages = nameAdvertisementMessages
                }
                
            }
            
        }
        
    }
    
}

// MARK: -
// MARK: -

/**
 OTP Producer Extension
 
 Extensions to `OTPProducer` to handle message creation and transmission.

*/
private extension OTPProducer {
    
    /**
     Sends the Transform Messages for this Producer.
     
     - Parameters:
        - fullPointSet: Whether a full set of Point should be sent, or only those which have changed.
     
    */
    private func sendTransformMessages(withFullPointSet fullPointSet: Bool) {

        let cid = Self.queue.sync { self.cid }
        let folios = Self.queue.sync { self.transformFolios }
        let nameData = Self.queue.sync { self.nameData }
        let systemNumbers = Self.queue.sync { self.systemNumbers }
        let timeOrigin = Self.queue.sync { self.timeOrigin }
        let moduleIdentifiers = Self.queue.sync { self.moduleIdentifiers }

        var systemMessages = [(systemNumber: SystemNumber, messages: [Data])]()
        
        // loop through all system numbers
        for systemNumber in systemNumbers {
            
            let now = Date()

            // time intervals are in seconds so convert to microseconds
            let timestamp: Timestamp = Timestamp(now.timeIntervalSince(timeOrigin) * 1000000)

            let otpLayerData = OTPLayer.createAsData(with: .transformMessage, cid: cid, nameData: nameData, folio: folios[Int(systemNumber)])
            let transformLayerData = TransformLayer.createAsData(withSystemNumber: systemNumber, timestamp: timestamp, fullPointSet: fullPointSet)

            var points = [ProducerPoint]()
            Self.queue.sync(flags: .barrier) {
                
                // get all points for this system and which should be included in messages
                points = self.points.filter { $0.address.systemNumber == systemNumber && $0.includeInMessages(fullPointSet: fullPointSet) }

                // clears the changes flag ready for future checks
                for (index, point) in self.points.enumerated() where point.address.systemNumber == systemNumber {
                    self.points[index].hasChanges = false
                }
                
            }

            // loop through all points
            var messages = [Data]()
            for (pointIndex, point) in points.enumerated() {

                // the point must have been sampled at least once (filtered in includeInMessages, but safely unwrapped here)
                guard let sampled = point.sampled else { continue }
                
                let pointLayerData = PointLayer.createAsData(withPriority: point.priority, groupNumber: point.address.groupNumber, pointNumber: point.address.pointNumber, timestamp: sampled)
                
                // get all modules supported by one or more consumers
                let supportedModules = point.modules.filter ({ module in moduleIdentifiers.contains(where: { $0.moduleIdentifier == module.moduleIdentifier }) })

                // loop through all modules for this point
                var modulesLength: OTPPDULength = 0
                for (moduleIndex, module) in supportedModules.enumerated() {
                    
                    let moduleLayerData = ModuleLayer.createAsData(with: module)
                    
                    // get the last message if it exists
                    if var lastMessage = messages.last {
                        
                        if moduleIndex == 0 && lastMessage.count + pointLayerData.count + moduleLayerData.count <= UDP.maxMessageLength {
                            
                            // this is the first module for a point, and the point and module will it in the remaining space
                            
                            // append the point
                            lastMessage += pointLayerData
                            
                            // append the module
                            lastMessage += moduleLayerData
                            
                            // there is only a single module so far
                            modulesLength = OTPPDULength(moduleLayerData.count)

                            // is this the last module?
                            if moduleIndex == supportedModules.count - 1 {
                                
                                // replace pdu lengths
                                replacePDULengths(in: &lastMessage, withModulesLength: modulesLength, lastPointInMessage: pointIndex == points.count - 1)
                                
                            }
                            
                            // replace this message
                            messages[messages.count-1] = lastMessage
                            
                        } else if moduleIndex > 0 && lastMessage.count + moduleLayerData.count <= UDP.maxMessageLength {
                            
                            // this is not the first module for a point, and the module will fit in the remaining space
                            
                            // append the module
                            lastMessage += moduleLayerData
                            
                            // increment the length of all modules for this point
                            modulesLength += UInt16(moduleLayerData.count)

                            // is this the last module?
                            if moduleIndex == supportedModules.count - 1 {
                                
                                // replace pdu lengths
                                replacePDULengths(in: &lastMessage, withModulesLength: modulesLength, lastPointInMessage: pointIndex == points.count - 1)
                                
                            }
                            
                            // replace this message
                            messages[messages.count-1] = lastMessage
                            
                        } else {
                            
                            // this module will not fit in this message, so start a new one
                            
                            // replace pdu lengths
                            replacePDULengths(in: &messages[messages.count-1], withModulesLength: modulesLength, lastPointInMessage: true)

                            // create a new message and append it
                            let message = otpLayerData + transformLayerData + pointLayerData + moduleLayerData
                            messages.append(message)
                            
                            // there is only a single module so far
                            modulesLength = OTPPDULength(moduleLayerData.count)
                            
                            // is this the last module?
                            if moduleIndex == supportedModules.count - 1 {
                                
                                // replace pdu lengths
                                replacePDULengths(in: &messages[messages.count-1], withModulesLength: modulesLength, lastPointInMessage: pointIndex == points.count - 1)
                                
                            }
                            
                        }
                        
                    } else {
                        
                        // create a new message and append it
                        let message = otpLayerData + transformLayerData + pointLayerData + moduleLayerData
                        messages.append(message)
                        
                        // there is only a single module so far
                        modulesLength = OTPPDULength(moduleLayerData.count)
                        
                        // is this the last module?
                        if moduleIndex == supportedModules.count - 1 {
                            
                            // replace pdu lengths
                            replacePDULengths(in: &messages[messages.count-1], withModulesLength: modulesLength, lastPointInMessage: pointIndex == points.count - 1)
                            
                        }
                        
                    }
                    
                }
                
            }

            // loop through all messages and replace page/last page
            for (index, _) in messages.enumerated() {
                messages[index].replacingOTPLayerPage(with: Page(index))
                messages[index].replacingOTPLayerLastPage(with: Page(index))
            }
            
            // increment the folio number for this system
            if !messages.isEmpty {
                Self.queue.sync(flags: .barrier) {
                    self.transformFolios[Int(systemNumber)] &+= 1
                }
            }
            
            // append any messages for this system
            systemMessages.append((systemNumber: systemNumber, messages: messages))
            
        }
        
        // loop through all messages
        for systemMessage in systemMessages {

            for messageData in systemMessage.messages {

                // send the message(s)
                if ipMode.usesIPv4(), let hostname = IPv4.transformHostname(for: systemMessage.systemNumber) {
                    unicastSocket.send(message: messageData, host: hostname, port: UDP.otpPort)
                }
                if ipMode.usesIPv6(), let hostname = IPv6.transformHostname(for: systemMessage.systemNumber) {
                    unicastSocket.send(message: messageData, host: hostname, port: UDP.otpPort)
                }
                
            }
            
        }
        
    }
        
    /**
     Replaces the Point, and optionally the Transform and OTP Layer Length fields as calculated.
     
     - Parameters:
        - message: The message in which to replace length fields.
        - modulesLength: The length of the modules in this Point Layer.
        - lastPointInMessage: Whether this is the last Point to be included in the message.

    */
    private func replacePDULengths(in message: inout Data, withModulesLength modulesLength: OTPPDULength, lastPointInMessage: Bool) {
        
        let pointLengthOffset = message.count - Int(modulesLength) - PointLayer.lengthOffsetFromData

        // replace the point length in this message
        message.replacingPDULength(modulesLength + PointLayer.lengthBeforeData, at: pointLengthOffset)
        
        // is this the last point
        if lastPointInMessage {
            
            // replace the otp layer length
            message.replacingPDULength(OTPPDULength(message.count - OTPLayer.lengthCountOffset), at: OTPLayer.Offset.length.rawValue)
            
            // replace the transform layer length
            message.replacingPDULength(OTPPDULength(message.count - OTPLayer.Offset.data.rawValue - TransformLayer.lengthCountOffset), at: OTPLayer.Offset.data.rawValue + TransformLayer.Offset.length.rawValue)

        }
        
    }
    
}

// MARK: -
// MARK: -

/**
 Component Socket Delegate
 
 Required methods for objects implementing this delegate.

*/

extension OTPProducer: ComponentSocketDelegate {

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

                switch otpLayer.vector {
                case .advertisementMessage:

                    // try to extract an advertisement layer
                    let advertisementLayer = try AdvertismentLayer.parse(fromData: otpLayer.data)
                    
                    // get the current list of consumers
                    let consumers = self.consumers
                    
                    // if this component is newly discovered (or coming back online) this should be its mode
                    let newComponentIPMode: OTPIPMode = ipFamily == .IPv4 ? .ipv4Only : .ipv6Only
                    
                    // if a previous message from this consumer has been received decide whether to accept it
                    if let consumer = consumers.first(where: { $0.cid == otpLayer.cid }) {
                        if consumer.notifiedState == .offline, let index = self.consumers.firstIndex(where: { $0.cid == otpLayer.cid }) {
                            // this consumer had gone offline, so start allowing messages from another IP family
                            self.consumers[index].ipMode = newComponentIPMode
                        } else {
                            switch consumer.ipMode {
                            case .ipv4Only:
                                if ipFamily == .IPv6 {
                                    updateHostnames(withHostname: hostname, ipFamily: ipFamily, forConsumer: consumer)
                                }
                            case .ipv6Only, .ipv4And6:
                                // only allow IPv6 messages to be processed
                                guard ipFamily == .IPv6 else {
                                    updateHostnames(withHostname: hostname, ipFamily: ipFamily, forConsumer: consumer)
                                    return
                                }
                            }
                        }
                    }

                    switch advertisementLayer.vector {
                    case .module:
                          
                        // if a previous message of this type has been received, it must be within the valid range (always continue if the consumer had previously gone offline)
                        if let consumer = consumers.first(where: { $0.cid == otpLayer.cid }), consumer.notifiedState != .offline, let previousFolio = consumer.moduleAdvertisementFolio, let previousPage = consumer.moduleAdvertisementPage {
                            guard otpLayer.isPartOfCurrentCommunication(previousFolio: previousFolio, previousPage: previousPage) else { throw OTPLayerValidationError.folioOutOfRange(consumer.cid) }
                        }
                        
                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Received module advertisement message from \(otpLayer.componentName) \(otpLayer.cid)") }
                        
                        // try to extract a module advertisement layer
                        let moduleAdvertisementLayer = try ModuleAdvertismentLayer.parse(fromData: advertisementLayer.data)
                        
                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Received module identifiers \(moduleAdvertisementLayer.moduleIdentifiers.map { $0.logDescription }.joined(separator: ", ")) from \(otpLayer.cid)") }
                        
                        let now = Date()
                        
                        // get all module identifiers and their associated modules
                        var moduleIdentifiersAndAssociations = [OTPModuleIdentifier]()
                        for moduleIdentifier in moduleAdvertisementLayer.moduleIdentifiers {

                            if let associations = ModuleAssociations.associations.first(where: { $0.source.identifier == moduleIdentifier })?.associated.map ({ $0.identifier }) {
                                moduleIdentifiersAndAssociations += [moduleIdentifier]
                                moduleIdentifiersAndAssociations += associations
                            } else {
                                moduleIdentifiersAndAssociations += [moduleIdentifier]
                            }
                            
                        }
              
                        // get new, and existing module identifiers
                        let receivedModuleIdentifiers = moduleIdentifiersAndAssociations.map { ModuleIdentifierNotification(moduleIdentifier: $0, notified: now) }
                        let existingModuleIdentifiers = self.moduleIdentifiers

                        // unique module identifiers, keeping newly provided over existing
                        let newModuleIdentifiers = Array(Set(receivedModuleIdentifiers).union(existingModuleIdentifiers)).sorted()

                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Resulting modules \(newModuleIdentifiers.map { $0.moduleIdentifier.logDescription }.joined(separator: ", "))") }
                                                    
                        // only rebuild if the identifiers are different
                        if newModuleIdentifiers != self.moduleIdentifiers {

                            // the module identifiers which should now be transmitted
                            let moduleIdentifiers = newModuleIdentifiers.map { $0.moduleIdentifier }
                            
                            // loop through all points
                            for (index, point) in self.points.enumerated() {

                                // do any modules for this point match those which should be transmitted?
                                let hasRequestedModules = point.modules.map { $0.moduleIdentifier }.contains(where: { moduleIdentifiers.contains($0) })

                                self.points[index].hasRequestedModules = hasRequestedModules
                                
                            }
                         
                            
                            // build the system numbers, as this may have changed due to different requested modules
                            self.buildSystemNumbersList()
                            
                        }
                        
                        // update the module identifiers stored, so the newer dates exist
                        self.moduleIdentifiers = newModuleIdentifiers
                    
                        // update or add this consumer
                        if let index = consumers.firstIndex(where: { $0.cid == otpLayer.cid }) {

                            // update the previously discovered consumers module advertisement folio number and page
                            self.consumers[index].moduleAdvertisementFolio = otpLayer.folio
                            self.consumers[index].moduleAdvertisementPage = otpLayer.page
                            
                            // a new advertisement message has been received
                            self.consumers[index].receivedAdvertisement = Date()
                            
                            let consumer = self.consumers[index]
                            
                            let existingComponentIPMode = newIPMode(from: ipFamily, for: consumer)
                                                        
                            // only send a notification if this was previously notified as offline or the name, ip address, ip mode, or module identifiers are different
                            if consumer.notifiedState == .offline || consumer.name != otpLayer.componentName || !consumer.ipAddresses.contains(hostname) || consumer.ipMode != existingComponentIPMode || consumer.moduleIdentifiers != moduleAdvertisementLayer.moduleIdentifiers {
                                                           
                                // the consumer is now advertising
                                if consumer.notifiedState == .offline {
                                    self.consumers[index].notifiedState = .advertising
                                }
                                
                                // get the newly changed state
                                let notifiedState = self.consumers[index].notifiedState
                                
                                let newIpAddresses = Array(Set(consumer.ipAddresses).union(Set([hostname]))).sorted()

                                // notify the delegate of the consumer status
                                self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: otpLayer.componentName, cid: consumer.cid, ipMode: existingComponentIPMode, ipAddresses: newIpAddresses, sequenceErrors: consumer.sequenceErrors, state: notifiedState, moduleIdentifiers: moduleAdvertisementLayer.moduleIdentifiers)) }
                                
                                // update both name and ip when this happens
                                self.consumers[index].name = otpLayer.componentName
                                self.consumers[index].ipAddresses = newIpAddresses
                                self.consumers[index].ipMode = existingComponentIPMode
                                self.consumers[index].moduleIdentifiers = moduleAdvertisementLayer.moduleIdentifiers

                            }
                            
                        } else {

                            // create a new consumer and append it
                            let consumer = ProducerConsumer(cid: otpLayer.cid, name: otpLayer.componentName, ipMode: newComponentIPMode, ipAddress: hostname, moduleAdvertisementFolio: otpLayer.folio, moduleAdvertisementPage: otpLayer.page, moduleIdentifiers: moduleAdvertisementLayer.moduleIdentifiers)
                            
                            self.consumers.append(consumer)
                            
                            // notify the delegate of the consumer status
                            self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: otpLayer.componentName, cid: otpLayer.cid, ipMode: newComponentIPMode, ipAddresses: [hostname], sequenceErrors: consumer.sequenceErrors, state: .advertising, moduleIdentifiers: moduleAdvertisementLayer.moduleIdentifiers)) }
                            
                        }
                                                
                    case .name:
                        
                        // if a previous message of this type has been received, it must be within the valid range (always continue if the consumer had previously gone offline)
                        if let consumer = consumers.first(where: { $0.cid == otpLayer.cid }), consumer.notifiedState != .offline, let previousFolio = consumer.nameAdvertisementFolio, let previousPage = consumer.nameAdvertisementPage {
                            guard otpLayer.isPartOfCurrentCommunication(previousFolio: previousFolio, previousPage: previousPage) else { throw OTPLayerValidationError.folioOutOfRange(consumer.cid) }
                        }

                        // try to extract a name advertisement layer
                        let response = try NameAdvertismentLayer.parse(fromData: advertisementLayer.data)
                        
                        // this must not be a response
                        guard response == nil else { return }
                        
                        // send any name advertisement messages after a random amount of time
                        let fullHostname = ipFamily == .IPv4 ? hostname : "\(hostname)%\(interface)"
                        sendDelayedNameAdvertisementMessage(to: fullHostname, port: port)
                                                
                        // update or add this consumer
                        if let index = consumers.firstIndex(where: { $0.cid == otpLayer.cid }) {

                            self.consumers[index].nameAdvertisementFolio = otpLayer.folio
                            self.consumers[index].nameAdvertisementPage = otpLayer.page
                            
                            // a new advertisement message has been received
                            self.consumers[index].receivedAdvertisement = Date()
                                
                            let consumer = self.consumers[index]
                            
                            let existingComponentIPMode = newIPMode(from: ipFamily, for: consumer)
                            
                            // only send a notification if this was previously notified as offline or the name, ip address, or ip mode is different
                            if consumer.notifiedState == .offline || consumer.name != otpLayer.componentName || !consumer.ipAddresses.contains(hostname) || consumer.ipMode != existingComponentIPMode {
                                                           
                                // the consumer is now advertising
                                if consumer.notifiedState == .offline {
                                    self.consumers[index].notifiedState = .advertising
                                }
                                
                                // get the newly changed state
                                let notifiedState = self.consumers[index].notifiedState
                                
                                let moduleIdentifiers = consumer.moduleIdentifiers
                                
                                let newIpAddresses = Array(Set(consumer.ipAddresses).union(Set([hostname]))).sorted()
                                
                                // notify the delegate of the consumer status
                                self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: otpLayer.componentName, cid: consumer.cid, ipMode: existingComponentIPMode, ipAddresses: newIpAddresses, sequenceErrors: consumer.sequenceErrors, state: notifiedState, moduleIdentifiers: moduleIdentifiers)) }
                                
                                // update both name and ip when this happens
                                self.consumers[index].name = otpLayer.componentName
                                self.consumers[index].ipAddresses = newIpAddresses
                                self.consumers[index].ipMode = existingComponentIPMode

                            }
                            
                        } else {
                            
                            // create a new consumer and append it
                            let consumer = ProducerConsumer(cid: otpLayer.cid, name: otpLayer.componentName, ipMode: newComponentIPMode, ipAddress: hostname, nameAdvertisementFolio: otpLayer.folio, nameAdvertisementPage: otpLayer.page)

                            self.consumers.append(consumer)
                            
                            // notify the delegate of the consumer status
                            self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: otpLayer.componentName, cid: otpLayer.cid, ipMode: newComponentIPMode, ipAddresses: [hostname], sequenceErrors: consumer.sequenceErrors, state: .advertising, moduleIdentifiers: [])) }
                            
                            
                        }
                                                    
                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Received name advertisement message from \(otpLayer.componentName) \(otpLayer.cid)") }
                        
                    case .system:
                        
                        // if a previous message of this type has been received, it must be within the valid range (always continue if the consumer had previously gone offline)
                        if let consumer = consumers.first(where: { $0.cid == otpLayer.cid }), consumer.notifiedState != .offline, let previousFolio = consumer.systemAdvertisementFolio {
                            guard otpLayer.isPartOfCurrentCommunication(previousFolio: previousFolio) else { throw OTPLayerValidationError.folioOutOfRange(consumer.cid) }
                        }

                        // try to extract a system advertisement layer
                        let response = try SystemAdvertismentLayer.parse(fromData: advertisementLayer.data, delegate: nil, delegateQueue: delegateQueue)
                        
                        // this must not be a response
                        guard response == nil else { return }
                        
                        // send a system advertisement message after a random amount of time
                        let fullHostname = ipFamily == .IPv4 ? hostname : "\(hostname)%\(interface)"
                        sendDelayedSystemAdvertisementMessage(to: fullHostname, port: port)
                                                
                        // update or add this consumer
                        if let index = consumers.firstIndex(where: { $0.cid == otpLayer.cid }) {
                            
                            // update the previously discovered consumers system advertisement folio number
                            self.consumers[index].systemAdvertisementFolio = otpLayer.folio
                            
                            // a new advertisement message has been received
                            self.consumers[index].receivedAdvertisement = Date()
                            
                            let consumer = self.consumers[index]
                            
                            let existingComponentIPMode = newIPMode(from: ipFamily, for: consumer)
                            
                            // only send a notification if this was previously notified as offline or the name, ip address, or ip mode is different
                            if consumer.notifiedState == .offline || consumer.name != otpLayer.componentName || !consumer.ipAddresses.contains(hostname) || consumer.ipMode != existingComponentIPMode {
                                                           
                                // the consumer is now advertising
                                if consumer.notifiedState == .offline {
                                    self.consumers[index].notifiedState = .advertising
                                }
                                
                                // get the newly changed state
                                let notifiedState = self.consumers[index].notifiedState
                                
                                let moduleIdentifiers = consumer.moduleIdentifiers
                                
                                let newIpAddresses = Array(Set(consumer.ipAddresses).union(Set([hostname]))).sorted()
                                
                                // notify the delegate of the consumer status
                                self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: otpLayer.componentName, cid: consumer.cid, ipMode: existingComponentIPMode, ipAddresses: newIpAddresses, sequenceErrors: consumer.sequenceErrors, state: notifiedState, moduleIdentifiers: moduleIdentifiers)) }
                                
                                // update both name and ip when this happens
                                self.consumers[index].name = otpLayer.componentName
                                self.consumers[index].ipAddresses = newIpAddresses
                                self.consumers[index].ipMode = existingComponentIPMode

                            }
                            
                        } else {
                            
                            // create a new consumer and append it
                            let consumer = ProducerConsumer(cid: otpLayer.cid, name: otpLayer.componentName, ipMode: newComponentIPMode, ipAddress: hostname, systemAdvertisementFolio: otpLayer.folio)

                            self.consumers.append(consumer)
                            
                            // notify the delegate of the consumer status
                            self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: otpLayer.componentName, cid: otpLayer.cid, ipMode: newComponentIPMode, ipAddresses: [hostname], sequenceErrors: consumer.sequenceErrors, state: .advertising, moduleIdentifiers: [])) }
                            
                        }
                                                    
                        // notify the debug delegate
                        delegateQueue.async { self.debugDelegate?.debugLog("Received system advertisement message from \(otpLayer.componentName) \(otpLayer.cid)") }

                    }

                case .transformMessage:
                    // producers don't care about transform messages
                    break
                }
                
            } catch let error as OTPLayerValidationError {
                       
                switch error {
                case .lengthOutOfRange, .invalidPacketIdentifier:
                   
                   // these errors should not be notified
                   break
                    
                case let .folioOutOfRange(cid):
                        
                    if let index = self.consumers.firstIndex(where: { $0.cid == cid }) {

                        // increment the sequence errors
                        self.consumers[index].sequenceErrors &+= 1
                        
                        let consumer = self.consumers[index]
                        
                        let consumerStatus = OTPConsumerStatus(name: consumer.name, cid: cid, ipMode: consumer.ipMode, ipAddresses: consumer.ipAddresses, sequenceErrors: consumer.sequenceErrors, state: consumer.notifiedState, moduleIdentifiers: consumer.moduleIdentifiers)
                        
                        // notify the delegate
                        self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(consumerStatus) }
                        
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
     Called to update hostnames and discovered IP families for a consumer.
     
     This should only be used when a consumer message is rejected due to invalid IP family checks.
     
     - Parameters:
        - hostname: A new hostname for this consumer.
        - ipFamily: The `ComponentSocketIPFamily` that this message was received on.
        - consumer: The consumer to be updated.
     
     - Precondition: Must be on `queue`.

    */
    private func updateHostnames(withHostname hostname: String, ipFamily: ComponentSocketIPFamily, forConsumer consumer: ProducerConsumer) {
        // must be on the producer read/write queue
        dispatchPrecondition(condition: .onQueue(Self.queue))
        
        let newIpMode = newIPMode(from: ipFamily, for: consumer)
        
        if (!consumer.ipAddresses.contains(hostname) || consumer.ipMode != newIpMode), let index = self.consumers.firstIndex(where: { $0.cid == consumer.cid }) {
            let newIpAddresses = Array(Set(consumer.ipAddresses).union(Set([hostname]))).sorted()

            // notify the delegate of the consumer status
            self.delegateQueue.async { self.producerDelegate?.consumerStatusChanged(OTPConsumerStatus(name: consumer.name, cid: consumer.cid, ipMode: newIpMode, ipAddresses: newIpAddresses, sequenceErrors: consumer.sequenceErrors, state: consumer.notifiedState, moduleIdentifiers: consumer.moduleIdentifiers)) }
            
            self.consumers[index].ipAddresses = newIpAddresses
            self.consumers[index].ipMode = newIpMode
        }
    }
    
    /**
     Calculates a new `OTPIPMode` from the existing mode and the newly received IP family.
     
     - Parameters:
        - ipFamily: The `ComponentSocketIPFamily` that this message was received on.
        - consumer: The consumer to be evaluated.
     
     - Precondition: Must be on `queue`.

    */
    private func newIPMode(from ipFamily: ComponentSocketIPFamily, for consumer: ProducerConsumer) -> OTPIPMode {
        // must be on the consumer read/write queue
        dispatchPrecondition(condition: .onQueue(Self.queue))
        
        switch consumer.ipMode {
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
        return consumer.ipMode
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
 OTP Producer Delegate
 
 Required methods for objects implementing this delegate.

*/

public protocol OTPProducerDelegate: AnyObject {

    /**
     Notifies the delegate that a consumer's status has changed.
     
     - Parameters:
        - consumer: The consumer which has changed.

    */
    func consumerStatusChanged(_ consumer: OTPConsumerStatus)

}



