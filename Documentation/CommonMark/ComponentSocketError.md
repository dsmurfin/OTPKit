# ComponentSocketError

Component Socket Error

``` swift
public enum ComponentSocketError
```

Enumerates all possible `ComponentSocketError` errors.

## Inheritance

`LocalizedError`

## Enumeration Cases

### `couldNotEnablePortReuse`

It was not possible to enable port reuse.

``` swift
case couldNotEnablePortReuse
```

### `couldNotJoin`

It was not possible to join this multicast group.

``` swift
case couldNotJoin(multicastGroup: String)
```

### `couldNotLeave`

It was not possible to leave this multicast group.

``` swift
case couldNotLeave(multicastGroup: String)
```

### `couldNotBind`

It was not possible to bind to a port/interface.

``` swift
case couldNotBind(message: String)
```

### `couldNotReceive`

It was not possible to start receiving data, e.g. because no bind occured first.

``` swift
case couldNotReceive(message: String)
```

## Properties

### `logDescription`

A human-readable description of the error useful for logging purposes.

``` swift
var logDescription: String
```
