# frozen_string_literal: true

require "graphql/tracing/platform_tracing"

module GraphQL
  module Tracing

    # This class uses the AppopticsAPM SDK from the appoptics_apm gem to create
    # traces for GraphQL.
    #
    # There are 4 configurations available. They can be set in the
    # appoptics_apm config file or in code. Please see:
    # {https://docs.appoptics.com/kb/apm_tracing/ruby/configure}
    #
    #     AppOpticsAPM::Config[:graphql][:enabled] = true|false
    #     AppOpticsAPM::Config[:graphql][:transaction_name]  = true|false
    #     AppOpticsAPM::Config[:graphql][:sanitize_query] = true|false
    #     AppOpticsAPM::Config[:graphql][:remove_comments] = true|false
    class AppOpticsTracing < GraphQL::Tracing::PlatformTracing
      # These GraphQL events will show up as 'graphql.prep' spans
      PREP_KEYS = ['lex', 'parse', 'validate', 'analyze_query', 'analyze_multiplex'].freeze
      # These GraphQL events will show up as 'graphql.execute' spans
      EXEC_KEYS = ['execute_multiplex', 'execute_query', 'execute_query_lazy'].freeze

      # During auto-instrumentation this version of AppOpticsTracing is compared
      # with the version provided in the appoptics_apm gem, so that the newer
      # version of the class can be used

      def self.version
        Gem::Version.new('1.0.0')
      end

      self.platform_keys = {
        'lex' => 'lex',
        'parse' => 'parse',
        'validate' => 'validate',
        'analyze_query' => 'analyze_query',
        'analyze_multiplex' => 'analyze_multiplex',
        'execute_multiplex' => 'execute_multiplex',
        'execute_query' => 'execute_query',
        'execute_query_lazy' => 'execute_query_lazy'
      }

      def platform_trace(platform_key, _key, data)
        return yield if !defined?(AppOpticsAPM) || gql_config[:enabled] == false

        layer = span_name(platform_key)
        kvs = metadata(data, layer)
        kvs[:Key] = platform_key if (PREP_KEYS + EXEC_KEYS).include?(platform_key)

        transaction_name(kvs[:InboundQuery]) if kvs[:InboundQuery] && layer == 'graphql.execute'

        ::AppOpticsAPM::SDK.trace(layer, kvs) do
          kvs.clear # we don't have to send them twice
          yield
        end
      end

      def platform_field_key(type, field)
        "graphql.#{type.graphql_name}.#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "graphql.authorized.#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "graphql.resolve_type.#{type.graphql_name}"
      end

      private

      def gql_config
        ::AppOpticsAPM::Config[:graphql] ||= {}
      end

      def transaction_name(query)
        return if gql_config[:transaction_name] == false ||
          ::AppOpticsAPM::SDK.get_transaction_name

        split_query = query.strip.split(/\W+/, 3)
        split_query[0] = 'query' if split_query[0].empty?
        name = "graphql.#{split_query[0..1].join('.')}"

        ::AppOpticsAPM::SDK.set_transaction_name(name)
      end

      def multiplex_transaction_name(names)
        return if gql_config[:transaction_name] == false ||
          ::AppOpticsAPM::SDK.get_transaction_name

        name = "graphql.multiplex.#{names.join('.')}"
        name = "#{name[0..251]}..." if name.length > 254

        ::AppOpticsAPM::SDK.set_transaction_name(name)
      end

      def span_name(key)
        return 'graphql.prep' if PREP_KEYS.include?(key)
        return 'graphql.execute' if EXEC_KEYS.include?(key)

        key[/^graphql\./] ? key : "graphql.#{key}"
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def metadata(data, layer)
        data.keys.map do |key|
          case key
          when :context
            graphql_context(data[key], layer)
          when :query
            graphql_query(data[key])
          when :query_string
            graphql_query_string(data[key])
          when :multiplex
            graphql_multiplex(data[key])
          when :path
            [key, data[key].join(".")]
          else
            [key, data[key]]
          end
        end.tap { _1.flatten!(2) }.each_slice(2).to_h.merge(Spec: 'graphql')
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def graphql_context(context, layer)
        context.errors && context.errors.each do |err|
          AppOpticsAPM::API.log_exception(layer, err)
        end

        [[:Path, context.path.join('.')]]
      end

      def graphql_query(query)
        return [] unless query

        query_string = query.query_string
        query_string = remove_comments(query_string) if gql_config[:remove_comments] != false
        query_string = sanitize(query_string) if gql_config[:sanitize_query] != false

        [[:InboundQuery, query_string],
         [:Operation, query.selected_operation_name]]
      end

      def graphql_query_string(query_string)
        query_string = remove_comments(query_string) if gql_config[:remove_comments] != false
        query_string = sanitize(query_string) if gql_config[:sanitize_query] != false

        [:InboundQuery, query_string]
      end

      def graphql_multiplex(data)
        names = data.queries.map(&:operations).map!(&:keys).tap(&:flatten!).tap(&:compact!)
        multiplex_transaction_name(names) if names.size > 1

        [:Operations, names.join(', ')]
      end

      def sanitize(query)
        return unless query

        # remove arguments
        query.gsub(/"[^"]*"/, '"?"')                 # strings
          .gsub(/-?[0-9]*\.?[0-9]+e?[0-9]*/, '?') # ints + floats
          .gsub(/\[[^\]]*\]/, '[?]')              # arrays
      end

      def remove_comments(query)
        return unless query

        query.gsub(/#[^\n\r]*/, '')
      end
    end
  end
end
