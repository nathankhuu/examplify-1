# Examplify

Make useful example code from your existing code.

## Annoying, brittle installation requirements

### Platform requirements

The only workable configuration I have found for satisfying
Soot and the Node `java` packages is to have JDK version 1.7
as the primary Java VM.

With our version of Java 1.7, we needed to add a few symbolic
links so that Soot gets the class definitions it expects. See
https://github.com/Sable/soot/issues/686 for details on the
hack we are following.

### Installation instructions

Start out by installing all of the Node dependencies for the
package by running

```bash
npm install
```
in the `examplify` folder.

This project requires Soot, a static analysis tool, to run.
The classes for Soot are stored in a pretty large JAR.  It's
not included in the repository, so for right now, you can
run this helper script to fetch the dependencies.

```bash
cd java/libs
./fetch_libs.sh
```

You will also need to compile all of the Java analyses once
before the plugin can run correctly.  To do this, you can
run the `runtests.sh` script (see below).

## Developing

### Java tests

To make sure that the static analysis code is working properly:

```bash
cd java/
./runtests.sh
```

### Running Soot

After following the dependency instructions above, you should
be able to run [Soot](https://github.com/Sable/soot) to
generate intermediate representation.  To run soot, use the
following commands:

```bash
CLASSPATH=$JAVA_HOME/jre/lib/rt.jar:libs/*:. java soot.Main Example -src-prec java -f J
```

Substitute `Example` with the name of your `.java` file
(though omit the `.java` extension).  This file will need to
be placed in the same directory as the one that you are
running the command.  The options do the following:
* `-src-prec java`: runs Soot on a `.java` file instead of a
    `.class` file
* `-f J`: produces a Jimple IR file (instead of a class)

### Style Guide

When possible, I use this style guide for Coffeescript:
https://github.com/polarmobile/coffeescript-style-guide

#### Equality checks

When implementing equality checks, call the method `equals`.
The method should take in another object as a parameter and
return a Boolean of whether the two objects are equal.

#### Accessors

Members of an object should only be accessed by other
objects through accessors (`get` methods).

#### Enums

When defining enums, define each field as an object.  This
make comparisons with an equals sign use values that are
exclusive to each class, instead of comparing just on the
fields of the object.

### Troubleshooting

#### When running specs on examplify in Atom

* If all else fails you need to install your packages and then run `npm rebuild --runtime=electron --target=1.3.4 --disturl=https://atom.io/download/atom-shell --abi=49` where 1.3.4 is your electron version and 49 is the abi it's expecting. (Source: https://github.com/electron-userland/electron-builder/issues/453)

#### Compiling example code

* InstallCert: Compile code with debug flags, e.g., `javac -g tests/scenarios/InstallCertFolder/InstallCert.java`
* Chat Client: Don't forget to specify the classpath when compiling with debug flags, e.g., `CLASSPATH=tests/scenarios/Basic-Java-Instant-Messenger/IMClient/src/ javac -g tests/scenarios/Basic-Java-Instant-Messenger/IMClient/src/ClientTest.java`
* Polyglot: `./runclass.sh PrimitiveValueAnalysis libs/polyglot.jar:libs/java_cup.jar:libs/pao.jar:tests/scenarios/polyglot-simple/ Main` and `./runclass.sh PrimitiveValueAnalysis tests/scenarios/polyglot-simple/ Main`
