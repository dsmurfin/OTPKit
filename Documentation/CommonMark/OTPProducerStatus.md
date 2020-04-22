# OTPProducerStatus

OTP Producer Status

``` swift
public struct OTPProducerStatus: OTPComponentStatus
```

Stores the status of an `OTPProducer`, including its name, state (online/offline) and errors.

Used by implementors for displaying information about discovered Producers.

## Inheritance

[`OTPComponentStatus`](OTPComponentStatus)

## Initializers

### `init(name:cid:ipAddress:sequenceErrors:state:)`

Creates a new OTP Producer Status.

``` swift
public init(name: String, cid: UUID, ipAddress: String, sequenceErrors: Int, state: OTPComponentState)
```

Includes identifying and status information.

#### Parameters

  - name: The human-readable name of this Producer.
  - cid: The CID of this Producer.
  - ipAddress: The IP Address of this Producer.
  - sequenceErrors: The number of sequence errors from this Producer.
  - state: The state of this Producer.
  - online: Optional: Whether this Producer is considered online.

## Properties

### `cid`

A globally unique identifier (UUID) representing the producer, compliant with RFC 4122.

``` swift
let cid: UUID
```

### `name`

A human-readable name for the producer.

``` swift
var name: String
```

### `ipAddress`

The IP address of the producer.

``` swift
var ipAddress: String
```

### `sequenceErrors`

The number of sequence errors in advertisement messages from the producer.

``` swift
var sequenceErrors: Int
```

### `state`

The status of this producer.

``` swift
var state: OTPComponentState
```
