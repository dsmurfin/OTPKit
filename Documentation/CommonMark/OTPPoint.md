# OTPPoint

OTP Point

``` swift
public struct OTPPoint: Comparable, Hashable
```

The smallest, indivisible component having properties of motion. This may be the center of a complex Object, or merely one of many Points on it.

OTP Points are identified using an `OTPAddress`, and contain `OTPModule`s containing transform information about the point. They may optionally have a CID identifier and sampled timestamp for a winning `OTPProducer`.

## Inheritance

`Comparable`, `Hashable`

## Initializers

### `init(address:priority:name:)`

Initializes a new OTP Point.

``` swift
public init(address: OTPAddress, priority: UInt8, name: String = "")
```

#### Parameters

  - address: The Address of the Point.
  - priority: The Priority for this Point.
  - name: Optional: A human-readable name for this Point.

## Properties

### `address`

The `OTPAddress` identifying the point.

``` swift
var address: OTPAddress
```

### `priority`

The priority of the point, used when arbitrating between multiple points with the same `OTPAddress`.

``` swift
var priority: UInt8
```

### `name`

A human-readable name for this point.

``` swift
var name: String
```

### `modules`

The modules for this point.

``` swift
var modules: [OTPModule]
```

### `cid`

An optional winning CID for this point (when from a producer).

``` swift
var cid: UUID?
```

### `sampled`

An optional sampled time for this point (when from a producer).

``` swift
var sampled: UInt64?
```

## Methods

### `==(lhs:rhs:)`

OTP Point `Equatable`

``` swift
public static func ==(lhs: Self, rhs: Self) -> Bool
```

#### Parameters

  - lhs: The first instance to be compared.
  - rhs: The second instance to be compared.

#### Returns

Whether the instances are considered equal.

### `<(lhs:rhs:)`

OTP Point `Comparable`

``` swift
public static func <(lhs: Self, rhs: Self) -> Bool
```

#### Parameters

  - lhs: The first instance to be compared.
  - rhs: The second instance to be compared.

#### Returns

Whether the first instance is considered smaller than the second.

### `hash(into:)`

OTP Point `Hashable`

``` swift
public func hash(into hasher: inout Hasher)
```

#### Parameters

  - hashable: The hasher to use when combining the components of this instance.
