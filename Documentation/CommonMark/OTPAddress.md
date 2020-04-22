# OTPAddress

OTP Address

``` swift
public struct OTPAddress: Comparable, Hashable
```

The combination of `OTPSystemNumber`, `OTPGroupNumber`, and `OTPPointNumber` make up the `OTPAddress` which identifies an `OTPPoint`.

It is intended that addresses are unique within the network, but duplicate addresses are handled using either the `OTPPriority` or merging algorithms.

## Inheritance

`Comparable`, `Hashable`

## Initializers

### `init(systemNumber:groupNumber:pointNumber:)`

Initializes a new OTP Address.

``` swift
public init(systemNumber: OTPSystemNumber, groupNumber: OTPGroupNumber, pointNumber: OTPPointNumber) throws
```

#### Parameters

  - systemNumber: The System Number.
  - groupNumber: The Group Number.
  - pointNumber: The Point Number.

#### Throws

An error of type `PointValidationError`

### `init(_:_:_:)`

Initializes a new OTP Address.

``` swift
public init(_ systemNumber: OTPSystemNumber, _ groupNumber: OTPGroupNumber, _ pointNumber: OTPPointNumber) throws
```

#### Parameters

  - systemNumber: The System Number.
  - groupNumber: The Group Number.
  - pointNumber: The Point Number.

#### Throws

An error of type `PointValidationError`

## Properties

### `systemNumber`

The system number component.

``` swift
var systemNumber: OTPSystemNumber
```

### `groupNumber`

The group number component.

``` swift
var groupNumber: OTPGroupNumber
```

### `pointNumber`

The point number component.

``` swift
var pointNumber: OTPPointNumber
```

### `description`

A human-readable description of the address in the approved format.

``` swift
var description: String
```

## Methods

### `==(lhs:rhs:)`

OTP Address `Equatable`

``` swift
public static func ==(lhs: Self, rhs: Self) -> Bool
```

#### Parameters

  - lhs: The first instance to be compared.
  - rhs: The second instance to be compared.

#### Returns

Whether the instances are considered equal.

### `<(lhs:rhs:)`

OTP Address `Comparable`

``` swift
public static func <(lhs: Self, rhs: Self) -> Bool
```

#### Parameters

  - lhs: The first instance to be compared.
  - rhs: The second instance to be compared.

#### Returns

Whether the first instance is considered smaller than the second.

### `hash(into:)`

OTP Address `Hashable`

``` swift
public func hash(into hasher: inout Hasher)
```

#### Parameters

  - hashable: The hasher to use when combining the components of this instance.
