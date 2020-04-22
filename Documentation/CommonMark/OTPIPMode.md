# OTPIPMode

IP Mode

``` swift
public enum OTPIPMode
```

The Internet Protocol version used by a Component.

  - ipv4Only: Only use IPv4

<!-- end list -->

  - ipv6Only: Only use IPv6

<!-- end list -->

  - ipv4And6: Use IPv4 and IPv6

## Inheritance

`CaseIterable`, `String`

## Enumeration Cases

### `ipv4Only`

The `Component` should only use IPv4.

``` swift
case ipv4Only
```

### `ipv6Only`

The `Component` should only use IPv6.

``` swift
case ipv6Only
```

### `ipv4And6`

The `Component` should use IPv4 and IPv6.

``` swift
case ipv4And6
```

## Properties

### `titles`

An array of titles for all cases.

``` swift
var titles: [String]
```

### `title`

The title for this case.

``` swift
var title: String
```
