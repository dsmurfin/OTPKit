# OTPComponentStatus

OTP Component Status

``` swift
public protocol OTPComponentStatus
```

All `OTPConsumerStatus`s and `OTPProducerStatus`s are OTP Components.

The core requirements of an OTP Component Status.

## Requirements

## cid

A globally unique identifier (UUID) representing the component, compliant with RFC 4122.

``` swift
var cid: UUID
```

## name

A human-readable name for the component.

``` swift
var name: String
```

## ipAddress

The IP address of the component.

``` swift
var ipAddress: String
```

## sequenceErrors

The number of sequence errors in advertisement messages from the component.

``` swift
var sequenceErrors: Int
```

## state

The state of this component.

``` swift
var state: OTPComponentState
```
