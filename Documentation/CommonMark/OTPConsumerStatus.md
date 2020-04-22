# OTPConsumerStatus

OTP Consumer Status

``` swift
public struct OTPConsumerStatus: OTPComponentStatus
```

Stores the status of an `OTPConsumer`, including its name, state (online/offline) and errors.

Used by implementors for displaying information about discovered Consumers.

## Inheritance

[`OTPComponentStatus`](OTPComponentStatus)

## Initializers

### `init(name:cid:ipAddress:sequenceErrors:state:moduleIdentifiers:)`

Creates a new OTP Consumer Status.

``` swift
public init(name: String, cid: UUID, ipAddress: String, sequenceErrors: Int, state: OTPComponentState, moduleIdentifiers: [OTPModuleIdentifier])
```

Includes identifying and status information.

#### Parameters

  - name: The human-readable name of this Consumer.
  - cid: The CID of this Consumer.
  - ipAddress: The IP Address of this Consumer.
  - sequenceErrors: The number of sequence errors from this Consumer.
  - state: The state of this Consumer.
  - moduleIdentifiers: The supported module identifiers of this Consumer.

## Properties

### `cid`

A globally unique identifier (UUID) representing the consumer, compliant with RFC 4122.

``` swift
let cid: UUID
```

### `name`

A human-readable name for the consumer.

``` swift
var name: String
```

### `ipAddress`

The IP address of the consumer.

``` swift
var ipAddress: String
```

### `sequenceErrors`

The number of sequence errors in advertisement messages from the consumer.

``` swift
var sequenceErrors: Int
```

### `state`

The state of this consumer.

``` swift
var state: OTPComponentState
```

### `supportedModuleIdentifiers`

A list of the module identifiers supported by this consumer.

``` swift
var supportedModuleIdentifiers: [String]
```
