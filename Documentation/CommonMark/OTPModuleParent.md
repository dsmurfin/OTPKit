# OTPModuleParent

OTP Module Parent

``` swift
public struct OTPModuleParent: OTPModule, Hashable
```

Implements an OTP Standard Module of the Parent type and handles creation and parsing.

This data structure contains the Address of the Parent of the Point and a flag which indicates whether other modules contained in this Point are relative to the Parent Point.

Example usage:

``` 

   do {
       
       let address = try OTPAddress(1,2,10)
 
       let module = OTPModuleParent(address: address, relative: false)
 
       // do something with module
 
   } catch {
       // handle error
   }
 
```

## Inheritance

`Hashable`, [`OTPModule`](OTPModule)

## Initializers

### `init()`

Initializes this `OTPModule` with default values.

``` swift
public init()
```

### `init(address:relative:)`

Initializes an OTP Module Parent.

``` swift
public init(address: OTPAddress, relative: Bool = false)
```

#### Parameters

  - address: The Address of the Parent Point.
  - relative: Whether this Points other Modules contain values relative to the Parent Point.

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

### `relative`

Whether the other `OTPModule`s contained within the same `OTPPoint` have values which are relative to the parent point.

``` swift
var relative: Bool
```

### `systemNumber`

The `OTPSystemNumber ` of the parent of the `OTPPoint` containing this module.

``` swift
var systemNumber: OTPSystemNumber
```

### `groupNumber`

The `OTPGroupNumber ` of the parent of the `OTPPoint` containing this module.

``` swift
var groupNumber: OTPGroupNumber
```

### `pointNumber`

The `OTPPointNumber ` of the parent of the `OTPPoint` containing this module.

``` swift
var pointNumber: OTPPointNumber
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

Attempts to create an `OTPModuleParent` from the data.

``` swift
public static func parse(fromData data: Data) throws -> (module: Self, length: OTPPDULength)
```

#### Parameters

  - data: The data to be parsed.

#### Throws

An error of type `ModuleLayerValidationError`.

#### Returns

A valid `OTPModuleParent` and the length of the PDU.

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
