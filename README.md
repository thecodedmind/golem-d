# golem-d
a flexible embeddable sub-scripting engine.
Designed to be pretty simple but extendable, useful for compiled languages that need some run-time evaluation.
Heavily Work-in-Progress.

```
:name test
:author TCM
:standard 1
-
//Above is metadata, which populates the parser class's variables pre-parsing.

#echo Each command is a line that starts with hashtag.
#echo Commands can also be run in-line, this will place the variable here; {get; name}.
#do(if:name==test) #echo commands can take arguments, like the if here, which is given to the function scope as a string table, useful for more complex processes.
```
