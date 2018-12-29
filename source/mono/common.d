module mono.common;
import core.runtime : Runtime;
import std.algorithm;
import std.array;
import std.conv:to;
import std.exception;
import std.experimental.all:wchar_t,uintptr_t,intptr_t;
import std.experimental.logger;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.meta:AliasSeq;

import derelict.mono;
import mono.exceptions;
import mono.gc;

// 		mono_jit_exec(handle, assembly, 0,null);

T* safeReturn(T)(T* ptr)
{
	import std.exception;
    enforce(ptr !is null);
    return ptr;
}


string toString(MonoObject* obj)
{
	enforce(obj !is null);
	MonoObject* exc;
	auto monoString = mono_object_to_string(obj,&exc);
	return monoString.toString;
}

string toString(MonoString* s)
{
	enforce(s !is null);
	return mono_string_to_utf8(s).fromStringz.idup;
}

MonoImage* openImage(string filename)
{
	MonoImageOpenStatus status;
	MonoImage* ret = mono_image_open(filename.toStringz,&status);
	enforce(ret !is null);
	return ret;
}

MonoMethodDesc* createMethodDescription(string description)
{
	return mono_method_desc_new(description.toStringz,false);
}

MonoMethod* findMethodRaw(MonoClass* monoClass, MonoMethodDesc* desc)
{
	return mono_method_desc_search_in_class(desc,monoClass);
}

MonoMethod* findMethodRaw(MonoClass* monoClass, string description)
{
	MonoMethodDesc* desc = description.createMethodDescription;
	MonoMethod* ret = findMethodRaw(monoClass,desc);
	mono_method_desc_free(desc);
	return ret;
}


MonoClass* findClassFromName(MonoImage* monoImage, string nameSpace, string className)
{
	tracef("find classFromName for %s/%s",nameSpace,className);
	auto ret = mono_class_from_name(monoImage,nameSpace.toStringz,className.toStringz);
	tracef("returning %s",ret);
	return ret;
}

char** toStringArray(string[] args)
{
	auto dupArgs = args.map!(arg=>arg.dup);
	char*[] ret = dupArgs.map!(arg => arg.ptr).array;
	return ret.ptr;
}

struct Domain
{
	MonoDomain* handle;
	MonoImage* monoImage;
	MonoAssembly* assembly;

	this(string filename)
	{
		this.handle = mono_jit_init(filename.toStringz);
		enforce(this.handle !is null);
		this.assembly = openAssembly(filename);
		this.monoImage = mono_assembly_get_image(this.assembly); //openImage(filename);
		enforce(this.monoImage !is null);
		//create_object (handle, this.monoImage);
	}

	~this()
	{
		mono_jit_cleanup(this.handle);
	}

	int jitExec(string filename, string[] args)
	{
		auto argv = args.toStringArray();
		return mono_jit_exec(this.handle,openAssembly(filename),cast(int)args.length,argv);
	}

	MonoClass*[] getAssemblyClassList()
	{
		return getAssemblyClassListFromImage(this.monoImage);
	}
	MonoString* toMonoString(string s)
	{
		auto ret = mono_string_new(this.handle, s.toStringz);
		enforce(ret !is null);
		return ret;
	}

	MonoAssembly* openAssembly(string filename)
	{
		MonoAssembly* assembly = mono_domain_assembly_open(this.handle,filename.toStringz);
		enforce(assembly !is null,format!"Assembly %s could not be opened"(filename));
		return assembly;
	}


	MonoObject* simpleInvoke(T...)(string nameSpace, MonoObject* obj, string methodName,T args)
	{
		MonoObject* exc;
		tracef("simpleInvoke called with %s/%s",nameSpace,methodName);
		//auto classHandle = mono_class_from_name(monoImage,nameSpace.toStringz,className.toStringz);
		auto classHandle = obj.getClass();
		tracef("classHandle %s",classHandle);
		enforce(classHandle !is null);
		MonoMethodDesc* desc = mono_method_desc_new(methodName.toStringz,false);
		tracef("desc %s",desc);
		enforce(desc !is null);
		MonoMethod* methodHandle = mono_method_desc_search_in_class(desc,classHandle);
		tracef("method %s",methodHandle);
		mono_method_desc_free(desc);
		tracef("freed desc");
		tracef("methodHandle is %s",methodHandle);
		enforce(methodHandle !is null);

		void*[] argsPtr;
		argsPtr.length = args.length;
		foreach(i,ref arg;args)
			argsPtr[i] = &arg;

		MonoObject* result = mono_runtime_invoke(methodHandle,obj,cast(void**) argsPtr.ptr,&exc);
		//MonoObject* result = mono_runtime_invoke(methodHandle,obj,args.mapArgs,&exc);
		enforce(result !is null, exc.toString());
		return result;
	}

	MonoObject* simpleInvokeStatic(T...)(string nameSpace, string className, string methodName,T args)
	{
		MonoObject* exc;
		tracef("simpleInvoke called with %s/%s",nameSpace,methodName);
		auto classHandle = mono_class_from_name(monoImage,nameSpace.toStringz,className.toStringz);
		tracef("classHandle %s",classHandle);
		enforce(classHandle !is null);
		MonoMethodDesc* desc = mono_method_desc_new(methodName.toStringz,false);
		tracef("desc %s",desc);
		enforce(desc !is null);
		MonoMethod* methodHandle = mono_method_desc_search_in_class(desc,classHandle);
		tracef("method %s",methodHandle);
		mono_method_desc_free(desc);
		tracef("freed desc");
		tracef("methodHandle is %s",methodHandle);
		enforce(methodHandle !is null);

		void*[] argsPtr;
		argsPtr.length = args.length;
		foreach(i,ref arg;args)
			argsPtr[i] = &arg;

		MonoObject* result = mono_runtime_invoke(methodHandle,null,cast(void**) argsPtr.ptr,&exc);
		//MonoObject* result = mono_runtime_invoke(methodHandle,obj,args.mapArgs,&exc);
		enforce(result !is null, exc.toString());
		return result;
	}

	T toDelegate(T)(string nameSpace, string className, string methodName)
	{
		tracef("toDelegate called with %s/%s/%s",nameSpace,className,methodName);
		auto classHandle = mono_class_from_name(monoImage,nameSpace.toStringz,className.toStringz);
		tracef("classHandle %s",classHandle);
		enforce(classHandle !is null);
		MonoMethodDesc* desc = mono_method_desc_new(methodName.toStringz,false);
		tracef("desc %s",desc);
		enforce(desc !is null);
		MonoMethod* methodHandle = mono_method_desc_search_in_class(desc,classHandle);
		tracef("method %s",methodHandle);
		mono_method_desc_free(desc);
		tracef("freed desc");
		tracef("methodHandle is %s",methodHandle);
		enforce(methodHandle !is null);
		auto ret = cast(T) mono_method_get_unmanaged_thunk(methodHandle);
		enforce(ret !is null);
		tracef("delegate is %s",ret);
		return ret;
	}

	string[] getMethodsString(string nameSpace, string className)
	{
		tracef("getMethods called with %s/%s",nameSpace,className);
		auto classHandle = mono_class_from_name(monoImage,nameSpace.toStringz,className.toStringz);
		tracef("classHandle %s",classHandle);
		enforce(classHandle !is null);
		return classHandle.getMethods.map!(m => m.getName()).array;		
	}

	MonoMethod*[] getMethods(string nameSpace, string className)
	{
		tracef("getMethods called with %s/%s",nameSpace,className);
		auto classHandle = mono_class_from_name(monoImage,nameSpace.toStringz,className.toStringz);
		tracef("classHandle %s",classHandle);
		enforce(classHandle !is null);
		return classHandle.getMethods;
	}
}




auto toDelegate(T)(MonoMethod* method)
{
	return cast(T) mono_method_get_unmanaged_thunk(method);
}

void** mapArgs(T...)(T args)
{
	void*[] ret;
	ret.length = args.length;
	alias U = Tuple!(T);
	auto values = new U(args);
	ret.length = args.length;
	static foreach(i,arg;args)
	{
		ret[i] = &values[i];
	}
	return ret.ptr;
}


void createObject(MonoDomain* domain, MonoClass* classHandle)
{
	mono_object_new(domain,classHandle);
}

alias CBool = bool;

extern(C)
{
    char* mono_string_to_utf8 (MonoString *s);
}

version(None)
extern(C)
{
    MonoString* mono_string_new (MonoDomain *domain, const char *text);
    MonoString* mono_string_new_len (MonoDomain *domain, const char *text, uint length);
    MonoString* mono_string_new_size (MonoDomain *domain, int len);
    MonoString* mono_string_new_utf16 (MonoDomain *domain, const ushort *text, int len);
    MonoString* mono_string_new_utf32 (MonoDomain *domain, const mono_unichar4 *text, int len);
    MonoString* mono_string_from_utf16 (wchar_t *data);
    MonoString* mono_string_from_utf32 (mono_unichar4 *data);
    mono_unichar2* mono_string_to_utf16 (MonoString *s);
    char* mono_string_to_utf8_checked (MonoString *s, MonoError *error);
    mono_unichar4* mono_string_to_utf32 (MonoString *s);
    CBool mono_string_equal (MonoString *s1, MonoString *s2);
    uint mono_string_hash (MonoString *s);
    MonoString* mono_string_intern (MonoString *str);
    MonoString* mono_string_is_interned (MonoString *o);
    MonoString* mono_string_new_wrapper (const char *text);
    wchar_t* mono_string_chars (MonoString *s);
    int mono_string_length (MonoString *s);


    MonoObject* mono_object_new(MonoDomain *domain, MonoClass *klass);
    MonoObject* mono_object_new_alloc_specific (MonoVTable *vtable);
    MonoObject* mono_object_new_fast (MonoVTable *vtable);
    MonoObject* mono_object_new_from_token (MonoDomain *domain, MonoImage *image, uint token);
    MonoObject* mono_object_new_specific (MonoVTable *vtable);
    MonoObject* mono_object_clone (MonoObject *obj);
    MonoClass* mono_object_get_class (MonoObject *obj);
    MonoDomain* mono_object_get_domain (MonoObject *obj);
    MonoMethod* mono_object_get_virtual_method (MonoObject *obj, MonoMethod *method);
    MonoObject* mono_object_isinst (MonoObject *obj, MonoClass *klass);
    void* mono_object_unbox (MonoObject *obj);
    MonoObject* mono_object_castclass_mbyref (MonoObject *obj, MonoClass *klass); uint mono_object_get_size (MonoObject* o);
    MonoString* mono_object_to_string(MonoObject *obj, MonoObject **exc);
    MonoObject* mono_value_box (MonoDomain *domain, MonoClass *klass, void* value);
    void mono_value_copy (void* dest, void* src, MonoClass *klass);
    void mono_value_copy_array (MonoArray *dest, int dest_idx, void* src, int count);
    MonoArray* mono_array_new (MonoDomain *domain, MonoClass *eclass, uintptr_t n);
    MonoArray* mono_array_new_full (MonoDomain *domain, MonoClass *array_class, uintptr_t *lengths, intptr_t *lower_bounds);
    MonoArray* mono_array_new_specific (MonoVTable *vtable, uintptr_t n);
    MonoClass* mono_array_class_get (MonoClass *eclass, uint rank);
    MonoArray* mono_array_clone (MonoArray *array);
    uintptr_t mono_array_length (MonoArray *array);
     char* mono_array_addr_with_size (MonoArray *array, int size, uintptr_t idx);
    int mono_array_element_size (MonoClass *ac);
    const(char)* mono_field_get_name (MonoClassField *field);
    MonoClass* mono_field_get_parent (MonoClassField *field);
    MonoType* mono_field_get_type (MonoClassField *field);
    void mono_field_get_value (MonoObject *obj, MonoClassField *field, void *value);
    MonoObject* mono_field_get_value_object (MonoDomain *domain, MonoClassField *field, MonoObject *obj);
    void mono_field_set_value (MonoObject *obj, MonoClassField *field, void *value);
    void mono_field_static_get_value (MonoVTable *vt, MonoClassField *field, void *value);
    void mono_field_static_set_value (MonoVTable *vt, MonoClassField *field, void *value);
    MonoReflectionProperty* mono_property_get_object_checked (MonoDomain *domain, MonoClass *klass, MonoProperty *property, MonoError *error);
    uint mono_property_get_flags (MonoProperty *prop);
    MonoMethod* mono_property_get_get_method (MonoProperty *prop);
  MonoClass* mono_property_get_parent (MonoProperty *prop);
    MonoMethod* mono_property_get_set_method (MonoProperty *prop);
    MonoObject* mono_property_get_value (MonoProperty *prop, void *obj, void **params, MonoObject **exc);
    void mono_property_set_value (MonoProperty *prop, void *obj, void **params, MonoObject **exc);
    MonoMethod* mono_event_get_add_method (MonoEvent *event);
    uint mono_event_get_flags (MonoEvent *event);
    const(char)* mono_event_get_name (MonoEvent *event);
    MonoClass* mono_event_get_parent (MonoEvent *event);
    MonoMethod* mono_event_get_raise_method (MonoEvent *event);
    MonoMethod* mono_event_get_remove_method (MonoEvent *event);
    void* mono_load_remote_field (MonoObject *this_obj, MonoClass *klass, MonoClassField *field, void* *res);
    MonoObject* mono_load_remote_field_new (MonoObject *this_obj, MonoClass *klass, MonoClassField *field);
    void mono_store_remote_field (MonoObject *this_obj, MonoClass *klass, MonoClassField *field, void* val);
    void mono_store_remote_field_new (MonoObject *this_obj, MonoClass *klass, MonoClassField *field, MonoObject *arg);
    MonoMethod* mono_get_delegate_begin_invoke (MonoClass *klass);
    MonoMethod* mono_get_delegate_end_invoke (MonoClass *klass);
}

//mono_object_isinst_mbyref 
//mono_field_get_object
//  mono_property_get_name 
//mono_object_hash 
//mono_array_get 
//mono_array_get 
//mono_array_setref mono_array_addr
//    mono_field_from_token mono_field_get_flags


MonoClass*[] getAssemblyClassListFromImage(MonoImage* image)
{
	Appender!(MonoClass*[]) ret;
	enforce(image !is null);
	const MonoTableInfo* tableInfo = mono_image_get_table_info(image,MONO_TABLE_TYPEDEF);
	enforce(tableInfo !is null);
	foreach(int i;0 .. cast(int) tableInfo.length)
	{
       MonoClass* class_;
       uint[MONO_TYPEDEF_SIZE] cols;
       mono_metadata_decode_row(tableInfo, i, cols.ptr, MONO_TYPEDEF_SIZE);
       const(char)* name = mono_metadata_string_heap(image, cols[MONO_TYPEDEF_NAME]);
       const(char)* name_space = mono_metadata_string_heap(image, cols[MONO_TYPEDEF_NAMESPACE]);
       class_ = mono_class_from_name(image, name_space, name);
	   if(class_ is null)
	   {
	   		writeln("cannot get class for %s/%s",name_space.fromStringz,name.fromStringz);
	   }
	   else
	   {
	       ret.put(class_);
	   }
   }
   return ret.data;
}
 
size_t length(const(MonoTableInfo)* tableInfo)
{
	enforce(tableInfo !is null);
	return cast(size_t) mono_table_info_get_rows(tableInfo);
}

string getNameSpace(MonoClass* class_)
{
	enforce(class_ !is null);
	auto ret = mono_class_get_namespace(class_);
	enforce(ret !is null);
	return ret.fromStringz.idup;
}

string getName(MonoClass* class_)
{
	enforce(class_ !is null);
	auto ret = mono_class_get_name(class_);
	enforce(ret !is null);
	return ret.fromStringz.idup;
}

MonoMethod*[] getMethods(MonoObject* obj)
{
	enforce(obj !is null);
	return obj.getClass().getMethods();
}


MonoMethod*[] getMethods(MonoClass* class_)
{
	void* iter;
	MonoMethod* m;
	Appender!(MonoMethod*[]) ret;
	while((m = mono_class_get_methods(class_,&iter))!is null)
	{
		ret.put(m);
	}
	return ret.data;
}

string getName(MonoMethod* method)
{
	enforce(method !is null);
	auto ret = mono_method_get_name(method);
	enforce(ret !is null);
	return ret.fromStringz.idup;
}

MonoDomain* getDomain(MonoObject* obj)
{
	auto domain = mono_object_get_domain (obj);
	enforce(domain !is null);
	return domain;
}
/+
MonoClass* getClass(MonoObject* obj)
{
	auto ret = mono_object_get_class (obj);
	enforce(ret !is null);
	return ret;
}
+/

MonoMethodSignature* getSignature(MonoMethod* method)
{
	enforce(method !is null);
	auto ret = mono_method_signature(method);
	enforce(ret !is null);
	return ret;
}

size_t length(MonoMethodSignature* sig)
{
	enforce(sig !is null);
	return cast(size_t)mono_signature_get_param_count(sig);
}

MonoType* getReturnType(MonoMethod* method)
{
	enforce(method !is null);
	auto sig = getSignature(method);
	enforce(sig !is null);
	return mono_signature_get_return_type(sig);
}

MonoType*[] getParamTypes(MonoMethod* method)
{
	Appender!(MonoType*[]) ret;
	enforce(method !is null);
	auto sig = getSignature(method);
	enforce(sig !is null);
	void* p;
	MonoType* t;
	while ( (t = mono_signature_get_params(sig,&p)) !is null)
	{
		ret.put(t);
	}
	return ret.data;
}

string getSignatureDescription(MonoMethod* method)
{
	enforce(method !is null);
	auto sig = mono_method_signature(method);
	enforce(sig !is null);
	auto ret = mono_signature_get_desc(sig,1);
	enforce(ret !is null);
	return ret.fromStringz.idup;
}

string getName(MonoType* type)
{
	enforce(type !is null);
	auto ret = mono_type_full_name(type);
	enforce(ret !is null);
	return ret.fromStringz.idup;
}




MonoClass* getClassT(T)()
if (!isDynamicArray!T)
{
	auto id = getId!T;
	static assert(id in CommonClassMap);
	mixin(format!"return mono_get_%s_class();"(id));
}

MonoClass* getClassT(T)()
if (isDynamicArray!T)
{
	return mono_get_array_class();
}

MonoClass* getClassT(T:MonoThreadT)()
{
	return mono_get_thread_class();
}

MonoClass* getClassT(T:MonoSByteT)()
{
	return mono_get_sbyte_class();
}

MonoClass* getClassT(T)()
if (is(T==struct) || is(T==class))
{
	return mono_get_object_class();
}

MonoClass* getClassT(T)()
if (is(T==enum))
{
	return mono_get_enum_class();
}

enum string[TypeInfo] CommonClassMap =
[
	getId!void:		"void",
	getId!bool:		"boolean",
	getId!ushort:	"uint16",
	getId!uint:		"uint32",
	getId!ulong:	"uint64",
	getId!short:	"int16",
	getId!int:		"int32",
	getId!long:		"int64",
	getId!double:	"double",
	getId!(int*):	"intptr",
	getId!(uint*):	"uintptr",
	getId!(void*):	"intptr",
	getId!(float):	"single",
	getId!(string):	"string",
	getId!(char):	"char",
	getId!(ubyte):	"ubyte",

];

auto getId(T)()
{
	return typeid(T);
}


struct MonoThreadT
{

}
struct MonoSByteT
{
	char val;
	alias val this;
}

_MonoReflectionType* monoGetTypeObject(MonoDomain* domain,MonoType* type)
{
    return safeReturn(mono_type_get_object(domain,type));
}

string fullName(MonoType* type)
{
    enforce(type !is null);
    return safeReturn(mono_type_full_name(type)).fromStringz.idup;
}

string shortName(MonoType* type)
{
    enforce(type !is null);
    return safeReturn(mono_type_get_name(type)).fromStringz.idup;    
}

MonoArrayType* getArrayType(MonoType* type)
{
    enforce(type !is null);
    return safeReturn(mono_type_get_array_type(type));
}

MonoClass* getClass(MonoType* type)
{
    enforce(type !is null);
    return safeReturn(mono_type_get_class(type));
}

MonoType* getPtrType(MonoType* type)
{
    enforce(type !is null);
    return safeReturn(mono_type_get_ptr_type(type));    
}

int monoTypeGetType(MonoType* type)
{
    enforce(type !is null);
    return mono_type_get_type(type);
}
MonoType* getUnderlyingType(MonoType* type)
{
    enforce(type !is null);
    return safeReturn(mono_type_get_underlying_type(type));
}

bool isByRef(MonoType* type)
{
    enforce(type !is null);
    return (mono_type_is_byref(type)!=0);
}

bool isStruct(MonoType* type)
{
    enforce(type !is null);
    return (mono_type_is_struct(type)!=0);
}

bool isVoid(MonoType* type)
{
    enforce(type !is null);
    return (mono_type_is_void(type)!=0);
}

bool isPointer(MonoType* type)
{
    enforce(type !is null);
    return (mono_type_is_pointer(type)!=0);
}

bool isReference(MonoType* type)
{
    enforce(type !is null);
    return (mono_type_is_reference(type)!=0);
}

auto toUnmanaged(MonoType* type, MonoMarshalSpec* marshalSpec, bool asField, int unicode, void* conv)
{
    enforce(type !is null);
    enforce(marshalSpec !is null);
    return mono_type_to_unmanaged(type,marshalSpec,asField,unicode,cast(int*)conv);
}
bool genericInstanceIsValueType(MonoType* type)
{
    enforce(type !is null);
    return (mono_type_generic_inst_is_valuetype(type)!=0);
}

auto stackSize(MonoType* type, int* alignment)
{
    enforce(type !is null);
    return mono_type_stack_size(type,alignment);
}

auto createFromTypeSpec(MonoImage* image,uint typeSpec)
{
    return safeReturn(mono_type_create_from_typespec(image,typeSpec));
}

auto getModifiers(MonoType* type, bool isRequired, void** iter)
{
	int required = isRequired?1:0;
    enforce(type !is null);
	enforce(iter !is null);
    return safeReturn(mono_type_get_modifiers(type,&required,iter));
}

auto arrayClass(MonoClass* elementClass, uint rank, bool isBounded)
{
	enforce(elementClass !is null);
	return safeReturn(mono_bounded_array_class_get(elementClass,rank,isBounded));
}

void free(MonoMethod* method)
{
	enforce(method !is null);
	mono_free_method(method);
}

MonoMethod* getDelegateInvoke(MonoClass* class_)
{
	enforce(class_ !is null);
	return safeReturn(mono_get_delegate_invoke(class_));
}

MonoObject* clone(MonoObject* obj)
{
	enforce(obj !is null);
	return safeReturn(mono_object_clone(obj));
}

MonoMethod* getVirtualMethod(MonoObject* obj, MonoMethod* method)
{
	enforce(obj !is null);
	enforce(method !is null);
	return safeReturn(mono_object_get_virtual_method(obj,method));
}

bool objectIsInst(MonoObject* obj, MonoClass* class_)
{
	enforce(obj !is null);
	enforce(class_ !is null);
	auto ret = mono_object_isinst(obj,class_);
	return (ret == obj);
}

void* unbox(MonoObject* obj)
{
	enforce(obj !is null);
	return safeReturn(mono_object_unbox(obj));
}

MonoObject* castClass(MonoObject* obj, MonoClass* class_)
{
	enforce(obj !is null);
	enforce(class_ !is null);
	return safeReturn(mono_object_castclass_mbyref(obj,class_));
}


size_t getSize(MonoObject* o)
{
	enforce(o !is null);
	return cast(size_t)mono_object_get_size(o);
}

auto getHash(MonoObject* o)
{
	enforce(o !is null);
	return mono_object_hash(o);
}
/+
auto toString(MonoObject* o)
{
	enforce(o !is null);
	MonoObject* exc;
	auto ret = mono_object_to_string(o,&exc);
	if (ret is null)
	{
		MonoObject* exc2;
		ret = mono_object_to_string(exc,&exc2);
		enforce(ret !is null,"error calling toString on exception when calling toString on object!");
	}
	return ret;
}
+/
MonoObject* valueBox(MonoDomain* domain, MonoClass* class_, void* value)
{
	return safeReturn(mono_value_box(domain,class_,value));
}

void valueCopy(void* source, void* dest, MonoClass* class_)
{
	enforce(source !is null);
	enforce(dest !is null);
	mono_value_copy(dest,source,class_);
}


void valueCopyArray(MonoArray* dest, int destIndex, void* source, int count)
{
	enforce(source !is null);
	enforce(dest !is null);
	mono_value_copy_array(dest,destIndex,source,count);
}

alias GCObject = MonoObject;

MonoString* monoString(string s)
{
	return safeReturn(mono_string_new(mono_domain_get(),s.toStringz));
}


auto getType(MonoType* type)
{
	return mono_type_get_type(type);
}


auto getMonoType(T)()
{
	static if(is(T==int))
		return MONO_TYPE_I4;
	static assert(0);
}




MonoClass* getClass(MonoObject* obj)
{
	auto klass = obj.getClass();
	return klass;
}


void invoke(MonoObject* obj, MonoMethod* method)
{
	enforce(obj !is null);
	enforce(method !is null);
	mono_runtime_invoke (method, obj, null,null);	
}

MonoObject* monoArray(T)(MonoDomain* domain, size_t size)
{
	auto type = getMonoType!T;
	return mono_array_new(domain,type,size);
}

// mono_get_byte_class

T getProperty(T)(MonoClass* klass, string value)
{
	auto prop = mono_class_get_property_from_name (klass, value.toStringz);
	auto method = mono_property_get_get_method (prop);
	auto result = mono_runtime_invoke (method, obj, null,null);
	return *(cast(T*)(mono_object_unbox(result)));
}

/+
string getPropertyString(MonoClass* klass, string value)
{
	auto prop = mono_class_get_property_from_name(klass, value.monoString);
	auto str = cast(MonoString*)mono_property_get_value (prop, obj, null,null);
	auto p = mono_string_to_utf8(str);
	auto ret = p.toStringz;
	mono_free(p);
	return ret;
}


void create_object (MonoDomain *domain, MonoImage *image)
{
	MonoClass* klass = mono_class_from_name (image, "Embed", "MyType");
	enforce(klass !is null, format!"Can't find MyType in assembly %s"(image.getFilename));
	MonoObject* obj = mono_object_new (domain, klass);
	mono_runtime_object_init (obj);

	access_valuetype_field (obj);
	access_reference_field (obj);

	call_methods (obj);
	more_methods (domain);
}
+/

string getFilename(MonoImage* image)
{
	return safeReturn(mono_image_get_filename(image)).fromStringz.idup;
}

struct CliClass
{
	string name;
	MonoClass* handle;

	MonoMethod*[string] methodTable;

	this(MonoClass* monoClass)
	{
		enforce(monoClass !is null);
		this.handle = monoClass;
		this.name = monoClass.getName();
		auto methods = monoClass.getMethods();
		tracef("creating %s methods on class %s",methods.length,this.name);
		foreach(ref method;methods)
		{
			auto fullName = format!"%s(%s)"(method.getName,method.getSignatureDescription);
			methodTable[fullName] = method;
		}
		tracef("done");
	}

/*    template opDispatch(string s) {
        template opDispatch(TARGS...) {
            auto opDispatch(ARGS...)(ARGS args) {
                static if(TARGS.length) return mixin("b." ~ s ~ "!TARGS(args)");
                else return mixin("b." ~ s ~ "(args)");
            }
        }
    }
*/
	template opDispatch(string method)
	{
		template opDispatch(T...)
		{
			MonoObject* opDispatch(T...)(T args)
			{
				tracef("called method %s on %s",method,this.name);
				MonoObject* exc;
				auto methodFullName = format!"%s(%s)"(method,methodArgs(args));
				writefln("method full name is %s",methodFullName);
				auto p = methodFullName in methodTable;
				enforce(p !is null,format!"calling %s method on %s class but method is not found: %s"(methodFullName,this.name,this.methodTable.keys));
				auto methodHandle = *p;

				enforce(*p !is null, format!"missing method calling %s on %s"(methodFullName,this.name));
				void*[] argsPtr;
				argsPtr.length = args.length;
				foreach(i,ref arg;args)
				{
					argsPtr[i] = convertToCSharp(&arg);
				}

				MonoObject* result = mono_runtime_invoke(methodHandle,null,cast(void**) argsPtr.ptr,&exc);
				//enforce(result !is null, exc.toString());
				return result;
			}
		}
	}

	MonoObject* invokeObjectMethod(string method,T...)(MonoObject* obj,T args)
	{
		tracef("called method %s on %s",method,this.name);
		MonoObject* exc;
		auto methodFullName = format!"%s(%s)"(method,methodArgs(args));
		writefln("method full name is %s",methodFullName);
		auto p = methodFullName in methodTable;
		enforce(p !is null,format!"calling %s method on %s class but method is not found: %s"(methodFullName,this.name,this.methodTable.keys));
		auto methodHandle = *p;

		enforce(*p !is null, format!"missing method calling %s on %s"(methodFullName,this.name));
		void*[] argsPtr;
		argsPtr.length = args.length;
		foreach(i,ref arg;args)
		{
			argsPtr[i] = convertToCSharp(&arg);
		}

		MonoObject* result = mono_runtime_invoke(methodHandle,obj,cast(void**) argsPtr.ptr,&exc);
		//enforce(result !is null, exc.toString());
		return result;
	}

	void createObject(MonoDomain* domain)
	{
		mono_object_new(domain,this.handle);
	}
}

string methodArgs(T...)(T args)
{
	Appender!(string[]) ret;
	static foreach(A;AliasSeq!T)
	{
		enum id = getId!A;
		enforce(id in CommonClassMap);
		auto baseTypeString = CommonClassMap[id];
		auto typeString = baseTypeString
							.replace("int32","int");
		ret.put(typeString);
	}
	return ret.data.join(",");
}

void* convertToCSharp(T)(T* arg)
if (!is(T==string))
{
	return cast(void*)arg;
}
void* convertToCSharp(string* arg)
{
	auto ret = (*arg).monoString();
	return cast(void*) ret;
}

struct CliObject
{
	MonoObject* handle;
	CliClass* cliClass;

	this(MonoObject* obj,CliClass* cliClass = null)
	{
		enforce(obj !is null);
		this.cliClass = (cliClass is null) ? new CliClass(obj.getClass()) : cliClass;
		this.handle = obj;
		tracef("done object init");
	}

	template opDispatch(string method)
	{
		template opDispatch(T...)
		{
			MonoObject* opDispatch(T...)(T args)
			{
				tracef("called method %s on object of class %s",method,cliClass.name);
				return cliClass.invokeObjectMethod!(method)(this.handle,args);
			}
		}
	}
}

void addInternalCall(F)(string className, string methodName, F funcPtr)
if (isFunction!F)
{
	mono_add_internal_call( format!"%s::%s"(className,methodName).toStringz, funcPtr);
}


void printNameSpaces(ref Domain domain)
{
	auto namespaces = domain.getAssemblyNamespaces();
	foreach(namespace;namespaces)
		writefln("%s",namespace);
}

void printClassesFromAssembly(ref Domain domain)
{
		auto classes = domain.getAssemblyClassList();
		foreach(class_;classes)
		writefln("%s/%s",class_.getNameSpace,class_.getName);	
}

void printMethodsOfClass(ref Domain domain, string nameSpace, string className)
{
		auto methods = domain.getMethods(nameSpace,className);
		foreach(method;methods)
			writefln("%s::%s %s -> %s",className,method.getName(),method.getSignatureDescription,method.getReturnType.getName());
}

string[] getAssemblyClassNames(ref Domain domain)
{
	return domain.getAssemblyClassList.map!(c => c.getName).array;
}

string[] getAssemblyNamespaces(ref Domain domain)
{
	return domain.getAssemblyClassList.map!(c => c.getNameSpace).array.sort.uniq.array;
}


int getFlags(MonoClassField* classField)
{
	enforce(classField !is null);
	return mono_field_get_flags(classField);
}

MonoObject* mono_field_get_object()
{
	return safeReturn(mono_field_get_object());
}

MonoClassField* monoFieldFromToken(MonoImage* image, uint token, MonoClass** retClass, MonoGenericContext* context)
{
	return safeReturn(mono_field_from_token(image,token,retClass,context));
}

string getName(MonoProperty* property)
{
	enforce(property !is null);
	return safeReturn(mono_property_get_name(property)).fromStringz.idup;
}

MonoClass* getParent(MonoProperty* property)
{
	enforce(property !is null);
	return safeReturn(mono_property_get_parent(property));
}

MonoMethod*  getGetMethod(MonoProperty* property)
{
	enforce(property !is null);
	return safeReturn(mono_property_get_get_method(property));
}

MonoMethod* getSetMethod(MonoProperty* property)
{
	enforce(property !is null);
	return safeReturn(mono_property_get_set_method(property));
}

// missing C binding I think
version(None)
{
	MonoReflectionProperty* getObjectChecked(MonoDomain* domain, MonoClass* monoClass, MonoProperty* property, MonoError* error)
	{
		enforce(domain !is null);
		enforce(monoClass !is null);
		enforce(property !is null);
		return safeReturn(mono_property_get_object_checked(domain,monoClass,property,error));
	}
}
int getFlags(MonoProperty* property)
{
	enforce(property !is null);
	return mono_property_get_flags(property);
}
MonoObject* getValue(MonoProperty *property, void *obj, void **params, MonoObject **exc)
{
	enforce(property !is null);
	enforce(obj !is null);
	enforce(params !is null);
	return safeReturn(mono_property_get_value(property,obj,params,exc));
}

void setValue(MonoProperty *property, void *obj, void **params, MonoObject **exc)
{
	enforce(property !is null);
	enforce(obj !is null);
	enforce(params !is null);
	mono_property_set_value(property,obj,params,exc);
}

T getValue(T)(MonoObject* obj, string fieldName)
{
	enforce(obj !is null);
	auto field = getField(obj,fieldName);
	T ret;
	mono_field_get_value(obj,field,cast(void*)&ret);
	return ret;
}
	
MonoObject* getValueObject(MonoDomain* domain, MonoObject* obj, string fieldName)
{
	enforce(domain !is null);
	enforce(obj !is null);
	auto field = getField(obj,fieldName);
	return safeReturn(mono_field_get_value_object(domain,field,obj));
}

MonoClassField* getField(MonoObject* obj, string fieldName)
{
	MonoClass *klass = obj.getClass();
	MonoClassField* field = mono_class_get_field_from_name(klass, fieldName.toStringz);
	enforce(field !is null);
	return field;
}

void setValue(T)(MonoObject* obj, string fieldName,T val)
{
	auto field = getField(obj,fieldName);
	auto type = field.getType;
	enforce(type == getMonoType!T);
	mono_field_set_value(obj,field.toStringz,&val); 
}

T getValue(T)(MonoVTable* vt, string fieldName)
{
	enforce(vt !is null);
	auto field = getField(obj,fieldName);
	T ret;
	mono_field_static_get_value(vt,field,&ret);
	return ret;
}

void setValue(T)(MonoVTable* vt, string fieldName, T value)
{
	enforce(vt !is null);
	auto field = getField(obj,fieldName);
	mono_field_static_set_value(vt,field,cast(void*)&value);
}

string getName(MonoClassField* classField)
{
	enforce(classField !is null);
	return safeReturn(mono_field_get_name(classField)).fromStringz.idup;
}

MonoClass* getParent(MonoClassField* classField)
{
	enforce(classField !is null);
	return safeReturn(mono_field_get_parent(classField));
}

int getType(MonoClassField* classField)
{
	enforce(classField !is null);
	auto type = mono_field_get_type(classField);
	enforce (type !is null);
	return mono_type_get_type(type);
}

T getAs(T)(MonoObject* obj, string fieldName)
{
	auto monoField = getField(obj,fieldName);
	return getAs!T(obj,monoField);
}

T getAs(T)(MonoObject* obj, MonoClassField* monoField)
{
	T ret;
	auto type = monoField.getType();
	enforce(type == getMonoType!T);
	mono_field_get_value(obj,monoField,&ret);
	return ret;
}

