# frozen_string_literal: true

module GraphQLTracingDetailedTraceBackendAssertions
  def self.included(child_class)
    child_class.instance_eval do
      describe "BackendAssertions" do
        before do
          @backend = new_backend
          @backend.delete_all_traces
        end

        it "can save, retreive, list, and delete traces" do
          data = SecureRandom.bytes(1000)
          trace_id = @backend.save_trace(
            "GetStuff",
            100.56,
            (Time.utc(2024, 01, 01, 04, 44, 33, 695000).to_f * 1000).round,
            data
          )

          trace = @backend.find_trace(trace_id)
          assert_kind_of GraphQL::Tracing::DetailedTrace::StoredTrace, trace
          assert_equal trace_id, trace.id
          assert_equal "GetStuff", trace.operation_name
          assert_equal 100.56, trace.duration_ms
          assert_equal "2024-01-01 04:44:33.694", Time.at(trace.begin_ms / 1000.0).utc.strftime("%Y-%m-%d %H:%M:%S.%L")
          assert_equal data, trace.trace_data


          @backend.save_trace(
            "GetOtherStuff",
            200.16,
            (Time.utc(2024, 01, 03, 04, 44, 33, 695000).to_f * 1000).round,
            data
          )

          @backend.save_trace(
            "GetMoreOtherStuff",
            200.16,
            (Time.utc(2024, 01, 03, 04, 44, 33, 795000).to_f * 1000).round,
            data
          )

          assert_equal ["GetMoreOtherStuff", "GetOtherStuff", "GetStuff" ], @backend.traces(last: 20, before: nil).map(&:operation_name)

          assert_equal ["GetMoreOtherStuff"], @backend.traces(last: 1, before: nil).map(&:operation_name)
          assert_equal ["GetOtherStuff", "GetStuff"], @backend.traces(last: 2, before: Time.utc(2024, 01, 03, 04, 44, 33, 795000).to_f * 1000).map(&:operation_name)


          @backend.delete_trace(trace_id)

          assert_equal ["GetMoreOtherStuff", "GetOtherStuff"], @backend.traces(last: 20, before: nil).map(&:operation_name)

          @backend.delete_all_traces
          assert_equal [], @backend.traces(last: 20, before: nil)
        end

        it "returns nil for nonexistent IDs" do
          assert_nil @backend.find_trace(999_999_999)
        end

        it "implements a limit" do
          limit_backend = new_backend(limit: 10)

          10.times do |n|
            limit_backend.save_trace(
              "Trace#{n}",
              1.5,
              5000 + n,
              "some-data"
            )
          end

          all_traces = limit_backend.traces(last: nil, before: nil)
          assert_equal 10, all_traces.size
          assert_equal "Trace9", all_traces.first.operation_name
          assert_equal "Trace0", all_traces.last.operation_name

          3.times do |n|
            limit_backend.save_trace(
              "Trace 2-#{n}",
              1.5,
              5020 + n,
              "some-data"
            )
          end

          all_traces = limit_backend.traces(last: nil, before: nil)
          assert_equal 10, all_traces.size
          assert_equal "Trace 2-2", all_traces.first.operation_name
          assert_equal "Trace3", all_traces.last.operation_name
        end
      end
    end
  end
end
