# OTPConsumer

OTP Consumer

``` swift
final public class OTPConsumer: Component
```

An `OTPConsumer` is the intended target of information from an `OTPProducer`.

Consumers are OTP Components.

Initialized Consumers may have their name, observed systems and supported modules changed. It is also possible to change the delegates without reinitializing.

Example usage:

``` swift
   
   // create a new dispatch queue to receive delegate notifications
   let queue = DispatchQueue(label: "com.danielmurfin.OTPKit.consumerQueue")
 
   // a unique identifier for this consumer
   let uniqueIdentifier = UUID()
 
   // observe the position and parent modules
   let moduleTypes = [OTPModulePosition.self, OTPModuleParent.self]
 
   // creates a new IPv6 only consumer which observes systems 1 and 20 and receives delegate notifications a maximum of every 50 ms
   let consumer = OTPConsumer(name: "My Consumer", cid: uniqueIdentifier, ipMode: ipv6Only, interface: "en0", moduleTypes: moduleTypes, observedSystems: [1,20], delegateQueue: Self.delegateQueue, delegateInterval: 50)
 
   // request consumer delegate notifications
   consumer.setConsumerDelegate(self)
 
   // starts the consumer transmitting network data
   consumer.start()
 
```

## Inheritance

`Component`

## Initializers

### `init(name:cid:ipMode:interface:moduleTypes:observedSystems:delegateQueue:delegateInterval:)`

Creates a new Consumer using a name, interface and delegate queue, and optionally a CID, IP Mode, modules.

``` swift
public init(name: String, cid: UUID = UUID(), ipMode: OTPIPMode = .ipv4Only, interface: String, moduleTypes: [OTPModule.Type], observedSystems: [OTPSystemNumber], delegateQueue: DispatchQueue, delegateInterval: Int)
```

The CID of a Consumer should persist across launches, so should be stored in persistent storage.

#### Parameters

  - name: The human readable name of this Consumer.
  - cid: Optional: CID for this Consumer.
  - ipMode: Optional: IP mode for this Consumer (IPv4/IPv6/Both).
  - interface: The network interface for this Consumer. The interface may be a name (e.g. "en1" or "lo0") or the corresponding IP address (e.g. "192.168.4.35").
  - moduleTypes: An array of Module Types which the Consumer should observe.
  - systemNumbers: An array of System Numbers this Consumer should observe.
  - delegateQueue: A delegate queue on which to receive delegate calls from this Consumer.
  - delegateInterval: The minimum interval between `ConsumerDelegate` notifications (values permitted 1-10000ms).

## Methods

### `setConsumerDelegate(_:)`

Changes the consumer delegate of this consumer to the the object passed.

``` swift
public func setConsumerDelegate(_ delegate: OTPConsumerDelegate?)
```

#### Parameters

  - delegate: The delegate to receive notifications.

### `setProtocolErrorDelegate(_:)`

Changes the protocol error delegate of this consumer to the the object passed.

``` swift
public func setProtocolErrorDelegate(_ delegate: OTPComponentProtocolErrorDelegate?)
```

#### Parameters

  - delegate: The delegate to receive notifications.

### `setDebugDelegate(_:)`

Changes the protocol error delegate of this consumer to the the object passed.

``` swift
public func setDebugDelegate(_ delegate: OTPComponentDebugDelegate?)
```

#### Parameters

  - delegate: The delegate to receive notifications.

### `start()`

Starts this Consumer.

``` swift
public func start() throws
```

The Consumer will begin transmitting OTP Advertisement Messages, and listening for OTP Advertisement and OTP Transform Messages.

When a Consumer starts, it begins transmitting supported modules. It waits for 12 s, then starts transmitting System Advertisement Messages to discover the System Numbers being transmitted by Producers on the network.

System Advertisement Messages:

Requests for System Number are transmitted every 10 s. When System Numbers are received from a Producer, they are compared with a combined list of System Numbers from all Producers discovered. If a System Number is being advertised and it is also observed by this Consumer, then a multicast join is performed. When a System Number is no longer being transmitted then a multicast leave is performed.

#### Throws

An error of type `ComponentSocketError`.

### `stop()`

Stops this Consumer.

``` swift
public func stop()
```

When stopped, this Consumer will no longer transmit or listen for OTP Messages.

### `update(name:)`

Updates the human-readable name of this Consumer.

``` swift
public func update(name: String)
```

#### Parameters

  - name: A human-readable name for this consumer.

### `addModuleTypes(_:)`

Adds additional module types to those supported by this Consumer.

``` swift
public func addModuleTypes(_ moduleTypes: [OTPModule.Type])
```

#### Parameters

  - moduleTypes: An array of Module Types which the Consumer should observe in addition to those already observed.

### `removeModuleTypes(_:)`

Removes module types from those supported by this Consumer.

``` swift
public func removeModuleTypes(_ moduleTypes: [OTPModule.Type])
```

#### Parameters

  - moduleTypes: An array of Module Types which the Consumer should no longer observe.

### `observeSystemNumbers(_:)`

Updates the system numbers that are observed by this Consumer.

``` swift
public func observeSystemNumbers(_ systemNumbers: [OTPSystemNumber])
```

#### Parameters

  - systemNumbers: An array of System Numbers this Consumer should observe.

### `requestProducerPointNames()`

Requests point names from all Producers.

``` swift
public func requestProducerPointNames()
```

Names are also requested whenever a Producer is first discovered.

When changed names are received, updated points will be provided to the `ConsumerDelegate` via `changes(forPoints: [OTPPoint])`.
