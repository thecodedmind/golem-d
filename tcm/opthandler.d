module tcm.opthandler;
import std.stdio, std.algorithm, std.array, std.string;
import tcm.strplus, tcm.arrayplus;

class Opt {
  string application;
  string[] args;
  string[string] properties;
  string[] flags;
  string[] commands;
  
  this(string[] arga) {
    this.args = arga;
    this.application = this.args[0];
    int i = 0;
    foreach (a; arga) {
	if(i > 0){
	  if(a.startsWith("-")){
	    if(a.contains("=")) this.properties[a.split("=")[0].tr("-", "", "d")] = a.split("=")[1];
	    else if(a.contains(":")) this.properties[a.split(":")[0].tr("-", "", "d")] = a.split(":")[1];
	    else this.flags ~= a.tr("-", "", "d");
	  }else this.commands ~= a;
	}
	i++;
    } 
  }

  string command(int index = 0) {
    if(index >= this.commands.length) return "";
    return this.commands[index];
  }
  
  string value(string key, string def = "") {
    return this.properties.get(key, def);
  }
  
  bool flag(string key) {
    return this.flags.contains(key);
  }
}
