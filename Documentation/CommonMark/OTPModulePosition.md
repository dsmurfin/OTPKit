# OTPModulePosition

OTP Module Position

``` swift
public struct OTPModulePosition: OTPModule, Equatable
```

Implements an OTP Standard Module of the Position type and handles creation and parsing.

This data structure contains the current position of a Point in all three linear directions (x, y, z), and scaling indicating whether units are in μm or mm.

Example usage:

``` swift

   // initialize a module at x = 0.002m, y = 1m, z = 2m
   let module = OTPModulePosition(x: 2000, y: 1000000, z: 2000000, scaling: .μm)
 
```

## Inheritance

`Equatable`, [`OTPModule`](OTPModule)

## Initializers

### `init()`

Initializes this `OTPModule` with default values.

``` swift
public init()
```

### `init(x:y:z:scaling:)`

Initializes an OTP Module Position.

``` swift
public init(x: Int32, y: Int32, z: Int32, scaling: Scaling)
```

#### Parameters

  - x: The X position in units dependent on `scaling`.
  - y: The Y position in units dependent on `scaling`.
  - z: The Z position in units dependent on `scaling`.
  - scaling: The scaling of the position.

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

### `scaling`

The scaling of the position values in this module.

``` swift
var scaling: Scaling
```

### `x`

The X position in units dependent on `scaling`.

``` swift
var x: Int32
```

### `y`

The Y position in units dependent on `scaling`.

``` swift
var y: Int32
```

### `z`

The Z position in units dependent on `scaling`.

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

Attempts to create an `OTPModulePosition` from the data.

``` swift
public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

#### Parameters

  - data: The data to be parsed.

#### Throws

An error of type `ModuleLayerValidationError`.

#### Returns

A valid `OTPModulePosition` and the length of the PDU.

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
