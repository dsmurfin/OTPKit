# OTPModule

OTP Module

``` swift
public protocol OTPModule
```

An OTP Module contains specific transform information about an `OTPPoint` such as position, rotation and hierarchy.

Implementors providing their own module types must implement all of these requirements for creating, sending and parsing received modules of that type.

## Requirements

## identifier

Uniquely identifies the module using an `OTPModuleIdentifier`.

``` swift
var identifier: OTPModuleIdentifier
```

## dataLength

The size of the module's data in bytes.

``` swift
var dataLength: OTPPDULength
```

## moduleLength

The total size of the module in bytes, including identifiers and length.

``` swift
var moduleLength: OTPPDULength
```

## logDescription

A human-readable log description of this module.

``` swift
var logDescription: String
```

## createAsData()

Creates a Module as Data.

``` swift
func createAsData() -> Data
```

### Returns

The `OTPModule` as a `Data` object.

## parse(fromData:)

Attempts to create an `OTPModule` from the data.

``` swift
static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

### Parameters

  - data: The data to be parsed.

### Throws

An error of type `ModuleLayerValidationError`.

### Returns

A valid `OTPModule` and the length of the PDU.

## merge(modules:)

Merges an arrray of modules.

``` swift
static func merge(modules: [OTPModule]) -> (module: Self?, excludePoint: Bool)
```

> Precondition: All modules must be of the same type.

### Parameters

  - modules: The `OTPModule`s to be merged.

### Returns

An optional `OTPModule` of this type, and whether to exclude the `OTPPoint` due to a mismatch.

## isEqualToModule(\_:)

Calculates whether this module is considered equal to another one.

``` swift
func isEqualToModule(_ module: OTPModule) -> Bool
```

> Precondition: Both modules must be of the same type.

### Parameters

  - module: The `OTPModule` to be compared against.

### Returns

Whether these `OTPModule`s are considered equal.
