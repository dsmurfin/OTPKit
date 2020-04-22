# OTPComponentState

OTP Component State

``` swift
public enum OTPComponentState
```

The transmit state of a component (offline, advertising, online).

Enumerates the possible states of an `OTPComponent`.

## Inheritance

`String`

## Enumeration Cases

### `offline`

This component is offline.

``` swift
case offline
```

### `advertising`

This component is only responding to advertisement messages.

``` swift
case advertising
```

### `online`

This component is transmitting transform messages.

``` swift
case online
```
