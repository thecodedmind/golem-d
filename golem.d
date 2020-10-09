import libgolem;
import std.stdio, tcm.opthandler, std.algorithm, std.array, std.string;

class GolemCLI {
  void test(){writeln("This is a test from PROXY system.");}
}
void main(string[] argv){
  auto g = new Golem();
  auto o = new Opt(argv);
  g.external1 = new GolemCLI();
  //auto proxy
  g.setGlobal("cli", function string(Golem g, string s, string[string] locals){
	auto x = g.external1.get!(GolemCLI);
	x.test(); return s;
    });
  
  if(o.command() == ""){
    writeln("GOLEM COMMAND LINE ( CLI: 0.1 | libgolem: "~g.get("VERSION")~" )");
    writeln("Input sequence of commands, then send an empty line to process buffer.");
    writeln("End line with `.` to immediately send single line.");
    writeln("Interpreter commands start with `:`.");
    string prefix = "#";
    string[] lines;
    string line;
    while((line = readln()) !is null){
	line = line.replace("\n", "");
	if(line == ""){
	  writeln(lines);
	  g.processLineArray(lines);
	  g.setVar("LINE", "0");
	  while(lines.length > 0)
	    lines = lines.remove(0);
	}else{
	  //if(!line.startsWith("#") && !) line = "#"~line;
	  if(line.endsWith(".")){
	    line = line.stripRight(".");
	    g.processCmdLn(line);
	  }else{
	    lines ~= line;
	    writeln("BUFFER << "~line);
	  }
	}
    }
  }else{
    g.parseFile(o.command());
  }
}
