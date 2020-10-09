# golem-d
a flexible embeddable sub-scripting engine.
Designed to be pretty simple but extendable, useful for compiled languages that need some run-time evaluation.
Heavily Work-in-Progress.

```
//variables are defined with the format `key := value`
// adding #! to the start of commands tells the parser to only run the command once, in case where the script loops, this command will be ignored
#!name := test
#!author := TCM
#!standard := 1

// == macro format ==
// saves an array of commands to be run later, must contain a local variable for its name
fn begin
$(name:testmacro) 
echo, This is from the macro
echo, By the name of testmacro!?
^you forgot this
end

echo, Each command is a line that starts with command name, comma, then the line.
echo, Commands can also be run in-line, this will place the variable here; {get; name}.
do, $(if:name==test) echo, commands can take arguments, like the if here, which is given to the function scope as a string table, useful for more complex processes.


echo begin 
   can split commands across lines too, with the format of
   command_name begin
   then lines
   and ending with an end
end

//runs a macro, pre-defined set of commands
macro, testmacro

echo, The name is {get; name} {get;standard} by {get; author} {do|if:$name==basic; return, This is a basic string!}
do, $(if:$author==kaiser) echo, Hello!


// adds 1 to the done variable, giving another number after the variable name tells it how much to increment by, 1 is just the default.
increment, done

echo, Loop {get;done}!
// goto makes the parser re-start its line-by-line processing
// optional if statement only makes it run if the check is met
// this statement makes it restart the script 2 times, since done is incremented each run-through, and this only runs if done is 2 or lower
do, $(if:$done<=2) goto, 0

```
