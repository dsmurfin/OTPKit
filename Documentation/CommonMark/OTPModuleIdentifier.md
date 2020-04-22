# OTPModuleIdentifier

OTP Module Identifier

``` swift
public struct OTPModuleIdentifier: Comparable, Hashable
```

The combination of `OTPManufacturerID`, `OTPModuleNumber`, which uniquely identifies an `OTPModule`.

## Inheritance

`Comparable`, `Hashable`

## Properties

### `logDescription`

A human-readable log description of this module identifier

``` swift
var logDescription: String
```

## Methods

### `<(lhs:rhs:)`

OTP Module Identifier `Comparable`

``` swift
public static func <(lhs: Self, rhs: Self) -> Bool
```

#### Parameters

  - lhs: The first instance to be compared.
  - rhs: The second instance to be compared.

#### Returns

Whether the first instance is considered smaller than the second.
