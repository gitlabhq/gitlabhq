# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      # Called by {Dataloader} to prepare the {Source}'s internal state
      # @api private
      def setup(dataloader)
        # These keys have been requested but haven't been fetched yet
        @pending = {}
        # These keys have been passed to `fetch` but haven't been finished yet
        @fetching = {}
        # { key => result }
        @results = {}
        @dataloader = dataloader
      end

      attr_reader :dataloader

      # @return [Dataloader::Request] a pending request for a value from `key`. Call `.load` on that object to wait for the result.
      def request(value)
        res_key = result_key_for(value)
        if !@results.key?(res_key)
          @pending[res_key] ||= value
        end
        Dataloader::Request.new(self, value)
      end

      # Implement this method to return a stable identifier if different
      # key objects should load the same data value.
      #
      # @param value [Object] A value passed to `.request` or `.load`, for which a value will be loaded
      # @return [Object] The key for tracking this pending data
      def result_key_for(value)
        value
      end

      # @return [Dataloader::Request] a pending request for a values from `keys`. Call `.load` on that object to wait for the results.
      def request_all(values)
        values.each do |v|
          res_key = result_key_for(v)
          if !@results.key?(res_key)
            @pending[res_key] ||= v
          end
        end
        Dataloader::RequestAll.new(self, values)
      end

      # @param value [Object] A loading value which will be passed to {#fetch} if it isn't already in the internal cache.
      # @return [Object] The result from {#fetch} for `key`. If `key` hasn't been loaded yet, the Fiber will yield until it's loaded.
      def load(value)
        result_key = result_key_for(value)
        if @results.key?(result_key)
          result_for(result_key)
        else
          @pending[result_key] ||= value
          sync([result_key])
          result_for(result_key)
        end
      end

      # @param values [Array<Object>] Loading keys which will be passed to `#fetch` (or read from the internal cache).
      # @return [Object] The result from {#fetch} for `keys`. If `keys` haven't been loaded yet, the Fiber will yield until they're loaded.
      def load_all(values)
        result_keys = []
        pending_keys = []
        values.each { |v|
          k = result_key_for(v)
          result_keys << k
          if !@results.key?(k)
            @pending[k] ||= v
            pending_keys << k
          end
        }

        if !pending_keys.empty?
          sync(pending_keys)
        end

        result_keys.map { |k| result_for(k) }
      end

      # Subclasses must implement this method to return a value for each of `keys`
      # @param keys [Array<Object>] keys passed to {#load}, {#load_all}, {#request}, or {#request_all}
      # @return [Array<Object>] A loaded value for each of `keys`. The array must match one-for-one to the list of `keys`.
      def fetch(keys)
        # somehow retrieve these from the backend
        raise "Implement `#{self.class}#fetch(#{keys.inspect}) to return a record for each of the keys"
      end

      MAX_ITERATIONS = 1000
      # Wait for a batch, if there's anything to batch.
      # Then run the batch and update the cache.
      # @return [void]
      def sync(pending_result_keys)
        @dataloader.yield(self)
        iterations = 0
        while pending_result_keys.any? { |key| !@results.key?(key) }
          iterations += 1
          if iterations > MAX_ITERATIONS
            raise "#{self.class}#sync tried #{MAX_ITERATIONS} times to load pending keys (#{pending_result_keys}), but they still weren't loaded. There is likely a circular dependency#{@dataloader.fiber_limit ? " or `fiber_limit: #{@dataloader.fiber_limit}` is set too low" : ""}."
          end
          @dataloader.yield(self)
        end
        nil
      end

      # @return [Boolean] True if this source has any pending requests for data.
      def pending?
        !@pending.empty?
      end

      # Add these key-value pairs to this source's cache
      # (future loads will use these merged values).
      # @param new_results [Hash<Object => Object>] key-value pairs to cache in this source
      # @return [void]
      def merge(new_results)
        new_results.each do |new_k, new_v|
          key = result_key_for(new_k)
          @results[key] = new_v
        end
        nil
      end

      # Called by {GraphQL::Dataloader} to resolve and pending requests to this source.
      # @api private
      # @return [void]
      def run_pending_keys
        if !@fetching.empty?
          @fetching.each_key { |k| @pending.delete(k) }
        end
        return if @pending.empty?
        fetch_h = @pending
        @pending = {}
        @fetching.merge!(fetch_h)
        results = fetch(fetch_h.values)
        fetch_h.each_with_index do |(key, _value), idx|
          @results[key] = results[idx]
        end
        nil
      rescue StandardError => error
        fetch_h.each_key { |key| @results[key] = error }
      ensure
        fetch_h && fetch_h.each_key { |k| @fetching.delete(k) }
      end

      # These arguments are given to `dataloader.with(source_class, ...)`. The object
      # returned from this method is used to de-duplicate batch loads under the hood
      # by using it as a Hash key.
      #
      # By default, the arguments are all put in an Array. To customize how this source's
      # batches are merged, override this method to return something else.
      #
      # For example, if you pass `ActiveRecord::Relation`s to `.with(...)`, you could override
      # this method to call `.to_sql` on them, thus merging `.load(...)` calls when they apply
      # to equivalent relations.
      #
      # @param batch_args [Array<Object>]
      # @param batch_kwargs [Hash]
      # @return [Object]
      def self.batch_key_for(*batch_args, **batch_kwargs)
        [*batch_args, **batch_kwargs]
      end

      # Clear any already-loaded objects for this source
      # @return [void]
      def clear_cache
        @results.clear
        nil
      end

      attr_reader :pending, :results

      private

      # Reads and returns the result for the key from the internal cache, or raises an error if the result was an error
      # @param key [Object] key passed to {#load} or {#load_all}
      # @return [Object] The result from {#fetch} for `key`.
      # @api private
      def result_for(key)
        if !@results.key?(key)
          raise GraphQL::InvariantError, <<-ERR
Fetching result for a key on #{self.class} that hasn't been loaded yet (#{key.inspect}, loaded: #{@results.keys})

This key should have been loaded already. This is a bug in GraphQL::Dataloader, please report it on GitHub: https://github.com/rmosolgo/graphql-ruby/issues/new.
ERR
        end
        result = @results[key]
        if result.is_a?(StandardError)
          # Dup it because the rescuer may modify it.
          # (This happens for GraphQL::ExecutionErrors, at least)
          raise result.dup
        end

        result
      end
    end
  end
end
