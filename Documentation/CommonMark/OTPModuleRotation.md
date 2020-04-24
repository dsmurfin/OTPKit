# OTPModuleRotation

OTP Module Rotation

``` swift
public struct OTPModuleRotation: OTPModule, Equatable
```

Implements an OTP Standard Module of the Rotation type and handles creation and parsing.

This data structure contains the current rotation of the Point using intrinsic Euler rotation calculated in the x-convention (the Tait-Bryan ZYX convention). Rotation is provided in millionths of a decimal degree i.e. 45,000,000 = 45° and shall be in the range 0-359999999 (0°-359.999999°).

Example usage:

``` swift

   // initialize a module at x = 45°, y = 0°, z = 45°
   let module = OTPModuleRotation(x: 45000000, y: 0, z: 45000000)
 
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

Initializes an OTP Module Rotation.

``` swift
public init(x: UInt32, y: UInt32, z: UInt32)
```

If values outside of the permitted range are used (0-359,999,999), the remainder will be initialized, for example when initialized as 450,000,000 (450°), the resulting initialized value will be 90,000,000 (90°).

#### Parameters

  - x: The X rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
  - y: The Y rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.
  - z: The Z rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.

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

### `minPermitted`

The minimum permitted value for all variables in this module.

``` swift
let minPermitted: UInt32
```

### `maxPermitted`

The maximum permitted value for all variables in this module.

``` swift
let maxPermitted: UInt32
```

### `x`

The X rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.

``` swift
var x: UInt32
```

### `y`

The Y rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.

``` swift
var y: UInt32
```

### `z`

The Z rotation in millionths of a decimal degree i.e. 45,000,000 = 45°.

``` swift
var z: UInt32
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

Attempts to create an `OTPModuleRotation` from the data.

``` swift
public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

#### Parameters

  - data: The data to be parsed.

#### Throws

An error of type `ModuleLayerValidationError`.

#### Returns

A valid `OTPModuleRotation` and the length of the PDU.

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
public static func validValue(from string: String) -> UInt32
```

#### Parameters

  - string: The string to be evaluated.

#### Returns

A valid value for storing in this module.
