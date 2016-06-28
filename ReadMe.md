## Javaversion
Javaversion is a command line tool for printing the java runtime version
for which a give JAR file was compiled.

###Usage
####General Usage
javaversion file1.jar file2.jar
####Targeted usage
find . -name "*.jar" | xargs -I file javaversion file

This tool is written in the [Nim language](http://nim-lang.org).
To build, you need the Nim compiler installed and the [Nimble build tool](https://github.com/nim-lang/nimble).
Clone the project, cd to the directory and execute 'nimble build'.

This project has a dependency on the libzip library.