# OTPModuleScale

OTP Module Scale

``` swift
public struct OTPModuleScale: OTPModule, Equatable
```

Implements an OTP Standard Module of the Scale type and handles creation and parsing.

This data structure describes the unitless, absolute scale of the Point in the X, Y, and Z directions. The Scale Module may be used for description of Points that have the ability to change size.

Example usage:

``` swift

   // initialize a module at x = actual size, y = actual size, z = half size
   let module = OTPModuleScale(x: 1000000, y: 1000000, z: 500000)
 
```

## Inheritance

`Equatable`, [`OTPModule`](OTPModule)

## Initializers

### `init()`

Initializes this `OTPModule` with default values.

``` swift
public init()
```

### `init(x:y:z:)`

Initializes an OTP Module Scale.

``` swift
public init(x: Int32 = 1000000, y: Int32 = 1000000, z: Int32 = 1000000)
```

#### Parameters

  - x: The scale of the x axis in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
  - y: The scale of the y axis in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).
  - z: The scale of the z axis in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).

## Properties

### `identifier`

Uniquely identifies the module using an `OTPModuleIdentifier`.

``` swift
let identifier: OTPModuleIdentifier
```

### `dataLength`

The size of the module's data in bytes.

``` swift
let dataLength: OTPPDULength
```

### `moduleLength`

The total size of the module in bytes, including identifiers and length.

``` swift
let moduleLength: OTPPDULength
```

### `x`

The X scale in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).

``` swift
var x: Int32
```

### `y`

The Y scale in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).

``` swift
var y: Int32
```

### `z`

The Z scale in unitless millionths i.e 1,000,000 = reference size (x1), 500,000 = half reference size (0.5x).

``` swift
var z: Int32
```

### `logDescription`

A human-readable log description of this module.

``` swift
var logDescription: String
```

## Methods

### `createAsData()`

Creates a Module as Data.

``` swift
public func createAsData() -> Data
```

#### Returns

The `OTPModule `as a `Data` object.

### `parse(fromData:)`

Attempts to create an `OTPModuleScale` from the data.

``` swift
public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

#### Parameters

  - data: The data to be parsed.

#### Throws

An error of type `ModuleLayerValidationError`.

#### Returns

A valid `OTPModuleScale` and the length of the PDU.

### `merge(modules:)`

Merges an arrray of modules.

``` swift
public static func merge(modules: [OTPModule]) -> (module: Self?, excludePoint: Bool)
```

> Precondition: All modules must be of the same type.

#### Parameters

  - modules: The `OTPModule`s to be merged.

#### Returns

An optional `OTPModule` of this type, and whether to exclude the `OTPPoint` due to a mismatch.

### `isEqualToModule(_:)`

Calculates whether this module is considered equal to another one.

``` swift
public func isEqualToModule(_ module: OTPModule) -> Bool
```

> Precondition: Both modules must be of the same type.

#### Parameters

  - module: The `OTPModule` to be compared against.

#### Returns

Whether these `OTPModule`s are considered equal.

### `validValue(from:)`

Calculates a valid value for this fields in this module from the string provided.

``` swift
public static func validValue(from string: String) -> Int32
```

#### Parameters

  - string: The string to be evaluated.

#### Returns

A valid value for storing in this module.
