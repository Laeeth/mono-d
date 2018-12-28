module mono.domain;
import derelict.mono;
import mono.common;
import std.exception;
import std.string:fromStringz,toStringz;

MonoDomain* createDomain()
{
      return safeReturn(mono_domain_create());
}

private char* toCString(string s)
{
      char[] ret = s.dup;
      return ret.ptr;
}

MonoDomain* createAppDomain(string friendlyName, string configurationFile)
{
      return safeReturn(mono_domain_create_appdomain(friendlyName.toCString,configurationFile.toCString));
}

bool finalizeDomain(MonoDomain* domain, uint timeout)
{
      return (mono_domain_finalize(domain,timeout)!=0);
}

void foreachDomain(MonoDomainFunc func, void* userData)
{
      mono_domain_foreach(func,userData);
}

void free(MonoDomain* domain, bool force)
{
      mono_domain_free(domain, force?1:0);
}

MonoDomain* fromAppDomain(MonoAppDomain* appDomain)
{
      return safeReturn(mono_domain_from_appdomain(appDomain));
}

MonoDomain* domainGetById(int domainId)
{
      return safeReturn(mono_domain_get_by_id(domainId));
}

string getFriendlyName(MonoDomain* domain)
{
      return safeReturn(mono_domain_get_friendly_name(domain)).fromStringz.idup;
}

int getId(MonoDomain* domain)
{
      enforce(domain !is null);
      return mono_domain_get_id(domain);
}

MonoDomain* getDomain()
{           
      return safeReturn(mono_domain_get());
}

bool hasTypeResolve(MonoDomain* domain)
{
      return (mono_domain_has_type_resolve(domain)!=0);
}

bool ownsVtableSlot(MonoDomain* domain, void* vtableSlot)
{
      return (mono_domain_owns_vtable_slot(domain,vtableSlot)!=0);
}

void setConfig(MonoDomain* domain, string baseDir, string configFilename)
{
      mono_domain_set_config(domain,baseDir.toStringz,configFilename.toStringz);
}

void setInternal(MonoDomain* domain)
{
      mono_domain_set_internal(domain);
}

bool setDomain(MonoDomain* domain, bool force)
{
      return (mono_domain_set(domain, force?1:0)!=0);
}


MonoReflectionAssembly* tryTypeResolve(MonoDomain* domain, string name, MonoObject* tb)
{
      return safeReturn(mono_domain_try_type_resolve(domain,name.toCString,tb));
}

MonoObject* tryUnload(MonoDomain* domain)
{
      MonoObject* exc;
      mono_domain_try_unload(domain,&exc);
      return exc;
}

void unload(MonoDomain* domain)
{
      mono_domain_unload(domain);
}

void contextInit(MonoDomain* domain)
{
      mono_context_init(domain);
}

MonoAppContext* getAppDomainContext()
{
      return safeReturn(mono_context_get());
}

int contextGetDomainId(MonoAppContext* context)
{
      return mono_context_get_domain_id(context);
}

void contextSet(MonoAppContext* context)
{
      mono_context_set(context);
}

string contextGetDescription(MonoGenericContext* context)
{
      return safeReturn(mono_context_get_desc(context)).fromStringz.idup;
}
