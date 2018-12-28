


	val = 100;
	str = mono_string_new (domain, "another string");
	args [0] = &val;
	args [1] = &str;
	mono_runtime_invoke (mvalues, obj, args, NULL);
	/* get the string in UTF-8 encoding to print it */
	p = mono_string_to_utf8 (str);
	printf ("Values of str/val from Values () are: %s/%d\n", p, val);
	/* we need to free the result from mono_string_to_utf8 () */
	mono_free (p);
}

static void
more_methods (MonoDomain *domain)
{
	MonoClass *klass;
	MonoMethodDesc* mdesc;
	MonoMethod *method, *vtmethod;
	MonoString *str;
	MonoObject *obj;
	char *p;
	int val;

	/* Now let's call an instance method on a valuetype. There are two
	 * different case:
	 * 1) calling a virtual method defined in a base class, like ToString (): 
	 * we need to pass the value boxed in an object
	 * 2) calling a normal instance method: in this case
	 * we pass the address to the valuetype as the second argument 
	 * instead of an object.
	 * First some initialization.
	 */
	val = 25;
	klass = mono_get_int32_class ();
	obj = mono_value_box (domain, klass, &val);

	/* A different way to search for a method */
	mdesc = mono_method_desc_new (":ToString()", FALSE);
	vtmethod = mono_method_desc_search_in_class (mdesc, klass);

	str = (MonoString*)mono_runtime_invoke (vtmethod, &val, NULL, NULL);
	/* get the string in UTF-8 encoding to print it */
	p = mono_string_to_utf8 (str);
	printf ("25.ToString (): %s\n", p);
	/* we need to free the result from mono_string_to_utf8 () */
	mono_free (p);

	/* Now: see how the result is different if we search for the ToString ()
	 * method in System.Object: mono_runtime_invoke () doesn't do any sort of
	 * virtual method invocation: it calls the exact method that it was given 
	 * to execute. If a virtual call is needed, mono_object_get_virtual_method ()
	 * can be called.
	 */
	method = mono_method_desc_search_in_class (mdesc, mono_get_object_class ());
	str = (MonoString*)mono_runtime_invoke (method, obj, NULL, NULL);
	/* get the string in UTF-8 encoding to print it */
	p = mono_string_to_utf8 (str);
	printf ("25.ToString (), from System.Object: %s\n", p);
	/* we need to free the result from mono_string_to_utf8 () */
	mono_free (p);

	/* Now get the method that overrides ToString () in obj */
	vtmethod = mono_object_get_virtual_method (obj, method);
	if (mono_class_is_valuetype (mono_method_get_class (vtmethod))) {
		printf ("Need to unbox this for call to virtual ToString () for %s\n", mono_class_get_name (klass));
	}

	mono_method_desc_free (mdesc);
}


static void main_function (MonoDomain *domain, const char *file, int argc, char **argv)
{
	MonoAssembly *assembly;

	/* Loading an assembly makes the runtime setup everything
	 * needed to execute it. If we're just interested in the metadata
	 * we'd use mono_image_load (), instead and we'd get a MonoImage*.
	 */
	assembly = mono_domain_assembly_open (domain, file);
	if (!assembly)
		exit (2);
	/*
	 * mono_jit_exec() will run the Main() method in the assembly.
	 * The return value needs to be looked up from
	 * System.Environment.ExitCode.
	 */
	mono_jit_exec (domain, assembly, argc, argv);

	create_object (domain, mono_assembly_get_image (assembly));
}

int 
main (int argc, char* argv[]) {
	MonoDomain *domain;
	const char *file;
	int retval;
	
	if (argc < 2){
		fprintf (stderr, "Please provide an assembly to load\n");
		return 1;
	}
	file = argv [1];
	/*
	 * mono_jit_init() creates a domain: each assembly is
	 * loaded and run in a MonoDomain.
	 */
	domain = mono_jit_init (file);

	main_function (domain, file, argc - 1, argv + 1);

	retval = mono_environment_exitcode_get ();
	
	mono_jit_cleanup (domain);
	return retval;
}


