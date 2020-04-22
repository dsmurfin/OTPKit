# OTPComponentProtocolErrorDelegate

OTP Component Protocol Error Delegate

``` swift
public protocol OTPComponentProtocolErrorDelegate: AnyObject
```

Required methods for objects implementing this delegate.

## Inheritance

`AnyObject`

## Requirements

## layerError(\_:)

Notifies the delegate of errors in parsing layers.

``` swift
func layerError(_ errorDescription: String)
```

### Parameters

  - errorDescription: A human-readable description of the error.

## sequenceError(\_:)

Notifies the delegate of sequence errors.

``` swift
func sequenceError(_ errorDescription: String)
```

### Parameters

  - errorDescription: A human-readable description of the error.

## unknownError(\_:)

Notifies the delegate of unknown errors.

``` swift
func unknownError(_ errorDescription: String)
```

### Parameters

  - errorDescription: A human-readable description of the error.
