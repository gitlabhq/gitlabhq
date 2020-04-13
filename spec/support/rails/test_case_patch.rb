# frozen_string_literal: true
#
# This file pulls in the changes in https://github.com/rails/rails/pull/38063
# to fix controller specs updated with the latest Rack versions.
#
# This file should be removed after that change ships. It is not
# present in Rails 6.0.2.2.
module ActionController
  class TestRequest < ActionDispatch::TestRequest #:nodoc:
    def self.new_session
      TestSessionPatched.new
    end
  end

  # Methods #destroy and #load! are overridden to avoid calling methods on the
  # @store object, which does not exist for the TestSession class.
  class TestSessionPatched < Rack::Session::Abstract::PersistedSecure::SecureSessionHash #:nodoc:
    DEFAULT_OPTIONS = Rack::Session::Abstract::Persisted::DEFAULT_OPTIONS

    def initialize(session = {})
      super(nil, nil)
      @id = Rack::Session::SessionId.new(SecureRandom.hex(16))
      @data = stringify_keys(session)
      @loaded = true
    end

    def exists?
      true
    end

    def keys
      @data.keys
    end

    def values
      @data.values
    end

    def destroy
      clear
    end

    def fetch(key, *args, &block)
      @data.fetch(key.to_s, *args, &block)
    end

    private

    def load!
      @id
    end
  end
end
