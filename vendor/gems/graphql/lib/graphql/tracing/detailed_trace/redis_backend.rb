# frozen_string_literal: true

module GraphQL
  module Tracing
    class DetailedTrace
      class RedisBackend
        KEY_PREFIX = "gql:trace:"
        def initialize(redis:, limit: nil)
          @redis = redis
          @key = KEY_PREFIX + "traces"
          @remrangebyrank_limit = limit ? -limit - 1 : nil
        end

        def traces(last:, before:)
          before = case before
          when Numeric
            "(#{before}"
          when nil
            "+inf"
          end
          str_pairs = @redis.zrange(@key, before, 0, byscore: true, rev: true, limit: [0, last || 100], withscores: true)
          str_pairs.map do |(str_data, score)|
            entry_to_trace(score, str_data)
          end
        end

        def delete_trace(id)
          @redis.zremrangebyscore(@key, id, id)
          nil
        end

        def delete_all_traces
          @redis.del(@key)
        end

        def find_trace(id)
          str_data = @redis.zrange(@key, id, id, byscore: true).first
          if str_data.nil?
            nil
          else
            entry_to_trace(id, str_data)
          end
        end

        def save_trace(operation_name, duration_ms, begin_ms, trace_data)
          id = begin_ms
          data = JSON.dump({ "o" => operation_name, "d" => duration_ms, "b" => begin_ms, "t" => Base64.encode64(trace_data) })
          @redis.pipelined do |pipeline|
            pipeline.zadd(@key, id, data)
            if @remrangebyrank_limit
              pipeline.zremrangebyrank(@key, 0, @remrangebyrank_limit)
            end
          end
          id
        end

        private

        def entry_to_trace(id, json_str)
          data = JSON.parse(json_str)
          StoredTrace.new(
            id: id,
            operation_name: data["o"],
            duration_ms: data["d"].to_f,
            begin_ms: data["b"].to_i,
            trace_data: Base64.decode64(data["t"]),
          )
        end
      end
    end
  end
end
