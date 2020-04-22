# OTPProducerDelegate

OTP Producer Delegate

``` swift
public protocol OTPProducerDelegate: AnyObject
```

Required methods for objects implementing this delegate.

## Inheritance

`AnyObject`

## Requirements

## consumerStatusChanged(\_:)

Notifies the delegate that a consumer's status has changed.

``` swift
func consumerStatusChanged(_ consumer: OTPConsumerStatus)
```

### Parameters

  - consumer: The consumer which has changed.
