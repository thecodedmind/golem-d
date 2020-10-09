module libgolem;
import std.stdio, std.array, std.uni, std.algorithm, std.range, std.conv, std.string, tcm.strplus, tcm.arrayplus, std.regex, std.variant;
//import core.stdc.stdio;
//import core.stdc.stdlib;
/*
variables
in line process, if its in format of
varname := value
then it is assigning a string to a variable
if value starts with # then its a command, assign return value as variable


multiline, see about handling newlines so the line breaks stay? maybe have || which replaces to break line later


find a way to treat custom macros as normal commands in the sake of execution, also some kinda handling of local variables too



find a way to add some variability to command formatting with names, for example
#sendtodiscord text here!
#send to discord text here
are the same

maybe make the check strip spaces from the line, then check startswith on all commands? then insert split after the command? but how to keep the stripped line different from the original line...
maybe change the logic to where the format is 
send to discord, line
as in, remove the hashtag requirement, command splits at first comma, if no commas then use whole line, and then strip spaces out of command

new golem format
regex the brackets out of the line, can be multiple, each one combines in to the lobals tabel
echo, $(tag:me,if:standard==1) this is a message $(label:debug)

 */



class Golem {
  string[] buffer;
  string[string] variables;
  string function(Golem g, string s, string[string] locals)[string] globals;
  int stage;
  void function(string s) output;
  void function(Golem g, string s) error;
  string[string] labelIndex;
  string[string] macros;
  string[] ignoreLines;
  Variant external1;
  Variant external2;
  Variant external3;
  Variant external4;
  Variant external5;
  string name = "Golem";
  bool cmdLnInlines = true;
  bool globalInlines = false;

  
  this(){
    this.stage = 0;
    this.output = function void(string s){writeln("GOLEM: "~s);};
    this.error = function void(Golem g, string s){writeln("ERROR ON LINE "~g.get("LINE")~": "~s);};
    
    this.setVar("LINE", "0"); this.setVar("VERSION", "0.1");
    
    this.setGlobal("echo", function string(Golem g, string s, string[string] locals){ g.output(s); return s; });
    this.setGlobal("once", function string(Golem g, string s, string[string] locals){
	  if(!g.ignoreLines.contains(s)){
	    g.ignoreLines ~= s;
	    g.processLines(s);
	  }
	  return "";
	});
    this.setGlobal("doallonce", function string(Golem g, string s, string[string] locals){
	  string[] send;
	  foreach(l; s.split("\n")){
	    if(!g.ignoreLines.contains(l)){
		g.ignoreLines ~= l;
		send ~= l;   
	    }
	  }

	  if(send.length > 0){
	    string lnum = g.get("LINE");
	    g.setVar("LINE", "0");
	    g.processLineArray(send, true);
	    g.setVar("LINE", lnum);
	  }
	  return "";
	});
    this.setGlobal("do", function string(Golem g, string s, string[string] locals){
	  string[string] vars = g.variables;
	  string getHandle(string g){
	    if(g.startsWith("$")){return vars.get(g.replace("$", ""), "");}
	    return g;
	  }
	  bool doit = false;
	  string f;
	  if("if" in locals){
	    string ch = locals["if"];
	    if(ch.contains("==") && getHandle(ch.split("==")[0]) == getHandle(ch.split("==")[1])) doit = true;
	    if( ch.contains("<=") && to!int(getHandle(ch.split("<=")[0])) <= to!int(getHandle(ch.split("<=")[1])) ) doit = true;
	    if( ch.contains("<<") && to!int(getHandle(ch.split("<<")[0])) < to!int(getHandle(ch.split("<<")[1])) ) doit = true;	    
	    if( ch.contains(">=") && to!int(getHandle(ch.split(">=")[0])) >= to!int(getHandle(ch.split(">=")[1])) ) doit = true;	   
	    if( ch.contains(">>") && to!int(getHandle(ch.split(">>")[0])) > to!int(getHandle(ch.split(">>")[1])) ) doit = true;
	  }
	  
	  if("ifand" in locals){
	    string[] ch = locals["ifand"].split("&&");
	    
	  }
	  if("ifor" in locals){
	    string[] ch = locals["ifand"].split("||");
	    
	  }
	  
	  if(doit){
	    if("while" in locals){

	    }else{
		f = g.processCmdLn(s);
	    }
	  }
	  

	  return f;
	});

    this.setGlobal("import", function string(Golem g, string s, string[string] locals){
	    string lnum = g.get("LINE");
	    g.setVar("LINE", "0");
	    g.parseFile(s);
	    g.setVar("LINE", lnum);


	  return "";
	});
    
    this.setGlobal("set", function string(Golem g, string s, string[string] locals){
	  g.setVar(s.split(" ")[0], s.split(" ")[1]); return "";
	});
    this.setGlobal("get", function string(Golem g, string s, string[string] locals){return g.get(s);});  
    this.setGlobal("get", function string(Golem g, string s, string[string] locals){return g.get(s);});
    
    this.setGlobal("goto", function string(Golem g, string s, string[string] locals){
	  if(s.isNumeric){ g.setVar("LINE", s); g.setVar("SUBROUTINE", "restart_processing");
	  }else{ if(s in g.labelIndex){ g.setVar("LINE", g.labelIndex[s]); g.setVar("SUBROUTINE", "restart_processing"); } }
	  return "";
	});  
    //this.setGlobal("download", function string(Golem g, string s, string[string] locals){
    // downloads a file
    // priorities of download location: supplied path in cmd >> env variable >> cwd
    //});
    //this.setGlobal("http", function string(Golem g, string s, string[string] locals){
    // should be used as inlines, returns text recieved from http
    //});
    //this.setGlobal("bash", function string(Golem g, string s, string[string] locals){
    // returns output from bash command
    //});
    //this.setGlobal("disable", function string(Golem g, string s, string[string] locals){
    // flags a label as disabled so goto ignores it });
    //this.setGlobal("int", function string(Golem g, string s, string[string] locals){ single entry point for all int mod commands });
    this.setGlobal("increment", function string(Golem g, string s, string[string] locals){
	  string[] vars = s.split(" ");
	  string varname = vars[0];
	  int mvby = 1;
	  if(vars.length > 1) mvby = to!int(vars[1]);
	  g.setVar(varname, to!string(to!int(g.get(varname))+mvby));
	  return to!string(g.get(varname));
	});
    this.setGlobal("decrement", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("multiply", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("divide", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    
    //this.setGlobal("choice", function string(Golem g, string s, string[string] locals){ returns random choice from list});
    //this.setGlobal("rng", function string(Golem g, string s, string[string] locals){ returns random number});
    this.setGlobal("return", function string(Golem g, string s, string[string] locals){
	  if(s.startsWith("#")) return g.processCmdLn(s);
	  return s;
	});

    this.setGlobal("defmacro", function string(Golem g, string s, string[string] locals){
	  string[] options = s.split("\n");
	  string name = locals["name"];
	  string[] macros;
	  
	  foreach(ln; options){
	    //if(ln.startsWith("!")) name = ln.stripLeft("!").strip();
	    //if(ln.startsWith("<<")) macros ~= ln.stripLeft("<<");
	    if(ln.startsWith("^")) macros[$-1] ~= ln.stripLeft("^");
	    else macros ~= ln;
	  }

	  if(name != "") g.macros[name] = macros.join("\n");

	  //writeln(g.macros);
	  return "";
	});
    this.setGlobal("macro", function string(Golem g, string s, string[string] locals){
	  string outp;
	  //writeln(s);
	  //writeln(g.macros);
	  if(s in g.macros){
	    auto m = g.macros[s].split("\n");
	    foreach(ln; m){
		//writeln(ln);
		string text = g.handleInlines(ln);
		outp ~= g.processCmdLn(text);
	    }
	    
	  }
	  return outp;
	});
    this.setGlobal("setvar", this.globals["set"]);
    this.setGlobal("getvar", this.globals["get"]);
    this.setGlobal("definemacro", this.globals["defmacro"]);
    this.setGlobal("fn", this.globals["defmacro"]);
    this.setGlobal("createmacro", this.globals["defmacro"]);
    this.setGlobal("runmacro", this.globals["macro"]);
    //writeln(this.globals);
  }

  void setVar(string key, string val){
    this.variables[key] = val;
  }
  string get(string key, string def = ""){
    return this.variables.get(key, def);
  }
  void setGlobal(string key, string function(Golem g, string s, string[string] locals) fn){
    this.globals[key] = fn;
  }

  string processCmdLn(string cln){
    string ln = cln.dup;
    if(ln.strip() == "") return "";
    //writeln(this.variables);
    if(cmdLnInlines) ln = this.handleInlines(cln.dup);
    string command = ln.split(",")[0].strip();
    //string command;
    //writeln("Original "~command);
    string line = ln.replace(command~",", "").strip();

    while(command.contains(" ")) command = command.replace(" ", "");
    command = command.toLower();
    //writeln("Altered "~command);
    string args;
    string[string] locals;
    auto re = regex(r"\$\((.*?)\)");

    foreach (c; matchAll(line, re)){
	line = line.replace(c.hit, "");
	string[] tmp = c.hit.stripLeft("$(").stripRight(")").split(",");
	foreach (v; tmp ){
	  if(v.contains(":"))
	    locals[v.split(":")[0]] = v.split(":")[1];
	  else locals[v] = "true";	    
	}
    }
    /*if(command_whole.contains("(")){
	//args = this.handleInlines(line.dup);
	command = command_whole.split("(")[0].stripLeft("#").stripLeft("@");
	string[] l = args.split(",");
	foreach(t;l){
	  if(t.contains(":"))
	    locals[t.split(":")[0]] = t.split(":")[1];
	  else locals[t] = "true";
	}
    } else command = command_whole.stripLeft("#").stripLeft("@");
    */
    
    if(command in this.globals)
	return this.globals[command](this, line, locals);
    
    this.error(this, "Invalid command: "~command);
    return "Invalid command: "~command;
  }

  string processLines(string text, bool overrideIgnores = false){
    stage++;
    string[] lines = text.split("\n");
    //writeln(lines);
    return this.processLineArray(lines, overrideIgnores);
  }
  
  string processLineArray(string[] lines, bool overrideIgnores = false){
    string b;
    string line;
    string outp;
    int lnum = to!int(this.variables.get("LINE", "0"));
    int lnumt = to!int(this.variables.get("LINE", "0"));
    //writeln("recv "~lines);
    bool multiline = false;
    bool allowIgnored;
    foreach (l; lnumt..lines.length){
	allowIgnored = false;
	line = lines[l].strip();
	//writeln(line);
	if(line.startsWith("//")) continue;
	if(line.contains("//")) line = line.split("//")[0];
	if(line.strip() == "" || line == "\n") continue;
	if(line.startsWith("#!")){
	  line = line.replace("#!", "").stripLeft();
	  if(!this.ignoreLines.contains(line)){
	    this.ignoreLines ~= line;
	    allowIgnored = true;
	  }

	} else allowIgnored = overrideIgnores;
	//writeln(allowIgnored);
	if(this.ignoreLines.contains(line) && !allowIgnored) continue;
	if(matchFirst(line, r"([A-Za-z])+(\s?):=(\s?)([A-Za-z\d\s])+\;")){
	  //writeln("Line matched as variable "~line);
	  this.variables[line.split(":=")[0].strip()] = line.split(":=")[1].strip().stripRight(";");
	  continue;
	}
	  
	if(multiline){
	  if(line == "end"){
	    outp ~= this.processCmdLn(b);
	    multiline = false;
	    //writeln(b);
	  }else {
	    //writeln("Multilining "~line);
	    if(line.startsWith("^")){
		b ~= " "~line.stripLeft("^");
		//writeln(b);
	    }else
	    b ~= "\n"~line;//.strip();
	  }
	} else {
	  if(line.endsWith(" begin")){
	    //b = line.split(" ")[0]~", ";
	    //writeln("Begining: "~line);
	    b = line.stripRight("begin");//.strip();
	    while(b.contains(" ")) b = b.replace(" ", "");
	    b = b~", ";
	    multiline = true;
	  } else outp ~= this.processCmdLn(line);
	}
	
	if(this.get("SUBROUTINE") == "restart_processing"){
	  this.setVar("SUBROUTINE", "");
	  this.processLineArray(lines);
	  break;
	} else {
	  lnum++;
	  this.setVar("LINE", to!string(lnum));
	}
    }

    return outp;
  }

  string handleInlines(string b){
    string text = b.dup;
    auto re = regex(r"\$\{(.*?)\}");

    foreach (c; matchAll(text, re)){
	string full = c.hit.stripLeft("${").stripRight("}");
	string command;
	string[string] locals;
	string line;
	
	if(full.contains(";")){
	  command = full.split(";")[0];
	  line = full.split(";")[1].strip();
	} else { command = full; }
	
	if(command.contains("|")){
	  string[] ltmp = command.split("|")[1].split(",");
	  command = command.split("|")[0];
	  
	  foreach(cl; ltmp){
	    locals[cl.split(":")[0]] = cl.split(":")[1];
	  }
	}
	if(command in this.globals) {
	  string res = this.globals[command](this, line, locals);
	  text = text.replace("${"~full~"}", res);
	}  else this.error(this, "Invalid inline command: "~full);
	
    }

    return text;
  }
  void buildLabelIndex(string text){
    string[] lines = text.split("\n");
    int linenum;
    foreach (line; lines){
	if(line.startsWith("<-") && line.endsWith(":")){
	  string lbl = line.replace("<-", "").replace(":", "");
	  this.labelIndex[lbl] = to!string(linenum);
	}
	linenum++;
    }
    writeln(this.labelIndex);
  }
  void extractMetadata(string text){
    string[] lines = text.split("\n");
    foreach(line; lines){
	if(line.startsWith(":")){
	  string key = line.split(" ")[0].replace(":", "");
	  string ln = line.replace(":"~key~" ", "");
	  this.setVar(key, ln);
	}
	if(line == "-") break;
    }
    
  }
  void gotoLn(string linenum){this.setVar("LINE", linenum);}
  void gotoLn(int linenum){this.gotoLn(to!string(linenum));}
  /// Entry point to parse a body of text
  string parseText(string text){
    stage = 0;
    //this.buildLabelIndex(text);
    //this.extractMetadata(text);
    this.setVar("LINE", "0");
    
    // pre-processor
    //this.processLines(text);
    
    //this.setVar("LINE", "0");
    //standard commands
    if(globalInlines) text = this.handleInlines(text);
    return this.processLines(text);
  }

  string parseFile(string pth){
    auto f = File(pth, "r");
    auto range = f.byLine();
    string txt;
    
    foreach (line; range)
	if (!line.empty) txt ~= line~"\n";
    return this.parseText(txt);
  }
}
