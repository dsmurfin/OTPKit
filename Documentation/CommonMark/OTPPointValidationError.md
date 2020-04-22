# OTPPointValidationError

Point Validation Error

``` swift
public enum OTPPointValidationError
```

Enumerates all possible Point parsing errors.

## Inheritance

`LocalizedError`

## Enumeration Cases

### `invalidPointNumber`

The point number is out-of-range.

``` swift
case invalidPointNumber
```

### `invalidGroupNumber`

The group number is out-of-range.

``` swift
case invalidGroupNumber
```

### `invalidSystemNumber`

The system number is out-of-range.

``` swift
case invalidSystemNumber
```

### `invalidPriority`

The point number is out-of-range.

``` swift
case invalidPriority
```

### `exists`

A point already exists with this `OTPAddress` and `Priority`.

``` swift
case exists
```

### `notExists`

There are no points with this `OTPAddress` and optionally `Priority`.

``` swift
case notExists(priority: Bool)
```

### `moduleExists`

This `OTPPoint` already contains an `OTPModule` with this `OTPModuleIdentifier`.

``` swift
case moduleExists
```

### `moduleSomeExist`

Some `OTPPoint`s already contain an `OTPModule` with this `OTPModuleIdentifier`.

``` swift
case moduleSomeExist
```

### `moduleNotExists`

This `OTPPoint`does not contain an `OTPModule` with this `OTPModuleIdentifier`.

``` swift
case moduleNotExists
```

### `moduleSomeNotExist`

Some `OTPPoints` with this `OTPAddress` do not contain an `OTPModule` with this `OTPModuleIdentifier`

``` swift
case moduleSomeNotExist
```

### `moduleAssociatedExists`

It is not possible to remove this `OTPModule` until all associated modules have also been removed.

``` swift
case moduleAssociatedExists
```

## Properties

### `logDescription`

A human-readable description of the error.

``` swift
var logDescription: String
```
