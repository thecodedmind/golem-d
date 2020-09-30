module libgolem;
import std.stdio, std.array, std.algorithm, std.range, std.conv, std.string, tcm.strplus, std.regex, std.variant;
/*
@preprocessors
//Macros create a new function that can be caled like any other
@macro(name) {
#commands
}

#commands

 */

class GolemProxy{}

class Golem {
  string[] buffer;
  string[string] variables;
  string function(Golem g, string s, string[string] locals)[string] globals;
  int stage;
  void function(string s) output;
  void function(Golem g, string s) error;

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
    
    this.setVar("LINE", "0");
    this.setVar("VERSION", "0.1");
    
    this.setGlobal("echo", function string(Golem g, string s, string[string] locals){ g.output(s); return s; });
    this.setGlobal("do", function string(Golem g, string s, string[string] locals){ writeln(s); return ""; });
    this.setGlobal("set", function string(Golem g, string s, string[string] locals){
	  g.setVar(s.split(" ")[0], s.split(" ")[1]); return "";
	});
    this.setGlobal("get", function string(Golem g, string s, string[string] locals){return g.get(s);});  
    this.setGlobal("fn", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("goto", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("disable", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("int", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("return", function string(Golem g, string s, string[string] locals){ return s; });
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

  void processCmdLn(string ln){
    if(cmdLnInlines) ln = this.handleInlines(ln);
    string command_whole = ln.split(" ")[0];
    string command;
    string line = ln.replace(command_whole~" ", "");
    string args;
    string[string] locals;

    if(command_whole.contains("(")){
	args = command_whole.split("(")[1].replace(")", "");
	command = command_whole.split("(")[0].replace("#", "").replace("@", "");
	string[] l = args.split(",");
	foreach(t;l){
	  if(t.contains(":"))
	    locals[t.split(":")[0]] = t.split(":")[1];
	  else locals[t] = "true";
	}
    } else command = command_whole.replace("#", "").replace("@", "");

    if(command in this.globals) this.globals[command](this, line, locals); else this.error(this, "Invalid command: "~command_whole);
  }

  void processLines(string text, string prefix){
    stage++;
    string[] lines = text.split("\n");
    //writeln(lines);
    this.processLineArray(lines, prefix);
  }
  
  void processLineArray(string[] lines, string prefix){
    string b;
    string line;
    int lnum = to!int(this.variables.get("LINE", "0"));
    
    bool multiline = false;
    //Pre-processor
    foreach (l; lnum..lines.length){
	line = lines[l];

	if(multiline){
	  if(line == "}"){
	    this.processCmdLn(b);
	    multiline = false;
	  }else {
	    if(line.startsWith("//")) continue;
	    b ~= " "~line.strip();
	  }
	} else if(line.startsWith(prefix)){
	  if(line.endsWith("{")){
	    b = line.split(" ")[0];
	    multiline = true;
	  } else this.processCmdLn(line);
	}
    }
    lnum++;
    this.setVar("LINE", to!string(lnum));
  }

  string handleInlines(string text){
    auto re = regex(r"\{(.*?)\}");

    foreach (c; matchAll(text, re)){
	string full = c.hit.replace("{", "").replace("}", "");
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
	  text = text.replace("{"~full~"}", res);
	}  else this.error(this, "Invalid inline command: "~full);
	
    }

    //Regex extract all {inline}, find and run them, replace the code with what the function returns.
    return text;
  }
  void buildLabelIndex(string text){}
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
  void parseText(string text){
    stage = 0;
    this.buildLabelIndex(text);
    this.extractMetadata(text);
    this.setVar("LINE", "0");
    
    // pre-processor
    this.processLines(text, "@");
    
    this.setVar("LINE", "0");
    //standard commands
    if(!globalInlines) text = this.handleInlines(text);
    this.processLines(text, "#");
  }

  /// Read a file, send content to paser
  void parseFile(string pth){
    auto f = File(pth, "r");
    auto range = f.byLine();
    string txt;
    
    foreach (line; range)
	if (!line.empty) txt ~= line~"\n";
    this.parseText(txt);
  }
}
