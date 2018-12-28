MonoClass*[string] classHandles;
string[MonoClass*] classNames;
MonoMethod*[string][string] methodHandles;
	
	void createObject(string className,string nameSpace)
	{
		MonoError exc;
		tracef("createObject %s",className);
		auto classHandle = findClass(className,nameSpace);
		tracef("found class %s",className);
		mono_object_new(this.handle,classHandle);
		tracef("newed %s",className);
	}


	void createClass(string className, string nameSpace = nameSpace)
	{
		auto p =  className in classHandles;
		MonoClass* classHandle = (p is null) ? null :*p;
		enforce(classHandle is null);
		auto c = findClassFromName(monoImage,nameSpace,className);
		classHandles[className] = c;
		classNames[c] = className;
		createObject(className,nameSpace);
	}

	MonoClass* findClass(string className, string nameSpace = nameSpace)
	{
		auto p =  className in classHandles;
		MonoClass* classHandle = (p is null) ? null :*p;
		if (classHandle is null)
		{
			MonoError error;
			classHandle = monoImage.findClassFromName(nameSpace,className);
			classHandles[className] = classHandle;
			classNames[classHandle] = className;
		}
		enforce(classHandle !is null);
		return classHandle;
	}

	string getClassName(MonoClass* classHandle)
	{
		auto ret = classHandle in classNames;
		enforce(ret !is null);
		return *ret;
	}

	MonoMethod* findStaticMethodRaw(string className, string nameSpace,string rawMethodName)
	{
		auto classHandle = findClass(className,nameSpace);
		return findMethodRaw(classHandle,rawMethodName);
	}

	MonoMethod* findMethodRaw(MonoClass* classHandle, string rawMethodName)
	{
		MonoMethod* methodHandle;
		auto className = getClassName(classHandle);
		auto classMethods = methodHandles.get(className,null);

		if (classMethods is null)
		{
			// first method on class so we need to create class table
			methodHandle = findMethodRaw(classHandle,rawMethodName);
			MonoMethod*[string] newClassMethodTable;
			newClassMethodTable[rawMethodName] = methodHandle;
			methodHandles[className] = newClassMethodTable;
			return methodHandle;
		}

		methodHandle = classMethods.get(rawMethodName,null);
		if (methodHandle !is null)
		{
			return methodHandle;
		}
		methodHandle = findMethodRaw(classHandle,rawMethodName);
		enforce (methodHandle !is null);
		classMethods[rawMethodName] = methodHandle;
		return methodHandle;
	}

	MonoObject* construct(T...)(string className,string nameSpace,string argsString, T args)
	{
		return callStaticMethod!T(className,nameSpace,"ctor",argsString,args);
	}

	MonoObject* callMethod(T...)(MonoObject* obj,string methodName,T args)
	{
		MonoObject* exc;
		auto methodHandle = findMethodRaw(obj.getClass,methodName);
		MonoObject* result = mono_runtime_invoke(methodHandle,obj,args.mapArgs,&exc);
		return result;
	}

	MonoObject* callStaticMethod(T...)(string className,string nameSpace, string methodName,string argsString, T args)
	{
		MonoObject* exc;
		createObject(className,nameSpace);
		auto methodHandle = findMethod(className,nameSpace,methodName);
		MonoObject* result = mono_runtime_invoke(methodHandle,obj,args.mapArgs,&exc);
		return result;
	}

	MonoObject* callStaticMethod(T...)(MonoMethod* method, T args)
	{
		MonoObject* exc;
		enforce(method !is null);
		createObject(className,nameSpace);
		MonoObject* result = mono_runtime_invoke(methodHandle,obj,args.mapArgs,&exc);
		return result;
	}
