module libgolem;
import std.stdio, std.array, std.algorithm, std.range, std.conv, std.string, tcm.strplus, std.regex, std.variant;
/*
@preprocessors
//Macros create a new function that can be caled like any other
@macro(name) {
#commands
}

#commands

add some syntactic sugar of not needing space between command and line if command is one character
 */

class GolemProxy{}

class Golem {
  string[] buffer;
  string[string] variables;
  string function(Golem g, string s, string[string] locals)[string] globals;
  int stage;
  void function(string s) output;
  void function(Golem g, string s) error;
  string[string] labelIndex;
  string[string] macros;
  
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

	    if( ch.contains("<") && to!int(getHandle(ch.split("<")[0])) < to!int(getHandle(ch.split("<")[1])) ) doit = true;
	    
	    if( ch.contains(">=") && to!int(getHandle(ch.split(">=")[0])) >= to!int(getHandle(ch.split(">=")[1])) ) doit = true;
	    
	    if( ch.contains(">") && to!int(getHandle(ch.split(">")[0])) > to!int(getHandle(ch.split(">")[1])) ) doit = true;
	    

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
    
    this.setGlobal("set", function string(Golem g, string s, string[string] locals){
	  g.setVar(s.split(" ")[0], s.split(" ")[1]); return "";
	});
    this.setGlobal("get", function string(Golem g, string s, string[string] locals){return g.get(s);});  
    
    //this.setGlobal("goto", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    //this.setGlobal("disable", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    //this.setGlobal("int", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("increment", function string(Golem g, string s, string[string] locals){
	  string[] vars = s.split(" ");
	  string varname = vars[0];
	  int mvby = 1;
	  if(vars.length > 1) mvby = to!int(vars[1]);
	  g.setVar(varname, to!string(to!int(g.get(varname))+mvby));
	  return s;
	});
    this.setGlobal("decrement", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("multiply", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("divide", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    
    //this.setGlobal("choice", function string(Golem g, string s, string[string] locals){ writeln(s); return s; });
    this.setGlobal("return", function string(Golem g, string s, string[string] locals){
	  if(s.startsWith("#")) return g.processCmdLn(s);
	  return s;
	});

    this.setGlobal("defmacro", function string(Golem g, string s, string[string] locals){
	  string[] options = s.split("|");
	  string name;
	  string[] macros;
	  
	  foreach(ln; options){
	    if(ln.startsWith("!")) name = ln.stripLeft("!").strip();
	    if(ln.startsWith("<<")) macros ~= ln.stripLeft("<<");
	    if(ln.startsWith("^")) macros[$-1] ~= ln.stripLeft("^");
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
    this.setGlobal("!", this.globals["set"]);
    this.setGlobal("?", this.globals["get"]);
    this.setGlobal("=", this.globals["return"]);
    this.setGlobal("fn", this.globals["defmacro"]);
    this.setGlobal(":", this.globals["macro"]);
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
    if(cmdLnInlines) ln = this.handleInlines(cln.dup);
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

    if(command in this.globals)
	return this.globals[command](this, line, locals);
    
    this.error(this, "Invalid command: "~command_whole);
    return "Invalid command: "~command_whole;
  }

  string processLines(string text, string prefix){
    stage++;
    string[] lines = text.split("\n");
    //writeln(lines);
    return this.processLineArray(lines, prefix);
  }
  
  string processLineArray(string[] lines, string prefix){
    string b;
    string line;
    string outp;
    int lnum = to!int(this.variables.get("LINE", "0"));
    int lnumt = to!int(this.variables.get("LINE", "0"));
    //writeln("Starting line "~to!string(lnum));
    bool multiline = false;
    //Pre-processor
    foreach (l; lnumt..lines.length){
	line = lines[l];
	//writeln(to!string(l)~": "~line);
	if(multiline){
	  if(line == "}"){
	    outp ~= this.processCmdLn(b);
	    multiline = false;
	  }else {
	    if(line.startsWith("//")) continue;
	    b ~= " "~line.strip();
	  }
	} else if(line.startsWith(prefix)){
	  if(line.endsWith("{")){
	    b = line.split(" ")[0];
	    multiline = true;
	  } else outp ~= this.processCmdLn(line);
	} else if(line.startsWith("goto") && prefix == "#"){
	  string[] opts = line.split(" ");
	  auto vars = this.variables;
	  
	  bool doit = true;
	  int newln = to!int(opts[1]);
	  
	  if(opts.length > 2 && opts[2] == "if"){
	    string getHandle(string g){
		if(g.startsWith("$")){return vars.get(g.replace("$", ""), "");}
		return g;
	    }
	    string ch = opts[3];
	    doit = false;
	    if( ch.contains("==") && getHandle(ch.split("==")[0]) == getHandle(ch.split("==")[1])) doit = true;
	    if( ch.contains("<=") && to!int(getHandle(ch.split("<=")[0])) <= to!int(getHandle(ch.split("<=")[1])) ) doit = true;
	    if( ch.contains("<<") && to!int(getHandle(ch.split("<<")[0])) < to!int(getHandle(ch.split("<<")[1])) ) doit = true;	    
	    if( ch.contains(">=") && to!int(getHandle(ch.split(">=")[0])) >= to!int(getHandle(ch.split(">=")[1])) ) doit = true;	   
	    if( ch.contains(">>") && to!int(getHandle(ch.split(">>")[0])) > to!int(getHandle(ch.split(">>")[1])) ) doit = true;	    
	  }

	  if(doit){
	    this.setVar("LINE", to!string(newln));
	    this.processLineArray(lines, prefix);
	    break;
	  }
	}
	lnum++;
	this.setVar("LINE", to!string(lnum));
    }

    return outp;
  }

  string handleInlines(string b){
    string text = b.dup;
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

    return text;
  }
  void buildLabelIndex(string text){
    string[] lines = text.split("\n");
    int linenum;
    foreach (line; lines){
	if(line.startsWith("[") && line.endsWith("]:")){
	  string lbl = line.replace("[", "").replace("]:", "");
	  this.labelIndex[lbl] = to!string(linenum);
	}
	linenum++;
    }
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
    this.buildLabelIndex(text);
    this.extractMetadata(text);
    this.setVar("LINE", "0");
    
    // pre-processor
    this.processLines(text, "@");
    
    this.setVar("LINE", "0");
    //standard commands
    if(globalInlines) text = this.handleInlines(text);
    return this.processLines(text, "#");
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
