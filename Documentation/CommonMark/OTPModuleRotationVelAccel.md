# OTPModuleRotationVelAccel

OTP Module Rotation Velocity/Acceleration

``` swift
public struct OTPModuleRotationVelAccel: OTPModule, Equatable
```

Implements an OTP Standard Module of the Rotation Velocity/Acceleration type and handles creation and parsing.

This data structure contains the rotational velocity and acceleration of a Point. Velocity is provided in thousandths of a decimal degree/s, and Acceleration in thousandths of a decimal degree/s².

This module supports velocities as low as 0.001 degrees/s and as high as 1000 revolutions/s. For example, a value of 45,000 for vX would mean a rotation of 45 degrees/s, or 0.125 revolutions/s, or 7.5 rpm.

Example usage:

``` 

   // initialize a module at vX = 0°/s, vY = 0°/s, vZ = 15°/s and aX = 0°/s², aY = 0°/s², aZ = 5°/s²
   let module = OTPModuleRotationVelAccel(vX: 0, vY: 0, vZ: 15000, aX: 0, aY: 0, aZ: 5000)
 
```

## Inheritance

`Equatable`, [`OTPModule`](OTPModule)

## Initializers

### `init()`

Initializes this `OTPModule` with default values.

``` swift
public init()
```

### `init(vX:vY:vZ:aX:aY:aZ:)`

Initializes an OTP Module Rotation Velocity/Acceleration.

``` swift
public init(vX: Int32, vY: Int32, vZ: Int32, aX: Int32, aY: Int32, aZ: Int32)
```

#### Parameters

  - vX: The X rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
  - vY: The Y rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
  - vZ: The Z rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.
  - aX: The X rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
  - aY: The Y rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².
  - aZ: The Z rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².

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
let minPermitted: Int32
```

### `maxPermitted`

The maximum permitted value for all variables in this module.

``` swift
let maxPermitted: Int32
```

### `vX`

The X rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.

``` swift
var vX: Int32
```

### `vY`

The Y rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.

``` swift
var vY: Int32
```

### `vZ`

The Z rotation velocity in thousandths of a decimal degree/s i.e. 5,000 = 5°/s.

``` swift
var vZ: Int32
```

### `aX`

The X rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².

``` swift
var aX: Int32
```

### `aY`

The Y rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².

``` swift
var aY: Int32
```

### `aZ`

The Z rotation acceleration in thousandths of a decimal degree/s² i.e. 5,000 = 5°/s².

``` swift
var aZ: Int32
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

Attempts to create an `OTPModuleRotationVelocityAccel` from the data.

``` swift
public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

#### Parameters

  - data: The data to be parsed.

#### Throws

An error of type `ModuleLayerValidationError`.

#### Returns

A valid `OTPModuleRotationVelocityAccel` and the length of the PDU.

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
