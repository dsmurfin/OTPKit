# OTPProducer

OTP Producer

``` swift
final public class OTPProducer: Component
```

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

   } catch let error as? OTPPointValidationError {
       
       // handle error
       print(error.logDescription)
 
   } catch let error {
 
       // handle unknown error
       print(error)
 
   }
 
```

## Inheritance

`Component`

## Initializers

### `init(name:cid:ipMode:interface:priority:interval:delegateQueue:)`

Creates a new Producer using a name, interface and delegate queue, and optionally a CID, IP Mode, Priority, interval.

``` swift
public init(name: String, cid: UUID = UUID(), ipMode: OTPIPMode = .ipv4Only, interface: String, priority: UInt8 = 100, interval: Int = 50, delegateQueue: DispatchQueue)
```

The CID of a Producer should persist across launches, so should be stored in persistent storage.

#### Parameters

  - name: The human readable name of this Producer.
  - cid: Optional: CID for this Producer.
  - ipMode: Optional: IP mode for this Producer (IPv4/IPv6/Both).
  - interface: The network interface for this Consumer. The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.4.35").
  - priority: Optional: Default Priority for this Producer, used when Points do not have explicit priorities (values permitted 0-200).
  - interval: Optional: Interval for Transform Messages from this Producer (values permitted 1-50ms).
  - delegateQueue: A delegate queue on which to receive delegate calls from this Producer.

## Methods

### `setProducerDelegate(_:)`

Changes the producer delegate of this producer to the the object passed.

``` swift
public func setProducerDelegate(_ delegate: OTPProducerDelegate?)
```

#### Parameters

  - delegate: The delegate to receive notifications.

### `setProtocolErrorDelegate(_:)`

Changes the protocol error delegate of this producer to the the object passed.

``` swift
public func setProtocolErrorDelegate(_ delegate: OTPComponentProtocolErrorDelegate?)
```

#### Parameters

  - delegate: The delegate to receive notifications.

### `setDebugDelegate(_:)`

Changes the protocol error delegate of this producer to the the object passed.

``` swift
public func setDebugDelegate(_ delegate: OTPComponentDebugDelegate?)
```

#### Parameters

  - delegate: The delegate to receive notifications.

### `start()`

Starts this Producer.

``` swift
public func start() throws
```

The Producer will begin transmitting and listening for OTP Advertisement Messages.

When a Producer starts, it first waits for 12 s to receive modules being advertised by Consumers. Once this time has elapsed, the Producer will begin transmitting Transform Messages at the interval specified. Any modules which have not been received within the last 30 s are purged.

Transform Messages:

Producers only transmit Points which have been sampled at least once, and have Modules which have been requested by Consumers within the last 30 s.

Name Advertisement Messages:

When a request for Point names is received, the Producer will transmit all non-empty Point names for Points which have at least one Module that has been requested by Consumers.

System Advertisement Messages:

When a request for System Numbers is received, the Producer will transmit all the System Numbers of all Points which have been sampled at least once, and have Modules which have been requested by Consumers within the last 30 s.

#### Throws

An error of type `ComponentSocketError`.

### `stop()`

Stops this Producer.

``` swift
public func stop()
```

When stopped, this Component will no longer transmit or listen for OTP Messages.

### `update(name:)`

Updates the human-readable name of this Producer.

``` swift
public func update(name: String)
```

#### Parameters

  - name: A human-readable name for this producer.

### `addPoint(with:priority:name:)`

Adds a new Point with this Address and optionally Priority. If a Priority is not provided, the default Priority for this Producer is used.

``` swift
public func addPoint(with address: OTPAddress, priority: UInt8? = nil, name: String = "") throws
```

A single Producer shall not use the same Address to describe multiple Points, unless they represent the same point on the same physical object and are transmitted using different priorities. *See E1.59 Section 7.1.2.2.*

If a name is provided, and an existing point exists with the same address, its name will be updated to the name provided, as names must be consistent for all points using the same address regardless of priority.

#### Parameters

  - address: The Address of the Point.
  - priority: Optional: An optional Priority for this Point.
  - name: Optional: A human-readable name for this Point.

#### Throws

An error of type `PointValidationError`.

### `removePoints(with:priority:)`

Removes any existing Points with this Address and optionally Priority. If a Priority is not provided, all Points with this Address are removed.

``` swift
public func removePoints(with address: OTPAddress, priority: UInt8? = nil) throws
```

#### Parameters

  - address: The Address of the Points to be removed.
  - priority: Optional: An optional priority for the Point to be removed.

#### Throws

An error of type `PointValidationError`.

### `renamePoints(with:name:)`

Renames any existing Points with this Address. All points using the same address must have the same name, even if they are transmitted with different priorities.

``` swift
public func renamePoints(with address: OTPAddress, name: String) throws
```

#### Parameters

  - address: The Address of the Points to be renamed.
  - name: The name to be assigned to the Points.

#### Throws

An error of type `PointValidationError`.

### `addModule(_:toPoint:priority:)`

Adds a new module to the Point with this Address and optionally Priority. If a Priority is not provided, this Module is added to all Points with this Address.

``` swift
public func addModule(_ module: OTPModule, toPoint address: OTPAddress, priority: UInt8? = nil) throws
```

#### Parameters

  - module: The Module to be added.
  - address: The Address of the Point this Module should be added to.
  - priority: Optional: An optional Priority for the Point this Module should be added to.

#### Throws

An error of type `PointValidationError`

### `removeModule(with:fromPoint:priority:)`

Removes an existing Module with the Module Identifier provided from any Point with this Address and optionally Priority. If a Priority is not provided, Modules with this Module Identifier are removed from all Points with this Address.

``` swift
public func removeModule(with moduleIdentifier: OTPModuleIdentifier, fromPoint address: OTPAddress, priority: UInt8? = nil) throws
```

#### Parameters

  - moduleIdentifier: The Module Identifier of the Module to be removed.
  - address: The Address of the Point this Module should be removed from.
  - priority: Optional: An optional Priority for the Point this Module should be removed from.

#### Throws

An error of type `PointValidationError`

### `updateModule(_:forPoint:priority:)`

Updates this module for the Point with this Address and optionally Priority. If a Priority is not provided, this Module is updated for all Points using this Address.

``` swift
public func updateModule(_ module: OTPModule, forPoint address: OTPAddress, priority: UInt8? = nil) throws
```

#### Parameters

  - module: The Module to be added.
  - address: The Address of the Point this Module should be added to.
  - priority: Optional: An optional Priority for the Point this Module should be added to.

#### Throws

An error of type `PointValidationError`
