module GraphqlHelpers
  # Run a loader's named resolver
  def resolve(kls, name, obj: nil, args: {}, ctx: {})
    kls[name].call(obj, args, ctx)
  end

  # Runs a block inside a BatchLoader::Executor wrapper
  def batch(max_queries: nil, &blk)
    wrapper = proc do
      begin
        BatchLoader::Executor.ensure_current
        blk.call
      ensure
        BatchLoader::Executor.clear_current
      end
    end
  
    if max_queries
      result = nil
      expect { result = wrapper.call }.not_to exceed_query_limit(max_queries)
      result
    else
      wrapper.call
    end
  end
end
