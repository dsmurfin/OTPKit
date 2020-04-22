# OTPComponentDebugDelegate

OTP Component Debug Delegate

``` swift
public protocol OTPComponentDebugDelegate: AnyObject
```

Required methods for objects implementing this delegate.

## Inheritance

`AnyObject`

## Requirements

## debugLog(\_:)

Notifies the delegate of a new debug log entry.

``` swift
func debugLog(_ logMessage: String)
```

### Parameters

  - logMessage: A human-readable log message.

## debugSocketLog(\_:)

Notifies the delegate of a new socket debug log entry.

``` swift
func debugSocketLog(_ logMessage: String)
```

### Parameters

  - logMessage: A human-readable log message.
