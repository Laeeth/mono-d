module mono.exceptions;
import derelict.mono;
import std.string;
import std.exception;
import mono.common;


void raiseException(MonoException* ex)
{
	enforce(ex !is null);
	mono_raise_exception(ex);
}

void UnhandledException(MonoObject* exc)
{
	enforce(exc !is null);
	mono_unhandled_exception(exc);
}

void printUnhandledException(MonoObject* exc)
{
	enforce(exc !is null);
	mono_print_unhandled_exception(exc);
}

MonoException* getExceptionFromNameDomain(MonoDomain* domain,MonoImage* image, string nameSpace,string name)
{
	enforce(domain !is null);
	enforce(image !is null);
	return safeReturn(mono_exception_from_name_domain(domain,image,nameSpace.toStringz,name.toStringz));
}

MonoException* getExceptionFromName(MonoImage* image, string nameSpace, string name)
{
	enforce(image !is null);
	return safeReturn(mono_exception_from_name(image,nameSpace.toStringz,name.toStringz));
}

MonoException* getExceptionFromNameMessage(MonoImage* image, string nameSpace, string name, string message)
{
	enforce(image !is null);
	return safeReturn(mono_exception_from_name_msg(image,nameSpace.toStringz,name.toStringz,message.toStringz));
}


MonoException* getExceptionFromNameMessages(MonoImage* image, string nameSpace, string name, MonoString* message1, MonoString* message2)
{
	enforce(image !is null);
	enforce(message1 !is null);
	enforce(message2 !is null);
	return safeReturn(mono_exception_from_name_two_strings(image,nameSpace.toStringz,name.toStringz,message1,message2));
}


enum MonoExceptionType
{
	arithmetic,
	arrayTypeMismatch,
	divideByZero,
	executionEngine,
	fileNotFound,
	indexOutOfRange,
	invalidCast,
	io,
	notImplemented,
	nullReference,
	overflow,
	security,
	serialization,
	stackOverflow,
	synchronizationLock,
	threadAbort,
	threadState,
	invalidOperation,
	notSupported,
	fieldAccess,
	methodAccess,
	outOfMemory,
}

MonoException* getException(MonoExceptionType type, string message = null)
{
	final switch(type) with(MonoExceptionType)
	{
		case arithmetic:
			return safeReturn(mono_get_exception_arithmetic());

		case arrayTypeMismatch:
			return safeReturn(mono_get_exception_array_type_mismatch());

		case divideByZero:
			return safeReturn(mono_get_exception_divide_by_zero());

		case executionEngine:
			return safeReturn(mono_get_exception_execution_engine(message.toStringz));

		case fileNotFound:
			return safeReturn(mono_get_exception_file_not_found(message.monoString));

		case indexOutOfRange:
			return safeReturn(mono_get_exception_index_out_of_range());

		case invalidCast:
			return safeReturn(mono_get_exception_invalid_cast());

		case io:
			return safeReturn(mono_get_exception_io(message.toStringz));

		case notImplemented:
			return safeReturn(mono_get_exception_not_implemented(message.toStringz));

		case nullReference:
			return safeReturn(mono_get_exception_null_reference());

		case overflow:
			return safeReturn(mono_get_exception_overflow());

		case security:
			return safeReturn(mono_get_exception_security());

		case serialization:
			return safeReturn(mono_get_exception_serialization(message.toStringz));

		case stackOverflow:
			return safeReturn(mono_get_exception_stack_overflow());

		case synchronizationLock:
			return safeReturn(mono_get_exception_synchronization_lock(message.toStringz));

		case threadAbort:
			return safeReturn(mono_get_exception_thread_abort());

		case threadState:
			return safeReturn(mono_get_exception_thread_state(message.toStringz));

		case invalidOperation:
			return safeReturn(mono_get_exception_invalid_operation(message.toStringz));

		case notSupported:
			return safeReturn(mono_get_exception_not_supported(message.toStringz));

		case fieldAccess:
			return safeReturn(mono_get_exception_field_access());

		case methodAccess:
			return safeReturn(mono_get_exception_method_access());

		case outOfMemory:
			return safeReturn(mono_get_exception_out_of_memory());
	}
	assert(0);
}

MonoException* getExceptionRuntimeWrapped(MonoObject* wrappedException)
{
	return safeReturn(mono_get_exception_runtime_wrapped(wrappedException));
}

MonoException* getExceptionBadImageFormat(string message)
{
	return safeReturn(mono_get_exception_bad_image_format(message.toStringz));
}


MonoException* getExceptionCannotUnloadAppdomain(string message)
{
	return safeReturn(mono_get_exception_cannot_unload_appdomain(message.toStringz));
}

MonoClass* getExceptionClass()
{
	return safeReturn(mono_get_exception_class());
}


MonoException* getExceptionMissingMethod(string className, string memberName)
{
	return safeReturn(mono_get_exception_missing_method(className.toStringz,memberName.toStringz));
}
MonoException* getExceptionTypeInitialization(string typeName, MonoException* inner)
{
	enforce(inner !is null);
	return safeReturn(mono_get_exception_type_initialization(typeName.toStringz,inner));
}

MonoException* getExceptionTypeLoad(MonoString* className, string assemblyName)
{
	enforce(className !is null);
	return safeReturn(mono_get_exception_type_load(className,cast(char*)assemblyName.toStringz));
}

MonoException* getExceptionMissingField(string className, string memberName)
{
	return safeReturn(mono_get_exception_missing_field(className.toStringz,memberName.toStringz));
}

MonoException* getExceptionReflectionTypeLoad(MonoArray* types, MonoArray* exceptions)
{
	return safeReturn(mono_get_exception_reflection_type_load(types,exceptions));
}

MonoException* fromTokenTwoStrings(MonoImage* image, int token, MonoString* a1, MonoString* a2)
{
	return safeReturn(mono_exception_from_token_two_strings(image,token,a1,a2));
}

MonoException* getExceptionBadFormat(string message)
{
	return safeReturn(mono_get_exception_bad_image_format(message.toStringz));
}


MonoException* getExceptionAppDomainUnloaded()
{
	return safeReturn(mono_get_exception_appdomain_unloaded());
}

MonoException* getExceptionArgument(string arg, string message)
{
	return safeReturn(mono_get_exception_argument(arg.toStringz,message.toStringz));
}

MonoException* getExceptionArgumentNull(string arg)
{
	return safeReturn(mono_get_exception_argument_null(arg.toStringz));
}

MonoException* getExceptionArgumentOutOfRange(string arg)
{
	return safeReturn(mono_get_exception_argument_out_of_range(arg.toStringz));
}

