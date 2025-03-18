# frozen_string_literal: true
require "spec_helper"
if RUBY_VERSION >= "3.1.1"
  require "async"
  describe GraphQL::Dataloader::AsyncDataloader do
    class AsyncSchema < GraphQL::Schema
      class SleepSource < GraphQL::Dataloader::Source
        def initialize(tag = nil)
          @tag = tag
        end

        def fetch(keys)
          max_sleep = keys.max
          # t1 = Time.now
          # puts "----- SleepSource => #{max_sleep} (from: #{keys})"
          sleep(max_sleep)
          # puts "----- SleepSource done #{max_sleep} after #{Time.now - t1}"
          keys.map { |_k| max_sleep }
        end
      end

      class WaitForSource < GraphQL::Dataloader::Source
        def initialize(tag)
          @tag = tag
        end

        def fetch(waits)
          max_wait = waits.max
          # puts "[#{Time.now.to_f}] Waiting #{max_wait} for #{@tag}"
          `sleep #{max_wait}`
          # puts "[#{Time.now.to_f}] Finished for #{@tag}"
          waits.map { |_w| @tag }
        end
      end

      class KeyWaitForSource < GraphQL::Dataloader::Source
        class << self
          attr_accessor :fetches
          def reset
            @fetches = []
          end
        end

        def initialize(wait)
          @wait = wait
        end

        def fetch(keys)
          self.class.fetches << keys
          sleep(@wait)
          keys
        end
      end

      class FiberLocalContextSource < GraphQL::Dataloader::Source
        def fetch(keys)
          keys.map { |key| Thread.current[key] }
        end
      end

      class Sleeper < GraphQL::Schema::Object
        field :sleeper, Sleeper, null: false, resolver_method: :sleep do
          argument :duration, Float
        end

        def sleep(duration:)
          context[:key_i] ||= 0
          new_key = context[:key_i] += 1
          dataloader.with(SleepSource, new_key).load(duration)
          duration
        end

        field :duration, Float, null: false
        def duration; object; end
      end

      class Waiter < GraphQL::Schema::Object
        field :wait_for, Waiter, null: false do
          argument :tag, String
          argument :wait, Float
        end

        def wait_for(tag:, wait:)
          dataloader.with(WaitForSource, tag).load(wait)
        end

        field :tag, String, null: false
        def tag
          object
        end
      end

      class Query < GraphQL::Schema::Object
        field :sleep, Float, null: false do
          argument :duration, Float
        end

        field :sleeper, Sleeper, null: false, resolver_method: :sleep do
          argument :duration, Float
        end

        def sleep(duration:)
          context[:key_i] ||= 0
          new_key = context[:key_i] += 1
          dataloader.with(SleepSource, new_key).load(duration)
          duration
        end

        field :wait_for, Waiter, null: false do
          argument :tag, String
          argument :wait, Float
        end

        def wait_for(tag:, wait:)
          dataloader.with(WaitForSource, tag).load(wait)
        end

        class ListWaiter < GraphQL::Schema::Object
          field :waiter, Waiter

          def waiter
            dataloader.with(KeyWaitForSource, object[:wait]).load(object[:tag])
          end
        end

        field :list_waiters, [ListWaiter] do
          argument :wait, Float
          argument :tags, [String]
        end

        def list_waiters(wait:, tags:)
          Kernel.sleep(0.1)
          tags.map { |t| { tag: t, wait: wait }}
        end

        field :fiber_local_context, String do
          argument :key, String
        end
        def fiber_local_context(key:)
          dataloader.with(FiberLocalContextSource).load(key)
        end
      end

      query(Query)
      use GraphQL::Dataloader::AsyncDataloader
    end

    module AsyncDataloaderAssertions
      def self.included(child_class)
        child_class.class_eval do
          it "works with sources" do
            dataloader = GraphQL::Dataloader::AsyncDataloader.new
            r1 = dataloader.with(AsyncSchema::SleepSource, :s1).request(0.1)
            r2 = dataloader.with(AsyncSchema::SleepSource, :s2).request(0.2)
            r3 = dataloader.with(AsyncSchema::SleepSource, :s3).request(0.3)

            v1 = nil
            dataloader.append_job {
              v1 = r1.load
            }
            started_at = Time.now
            dataloader.run
            ended_at = Time.now
            assert_equal 0.1, v1
            started_at_2 = Time.now
            # These should take no time at all since they're already resolved
            v2 = r2.load
            v3 = r3.load
            ended_at_2 = Time.now

            assert_equal 0.2, v2
            assert_equal 0.3, v3
            assert_in_delta 0.0, started_at_2 - ended_at_2, 0.06, "Already-loaded values returned instantly"

            assert_in_delta 0.3, ended_at - started_at, 0.06, "IO ran in parallel"
          end

          it "works with GraphQL" do
            started_at = Time.now
            res = @schema.execute("{ s1: sleep(duration: 0.1) s2: sleep(duration: 0.2) s3: sleep(duration: 0.3) }")
            ended_at = Time.now
            assert_equal({"s1"=>0.1, "s2"=>0.2, "s3"=>0.3}, res["data"])
            assert_in_delta 0.3, ended_at - started_at, 0.06, "IO ran in parallel"
          end

          it "runs fields by depth" do
            query_str = <<-GRAPHQL
            {
              s1: sleeper(duration: 0.1) {
                sleeper(duration: 0.1) {
                  sleeper(duration: 0.1) {
                    duration
                  }
                }
              }
              s2: sleeper(duration: 0.2) {
                sleeper(duration: 0.1) {
                  duration
                }
              }
              s3: sleeper(duration: 0.3) {
                duration
              }
            }
            GRAPHQL
            started_at = Time.now
            res = @schema.execute(query_str)
            ended_at = Time.now

            expected_data = {
              "s1" => { "sleeper" => { "sleeper" => { "duration" => 0.1 } } },
              "s2" => { "sleeper" => { "duration" => 0.1 } },
              "s3" => { "duration" => 0.3 }
            }
            assert_equal expected_data, res["data"]
            assert_in_delta 0.5, ended_at - started_at, 0.06, "Each depth ran in parallel"
          end

          it "runs dataloaders in parallel across branches" do
            query_str = <<-GRAPHQL
            {
              w1: waitFor(tag: "a", wait: 0.2) {
                waitFor(tag: "b", wait: 0.2) {
                  waitFor(tag: "c", wait: 0.2) {
                    tag
                  }
                }
              }
              # After the first, these are returned eagerly from cache
              w2: waitFor(tag: "a", wait: 0.2) {
                waitFor(tag: "a", wait: 0.2) {
                  waitFor(tag: "a", wait: 0.2) {
                    tag
                  }
                }
              }
              w3: waitFor(tag: "a", wait: 0.2) {
                waitFor(tag: "b", wait: 0.2) {
                  waitFor(tag: "d", wait: 0.2) {
                    tag
                  }
                }
              }
              w4: waitFor(tag: "e", wait: 0.6) {
                tag
              }
            }
            GRAPHQL
            started_at = Time.now
            res = @schema.execute(query_str)
            ended_at = Time.now

            expected_data = {
              "w1" => { "waitFor" => { "waitFor" => { "tag" => "c" } } },
              "w2" => { "waitFor" => { "waitFor" => { "tag" => "a" } } },
              "w3" => { "waitFor" => { "waitFor" => { "tag" => "d" } } },
              "w4" => { "tag" => "e" }
            }
            assert_equal expected_data, res["data"]
            # We've basically got two options here:
            # - Put all jobs in the same queue (fields and sources), but then you don't get predictable batching.
            # - Work one-layer-at-a-time, but then layers can get stuck behind one another. That's what's implemented here.
            # assert_in_delta 1.0, ended_at - started_at, 0.06, "Sources were executed in parallel"
          end

          it "groups across list items" do
            query_str = <<-GRAPHQL
              {
                listWaiters(wait: 0.2, tags: ["a", "b", "c"]) {
                  waiter {
                    tag
                  }
                }
              }
            GRAPHQL

            t1 = Time.now
            result = @schema.execute(query_str)
            t2 = Time.now
            assert_equal ["a", "b", "c"], result["data"]["listWaiters"].map { |lw| lw["waiter"]["tag"]}
            # The field itself waits 0.1
            assert_in_delta 0.3, t2 - t1, 0.06, "Wait was parallel"
            assert_equal [["a", "b", "c"]], AsyncSchema::KeyWaitForSource.fetches, "All keys were fetched at once"
          end

          it 'copies fiber-local variables over to sources' do
            key = 'arbitrary_context'
            value = 'test'
            Thread.current[key] = value
            query_str = <<-GRAPHQL
              {
                fiberLocalContext(key: "#{key}")
              }
            GRAPHQL

            result = @schema.execute(query_str)
            assert_equal value, result['data']['fiberLocalContext']
          end
        end
      end
    end

    describe "with async" do
      before do
        @schema = AsyncSchema
        AsyncSchema::KeyWaitForSource.reset
      end
      include AsyncDataloaderAssertions
    end

    describe "with perfetto trace turned on" do
      class TraceAsyncSchema < AsyncSchema
        trace_with GraphQL::Tracing::PerfettoTrace
        use GraphQL::Dataloader::AsyncDataloader
      end

      before do
        @schema = TraceAsyncSchema
        AsyncSchema::KeyWaitForSource.reset
      end

      include AsyncDataloaderAssertions
      include PerfettoSnapshot

      it "produces a trace" do
        query_str = <<-GRAPHQL
        {
          s1: sleeper(duration: 0.1) {
            sleeper(duration: 0.1) {
              sleeper(duration: 0.1) {
                duration
              }
            }
          }
          s2: sleeper(duration: 0.2) {
            sleeper(duration: 0.1) {
              duration
            }
          }
          s3: sleeper(duration: 0.3) {
            duration
          }
        }
        GRAPHQL
        res = @schema.execute(query_str)
        if ENV["DUMP_PERFETTO"]
          res.context.query.current_trace.write(file: "perfetto.dump")
        end

        json = res.context.query.current_trace.write(file: nil, debug_json: true)
        data = JSON.parse(json)


        check_snapshot(data, "example.json")
      end
    end
  end
end
