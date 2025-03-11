# frozen_string_literal: true

require 'graphql/version'
require 'digest/sha2'

module GraphQL
  module Language
    # This cache is used by {GraphQL::Language::Parser.parse_file} when it's enabled.
    #
    # With Rails, parser caching may enabled by setting `config.graphql.parser_cache = true` in your Rails application.
    #
    # The cache may be manually built by assigning `GraphQL::Language::Parser.cache = GraphQL::Language::Cache.new("some_dir")`.
    # This will create a directory (`tmp/cache/graphql` by default) that stores a cache of parsed files.
    #
    # Much like [bootsnap](https://github.com/Shopify/bootsnap), the parser cache needs to be cleaned up manually.
    # You will need to clear the cache directory for each new deployment of your application.
    # Also note that the parser cache will grow as your schema is loaded, so the cache directory must be writable.
    #
    # @see GraphQL::Railtie for simple Rails integration
    class Cache
      def initialize(path)
        @path = path
      end

      DIGEST = Digest::SHA256.new << GraphQL::VERSION

      def fetch(filename)
        hash = DIGEST.dup << filename
        begin
          hash << File.mtime(filename).to_i.to_s
        rescue SystemCallError
          return yield
        end
        cache_path = @path.join(hash.to_s)

        if cache_path.exist?
          Marshal.load(cache_path.read)
        else
          payload = yield
          tmp_path = "#{cache_path}.#{rand}"

          @path.mkpath
          File.binwrite(tmp_path, Marshal.dump(payload))
          File.rename(tmp_path, cache_path.to_s)
          payload
        end
      end
    end
  end
end
