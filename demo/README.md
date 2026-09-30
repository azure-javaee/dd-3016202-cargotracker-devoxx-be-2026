# Eclipse Cargo Tracker - Applied Domain-Driven Design Blueprints for Java EE

## Overview

The project demonstrates how you can develop applications with Java EE 7 using widely adopted architectural best practices like Domain-Driven
Design (DDD). The project is directly based on the well known 
original [Java DDD sample application](http://dddsample.sourceforge.net) 
developed by DDD pioneer Eric Evans' company Domain Language and the Swedish 
software consulting company Citerus. The cargo example actually comes from 
Eric Evans' seminal book on DDD. The original application is written in Spring,
Hibernate and Jetty whereas the application is built on Java EE 7.

The application is an end-to-end system for keeping track of shipping cargo. It 
has several interfaces described in the following sections.

For further details on the project, please visit: https://github.com/eclipse-ee4j/cargotracker.
 
## Getting Started

The [project site](https://projects.eclipse.org/projects/ee4j.cargotracker/) has detailed information on how to get started.

The simplest steps are the following:

* Get the project source code.
* To run on JDK 17 with Open Liberty, set `JAVA_HOME` to a JDK 17 installation
  and run: `./mvnw clean package liberty:run`
* Go to http://localhost:8080/cargo-tracker/

## Exploring the Application

After the application runs, it will be available at: 
http://localhost:8080/cargo-tracker/. Under the hood, the application uses a 
number of Java EE 7 features including Faces 2.2, CDI, EJB 3.2,
Persistence 2.1, REST 2, WebSocket, JSON Processing, Bean Validation 1.1 and Messaging 2.

There are several web interfaces, REST interfaces and a file system scanning
interface. It's probably best to start exploring the interfaces in the rough
order below.

The tracking interface let's you track the status of cargo and is
intended for the general public. Try entering a tracking ID like ABC123 (the 
application is pre-populated with some sample data).

The administrative interface is intended for the shipping company that manages
cargo. The landing page of the interface is a dashboard providing an overall 
view of registered cargo. You can book cargo using the booking interface.
One cargo is booked, you can route it. When you initiate a routing request,
the system will determine routes that might work for the cargo. Once you select
a route, the cargo will be ready to process handling events at the port. You can
also change the destination for cargo if needed or track cargo.

The Incident Logging interface is intended for port personnel registering what 
happened to cargo. The interface is primarily intended for mobile devices, but
you can use it via a desktop browser. The interface is accessible at:
http://localhost:8080/cargo-tracker/eventLogger/. For convenience, you
could use a mobile emulator instead of an actual mobile device. Generally speaking cargo
goes through these events:

* It's received at the origin port.
* It's loaded and unloaded onto voyages on it's itinerary.
* It's claimed at it's destination port.
* It may go through customs at arbitrary points.

While filling out the event registration form, it's best to have the itinerary 
handy. You can access the itinerary for registered cargo via the admin interface. The cargo handling is done via Messaging for scalability. While using the incident logger, note that only the load 
and unload events require as associated voyage.

You should also explore the file system based bulk event registration interface. 
It reads files under /tmp/uploads. The files are just CSV files. A sample CSV
file is available under [src/test/resources/handling_events.csv](src/test/resources/handling_events.csv). The sample is already set up to match the remaining itinerary events for cargo ABC123. Just make sure to update the times in the first column of the sample CSV file to match the itinerary as well.

Sucessfully processed entries are archived under /tmp/archive. Any failed records are 
archived under /tmp/failed.

Don't worry about making mistakes. The application is intended to be fairly 
error tolerant. If you do come across issues, you should [report them](https://github.com/eclipse-ee4j/cargotracker/issues).

*All data entered is wiped upon application restart, so you can start from 
a blank slate easily if needed.*

You can also use the soapUI scripts included in the source code to explore the 
REST interfaces as well as the numerous unit tests covering the code base 
generally.

## Exploring the Code

As mentioned earlier, the real point of the application is demonstrating how to 
create well architected, effective Java EE 7 applications. To that end, once you
have gotten some familiarity with the application functionality the next thing 
to do is to dig right into the code.

DDD is a key aspect of the architecture, so it's important to get at least a 
working understanding of DDD. As the name implies, Domain-Driven Design is an 
approach to software design and development that focuses on the core domain and 
domain logic.

For the most part, it's fine if you are new to Java EE 7. As long as you have a
basic understanding of server-side applications, the code should be good enough to get started. For learning Java EE further,
we have recommended a few links in the resources section of the project site. Of 
course, the ideal user of the project is someone who has a basic working 
understanding both Java EE and DDD. Though it's not our goal to become a kitchen
sink example for demonstrating the vast amount of APIs and features in Java EE,
we do use a very representative set. You'll find that you'll learn a fair amount
by simply digging into the code to see how things are implemented.

## Exploring the Tests

Cargo Tracker's tests use JUnit and Arquillian with the managed Open Liberty
container. From the `demo/` directory, run `./mvnw clean package` to execute
the tests and build the deployable WAR.
