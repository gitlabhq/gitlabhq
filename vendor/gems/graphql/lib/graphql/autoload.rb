# frozen_string_literal: true

module GraphQL
  # @see GraphQL::Railtie for automatic Rails integration
  module Autoload
    # Register a constant named `const_name` to be loaded from `path`.
    # This is like `Kernel#autoload` but it tracks the constants so they can be eager-loaded with {#eager_load!}
    # @param const_name [Symbol]
    # @param path [String]
    # @return [void]
    def autoload(const_name, path)
      @_eagerloaded_constants ||= []
      @_eagerloaded_constants << const_name

      super const_name, path
    end

    # Call this to load this constant's `autoload` dependents and continue calling recursively
    # @return [void]
    def eager_load!
      @_eager_loading = true
      if @_eagerloaded_constants
        @_eagerloaded_constants.each { |const_name| const_get(const_name) }
        @_eagerloaded_constants = nil
      end
      nil
    ensure
      @_eager_loading = false
    end

    private

    # @return [Boolean] `true` if GraphQL-Ruby is currently eager-loading its constants
    def eager_loading?
      @_eager_loading ||= false
    end
  end
end
