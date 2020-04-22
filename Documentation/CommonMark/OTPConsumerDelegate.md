# OTPConsumerDelegate

OTP Consumer Delegate

``` swift
public protocol OTPConsumerDelegate: AnyObject
```

Required methods for objects implementing this delegate.

## Inheritance

`AnyObject`

## Requirements

## replaceAllPoints(\_:)

Notifies the delegate of all points.

``` swift
func replaceAllPoints(_ points: [OTPPoint])
```

### Parameters

  - points: Merged points from all online producers sorted with the lowest address first.

## changes(forPoints:)

Notifies the delegate that a consumer has changes for points.

``` swift
func changes(forPoints points: [OTPPoint])
```

### Parameters

  - points: The points with changes.

## producerStatusChanged(\_:)

Notifies the delegate that a producer's status has changed.

``` swift
func producerStatusChanged(_ producer: OTPProducerStatus)
```

### Parameters

  - producer: The producer which has changed.

## discoveredSystemNumbers(\_:)

Notifies the delegate of the system numbers of producers on the network being advertised to this consumer.

``` swift
func discoveredSystemNumbers(_ systemNumbers: [OTPSystemNumber])
```

### Parameters

  - systemNumbers: The system numbers this consumer has discovered.
