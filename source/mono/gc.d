module mono.gc;
import derelict.mono;
import mono.common;
import std.exception;


alias GCObject = MonoObject;

struct MonoGC
{
	struct Handle
	{
		int value;
		alias value this;
	}
	static Handle newHandle(GCObject *obj, bool isPinned)
	{
		enforce(obj !is null);
		return Handle(mono_gchandle_new(obj,isPinned?1:0));
	}

	static Handle newWeakRef(GCObject* obj, bool trackResurrection)
	{
		enforce(obj !is null);
		return Handle(mono_gchandle_new_weakref(obj,trackResurrection?1:0));
	}

	static GCObject* getTarget(Handle handle)
	{
		return safeReturn(mono_gchandle_get_target(handle));
	}

	static void free(Handle handle)
	{
		mono_gchandle_free(handle);
	}

	static void collect(int generation)
	{
		mono_gc_collect(generation);
	}

	static int collectionCount(int generation)
	{
		return mono_gc_collection_count(generation);
	}
	static int maxGeneration()
	{
		return mono_gc_max_generation();
	}
	static int getGeneration(MonoObject* obj)
	{
		enforce(obj !is null);
		return mono_gc_get_generation(obj);
	}

	static size_t getHeapSize()
	{
		return mono_gc_get_heap_size();
	}

	static size_t getUsedSize()
	{
		return mono_gc_get_used_size();
	}

	static int walkHeap(MonoGCReferences callback, void* userData, int unusedFlags =0)
	{
		enforce(userData !is null);
		return mono_gc_walk_heap(unusedFlags,callback,userData);
	}
	static bool queueAdd(MonoReferenceQueue* queue,MonoObject* obj, void* userData)
	{
		enforce(queue !is null);
		enforce(obj !is null);
		return (mono_gc_reference_queue_add(queue,obj,userData)!=0);
	}
	static void queueFree(MonoReferenceQueue* queue)
	{
		enforce(queue !is null);
		mono_gc_reference_queue_free(queue);
	}

	static MonoReferenceQueue* queueNew(mono_reference_queue_callback callback)
	{
		enforce(callback !is null);
		return safeReturn(mono_gc_reference_queue_new(callback));
	}


	static auto registerBridgeCallbacks(MonoGCBridgeCallbacks* callbacks)
	{
		return mono_gc_register_bridge_callbacks(callbacks);
	}

	static void waitForBridgeProcessing()
	{
		return mono_gc_wait_for_bridge_processing();
	}


	static void writeBarrierArrayRefCopy(void* src,void* dest, int count)
	{
		enforce(dest !is null);
		enforce(src !is null);
		mono_gc_wbarrier_arrayref_copy(dest,src,count);
	}

	static void writeBarrierGenericNoStore(MonoObject* obj)
	{
		enforce(obj !is null);
		mono_gc_wbarrier_generic_nostore(obj);
	}

	static void writeBarrierGenericStore(void* ptr, MonoObject* value)
	{
		enforce(value !is null);
		enforce(ptr !is null);
		mono_gc_wbarrier_generic_store(ptr,value);
	}

	static void writeBarrierGenericStoreAtomic(void* ptr, MonoObject* value)
	{
		enforce(ptr !is null);
		enforce(value !is null);
		mono_gc_wbarrier_generic_store_atomic(ptr,value);
	}

	static void writeBarrierObjectCopy(MonoObject* obj, MonoObject* src)
	{
		enforce(obj !is null);
		enforce(src !is null);
		mono_gc_wbarrier_object_copy(obj,src);
	}

	static void writeBarrierSetArrayRef(MonoArray* arr,void* slotPtr,MonoObject* value)
	{
		enforce(arr !is null);
		enforce(slotPtr !is null);
		enforce(value !is null);
		mono_gc_wbarrier_set_arrayref(arr,slotPtr,value);
	}

	static void writeBarrierSetField(MonoObject* obj, void* fieldPtr, MonoObject* value)
	{
		enforce(obj !is null);
		enforce([fieldPtr] !is null);
		enforce(value !is null);
		mono_gc_wbarrier_set_field(obj, fieldPtr, value);
	}
}


