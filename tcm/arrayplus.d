module tcm.arrayplus;
import std.stdio, std.algorithm, std.array;

bool contains(string[] s, string needle){
  foreach (a; s) {if(a == needle)return true;}
  return false;
}
