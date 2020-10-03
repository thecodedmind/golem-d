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


#echo {
	but what about
	MULTILINES?
  This joins all the lines in to one command
}

//runs a macro, pre-defined set of commands
#macro testmacro

#echo The name is {get; name} {get;standard} by {get; author} {do|if:$name==basic; #return This is a basic string!}
#do(if:$author==kaiser) #echo Hello!


// == macro format ==
// line starting with |! in the body defines its name, if no name given, macro wont be added
// lines starting with |<< insert the following line as a command that runs
@fn {
|!testmacro  
|<<#echo This is from the macro
|<<#echo By the name of testmacro!?
|^this line appends to the previous
}

// adds 1 to the done variable, giving another number after the variable name tells it how much to increment by, 1 is just the default.
#increment done

#echo Loop {get;done}!
// goto is a special parser handle, which makes the parser re-start its line-by-line processing
// optional if statement only makes it run if the check is met
// this statement makes it restart the script 5 times, since done is incremented each run-through, and this only runs if done is 5 or lower
goto 0 if $done<=5

```
