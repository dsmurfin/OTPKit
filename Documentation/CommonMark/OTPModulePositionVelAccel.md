# OTPModulePositionVelAccel

OTP Module Position Velocity/Acceleration

``` swift
public struct OTPModulePositionVelAccel: OTPModule, Equatable
```

Implements an OTP Standard Module of the Position Velocity/Acceleration type and handles creation and parsing.

This data structure contains the positional velocity and acceleration of a Point. Velocity is provided in μm/s, and Acceleration in μm/s².

Example usage:

``` 

   // initialize a module at vX = 0.5m/s, vY = 0m/s, vZ = 0m/s and aX = 0.05m/s², aY = 0m/s², aZ = 0m/s²
   let module = OTPModulePositionVelAccel(vX: 500000, vY: 0, vZ: 0, aX: 50000, aY: 0, aZ: 0)
 
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

Initializes an OTP Module Position Velocity/Acceleration.

``` swift
public init(vX: Int32, vY: Int32, vZ: Int32, aX: Int32, aY: Int32, aZ: Int32)
```

#### Parameters

  - vX: The X position velocity in μm/s.
  - vY: The Y position velocity in μm/s.
  - vZ: The Z position velocity in μm/s.
  - aX: The X position acceleration in μm/s².
  - aY: The Y position acceleration in μm/s².
  - aZ: The Z position acceleration in μm/s².

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

### `vX`

The X position velocity in μm/s.

``` swift
var vX: Int32
```

### `vY`

The Y position velocity in μm/s.

``` swift
var vY: Int32
```

### `vZ`

The Z position velocity in μm/s.

``` swift
var vZ: Int32
```

### `aX`

The X position acceleration in μm/s².

``` swift
var aX: Int32
```

### `aY`

The Y position acceleration in μm/s².

``` swift
var aY: Int32
```

### `aZ`

The Z position acceleration in μm/s².

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

Attempts to create an `OTPModulePositionVelocityAccel` from the data.

``` swift
public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

#### Parameters

  - data: The data to be parsed.

#### Throws

An error of type `ModuleLayerValidationError`.

#### Returns

A valid `OTPModulePositionVelocityAccel` and the length of the PDU.

### `merge(modules:)`

Merges an arrray of modules.

``` swift
public static func merge(modules: [OTPModule]) -> (module: Self?, excludePoint: Bool)
```

#### Parameters

  - modules: The `OTPModule`s to be merged.

#### Returns

An optional `OTPModule` of this type, and whether to exclude the `OTPPoint` due to a mismatch.

### `isEqualToModule(_:)`

Compares these modules for equality.

``` swift
public func isEqualToModule(_ module: OTPModule) -> Bool
```

#### Parameters

  - module: The module to compare against.

#### Returns

Whether these modules are equal.
