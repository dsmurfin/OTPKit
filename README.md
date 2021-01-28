# OTPKit

A Swift Package (SPM) implementation of ANSI E1.59 - 2021, Entertainment Technology - Object Transform Protocol (OTP).

Provides complete protocol implementations of OTP Producer and Consumer components using IPv4/6 (OTP-4, OTP-6, OTP-4/6).

Current revision: Document Number: CP/2018-1034r5.

[Download](https://tsp.esta.org/tsp/documents/published_docs.php) the full standard document.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Requires Swift 5.2  
macOS 10.14+, iOS 10+

### Installing

#### Xcode 11+

To add the package dependency to your Xcode project, select File > Swift Packages > Add Package Dependency and enter the repository URL:

https://github.com/dsmurfin/OTPKit

#### Swift Package Manager

Simply add the package dependency to your Package.swift and depend on "OTPKit" in the necessary targets:

``` dependencies: [
.package(url: "https://github.com/dsmurfin/OTPKit", from: "1.0.0")
]
```

#### Manual

Include OTPKit in your project by adding the source files directly, but you should probably be using a dependency manager to keep up to date.


### Importing

Import into your project files using Swift:

``` swift
import OTPKit
```

### Usage

Full documentation can be found in the project [wiki](https://github.com/dsmurfin/OTPKit/wiki).

**OTPKit is fully Grand Central Dispatch (GCD) based and Thread-Safe**  
It runs entirely within its own GCD DispatchQueue(s), and is completely thread-safe. Further, the delegate methods are all invoked asynchronously onto a DispatchQueue of your choosing. This means parallel operation of your OTP code, and your delegate/processing code.

#### Producer

Creating a Producer:

``` swift
// create a new dispatch queue to receive delegate notifications
let queue = DispatchQueue(label: "com.danielmurfin.OTPKit.producerQueue")

// a unique identifier for this producer
let uniqueIdentifier = UUID()

// creates a new IPv4 only producer, which has a default priority of 120, and transmits changes every 10 ms
let producer = OTPProducer(name: "My Producer", cid: uniqueIdentifier, ipMode: ipv4Only, interface: "en0", priority: 120, interval: 10, delegateQueue: Self.delegateQueue)
```

Starting a Producer:

``` swift
// starts the producer transmitting network data
producer.start()
```

Adding a Point and Module to a Producer:

``` swift
do {
   
    let address = try OTPAddress(1,2,10)

    // add a new point using the producer's default priority (120)
    try producer.addPoint(with: address, name: "My Point")

    // create a new position module with default values
    let module = OTPModulePosition()

    // add this module to all points with this address
    producer.addModule(module, toPoint: address)

} catch let error as OTPPointValidationError {
    
    // handle error
    print(error.logDescription)

} catch let error {

    // handle unknown error
    print(error)

}
```

Register to receive delegate notifications from Producer:

``` swift
// request producer delegate notifications
producer.setProducerDelegate(self)
```

### Consumer

Creating a Consumer:

``` swift
// create a new dispatch queue to receive delegate notifications
let queue = DispatchQueue(label: "com.danielmurfin.OTPKit.consumerQueue")

// a unique identifier for this consumer
let uniqueIdentifier = UUID()

// observe the position and reference frame modules
let moduleTypes = [OTPModulePosition.self, OTPModuleReferenceFrame.self]

// creates a new IPv6 only consumer which observes systems 1 and 20 and receives delegate notifications a maximum of every 50 ms
let consumer = OTPConsumer(name: "My Consumer", cid: uniqueIdentifier, ipMode: ipv6Only, interface: "en0", moduleTypes: moduleTypes, observedSystems: [1,20], delegateQueue: Self.delegateQueue, delegateInterval: 50)
```

Starting a Consumer:

``` swift
// starts the consumer transmitting network data
consumer.start()
```

Register to receive delegate notifications from Producer:

``` swift
// request consumer delegate notifications
consumer.setConsumerDelegate(self)
```

## Deployment

This package is ready for deployment in live systems. It may also be used for testing and evaluation.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/dsmurfin/OTPKit/tags). 

## Authors

* **Daniel Murfin** - *Initial work* - [dsmurfin](https://github.com/dsmurfin)

See also the list of [contributors](https://github.com/dsmurfin/OTPKit/graphs/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Socket library dependency [CocoaSyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)
* Includes [CwlUtils](https://github.com/mattgallagher/CwlUtils) from [Matt Gallagher] (https://www.cocoawithlove.com)
