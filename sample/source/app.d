import std.experimental.logger;
import std.algorithm;
import std.range;
import std.array;
import mono;
import std.string;
import std.exception;
import std.typecons;
import std.conv:to;
import std.stdio;
import core.runtime : Runtime;
import std.experimental.all:wchar_t,uintptr_t,intptr_t;
import std.traits:ReturnType;


void main()
{
	commonMain();
	dogMain();
}

void commonMain()
{
	mono_config_parse(null);
	trace("parsed mono config");
}

void dogMain()
{
	auto ns = "";
	auto className = "Dog";
	auto domain = Domain("Dog.dll");
	trace("created domain");
	printNameSpaces(domain);
	printClassesFromAssembly(domain);
	domain.printMethodsOfClass("","Dog");

	auto Dog = CliClass(mono_class_from_name(domain.monoImage,ns.toStringz,className.toStringz));

	Dog.Type();
	auto dog = 	CliObject(mono_object_new(domain.handle,Dog.handle),&Dog);
	tracef("created a dog object");
	mono_runtime_object_init(dog.handle);
	tracef("initialised a dog object");
	dog.Bark();
	dog.Bark(4);
	auto result = dog.Squared(5);
	writefln("5*5 = %s", result.toString);
	auto resultAgain = dog.SquaredString(7);
	writefln("7*7 = %s", resultAgain.toString);
}




